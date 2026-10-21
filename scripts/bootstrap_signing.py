#!/usr/bin/env python3
"""Create Apple Distribution signing assets without a Mac.

Uses openssl plus the App Store Connect API. Writes a .p12, a .mobileprovision,
and a text file of base64 values into signing-out/. That directory is gitignored.
Never commit the output.

Required environment:
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_KEY_PATH   path to the AuthKey_XXXX.p8 file
  APPLE_TEAM_ID                10-character Team ID from Membership details
  P12_PASSWORD                 password that will protect the .p12

Optional:
  APP_NAME     default "Thunderbird Verkvest" (must be unique on the App Store)
  BUNDLE_ID    default com.verkvest.thunderbird

The API key must be Admin (Account Holder on an Individual team can create one).
Certificate creation is refused when two distribution certificates already exist,
because Apple will not return the private key of an existing certificate.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

BUNDLE_ID_DEFAULT = "com.verkvest.thunderbird"
APP_NAME_DEFAULT = "Thunderbird Verkvest"
PROFILE_NAME = "verkvest-thunderbird-appstore"
API = "https://api.appstoreconnect.apple.com"


class APIError(RuntimeError):
    def __init__(self, method: str, path: str, code: int, detail: str) -> None:
        self.method = method
        self.path = path
        self.code = code
        self.detail = detail
        super().__init__(f"App Store Connect API {method} {path} failed ({code}):\n{detail}")


def die(message: str, code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(code)


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def der_ecdsa_to_raw(der: bytes, size: int = 32) -> bytes:
    if not der or der[0] != 0x30:
        die("openssl produced a signature that is not a DER sequence")
    index = 2
    if der[1] & 0x80:
        count = der[1] & 0x7F
        index = 2 + count

    def read_int(at: int) -> tuple[bytes, int]:
        if der[at] != 0x02:
            die("openssl signature is missing an integer")
        length = der[at + 1]
        start = at + 2
        return der[start : start + length], start + length

    raw_r, index = read_int(index)
    raw_s, _ = read_int(index)

    def pad(value: bytes) -> bytes:
        if len(value) > size and value[0] == 0x00:
            value = value[1:]
        if len(value) > size:
            die("ECDSA integer does not fit P-256")
        return value.rjust(size, b"\x00")

    return pad(raw_r) + pad(raw_s)


def raw_to_der(raw: bytes) -> bytes:
    def encode_int(part: bytes) -> bytes:
        part = part.lstrip(b"\x00") or b"\x00"
        if part[0] & 0x80:
            part = b"\x00" + part
        return bytes([0x02, len(part)]) + part

    body = encode_int(raw[:32]) + encode_int(raw[32:])
    return bytes([0x30, len(body)]) + body


def make_jwt(key_path: Path, key_id: str, issuer_id: str) -> str:
    header = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}, separators=(",", ":")).encode())
    now = int(time.time())
    payload = b64url(
        json.dumps(
            {"iss": issuer_id, "iat": now - 30, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"},
            separators=(",", ":"),
        ).encode()
    )
    signing_input = f"{header}.{payload}".encode()
    signature = subprocess.check_output(
        ["openssl", "dgst", "-sha256", "-sign", str(key_path)],
        input=signing_input,
    )
    return signing_input.decode() + "." + b64url(der_ecdsa_to_raw(signature))


def api(token: str, method: str, path: str, body: dict | None = None) -> dict:
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(
        API + path,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise APIError(method, path, error.code, detail)
    return {}


def openssl(*args: str, input_bytes: bytes | None = None) -> bytes:
    try:
        return subprocess.check_output(["openssl", *args], input=input_bytes, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as error:
        sys.stderr.buffer.write(error.stderr or b"")
        die(f"openssl {' '.join(args)} failed")
    return b""


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        die(f"Set {name} in the environment.")
    return value


def list_all(token: str, path: str) -> list[dict]:
    items: list[dict] = []
    next_path: str | None = path
    while next_path:
        page = api(token, "GET", next_path)
        items.extend(page.get("data", []))
        link = page.get("links", {}).get("next")
        if not link:
            break
        parsed = urllib.parse.urlparse(link)
        next_path = parsed.path
        if parsed.query:
            next_path += "?" + parsed.query
        if next_path.startswith(API):
            next_path = next_path[len(API) :]
    return items


def ensure_bundle_id(token: str, bundle_id: str, name: str) -> str:
    query = urllib.parse.urlencode({"filter[identifier]": bundle_id})
    found = api(token, "GET", f"/v1/bundleIds?{query}").get("data", [])
    if found:
        print(f"Bundle ID already registered: {bundle_id}")
        return found[0]["id"]
    created = api(
        token,
        "POST",
        "/v1/bundleIds",
        {
            "data": {
                "type": "bundleIds",
                "attributes": {
                    "identifier": bundle_id,
                    "name": name,
                    "platform": "IOS",
                },
            }
        },
    )
    print(f"Registered bundle ID {bundle_id}")
    return created["data"]["id"]


def distribution_certificates(token: str) -> list[dict]:
    certs = list_all(token, "/v1/certificates?limit=200")
    kinds = {"DISTRIBUTION", "IOS_DISTRIBUTION", "MAC_APP_DISTRIBUTION"}
    return [cert for cert in certs if cert.get("attributes", {}).get("certificateType") in kinds]


def create_certificate(token: str, out_dir: Path, password: str) -> str:
    existing = distribution_certificates(token)
    # Apple Distribution certificates are capped (commonly two). A new one is
    # required because the private key of an existing certificate cannot be downloaded.
    if len(existing) >= 2:
        names = ", ".join(cert.get("attributes", {}).get("name", cert["id"]) for cert in existing)
        die(
            "This team already has two distribution certificates "
            f"({names}). Apple will not give us the private key for those. "
            "Revoke one you no longer use at developer.apple.com → Certificates, "
            "then run this script again. Revoking invalidates apps signed with that certificate."
        )
    key_path = out_dir / "distribution.key.pem"
    csr_path = out_dir / "distribution.csr.pem"
    openssl("genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:P-256", "-out", str(key_path))
    openssl(
        "req",
        "-new",
        "-key",
        str(key_path),
        "-subj",
        "/CN=Thunderbird Verkvest Distribution/O=Personal",
        "-out",
        str(csr_path),
    )
    csr = csr_path.read_text()
    created = None
    last_error: APIError | None = None
    for certificate_type in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        try:
            created = api(
                token,
                "POST",
                "/v1/certificates",
                {
                    "data": {
                        "type": "certificates",
                        "attributes": {
                            "certificateType": certificate_type,
                            "csrContent": csr,
                        },
                    }
                },
            )
            print(f"Apple accepted certificate type {certificate_type}")
            break
        except APIError as error:
            last_error = error
            if "certificateType" not in error.detail and certificate_type == "DISTRIBUTION":
                die(str(error))
    if created is None:
        die(str(last_error))
    cert_b64 = created["data"]["attributes"]["certificateContent"]
    cert_der = out_dir / "distribution.cer"
    cert_der.write_bytes(base64.b64decode(cert_b64))
    cert_pem = out_dir / "distribution.cert.pem"
    openssl("x509", "-inform", "DER", "-in", str(cert_der), "-out", str(cert_pem))
    p12_path = out_dir / "distribution.p12"
    openssl(
        "pkcs12",
        "-export",
        "-inkey",
        str(key_path),
        "-in",
        str(cert_pem),
        "-out",
        str(p12_path),
        "-passout",
        f"pass:{password}",
        "-keypbe",
        "PBE-SHA1-3DES",
        "-certpbe",
        "PBE-SHA1-3DES",
        "-macalg",
        "sha1",
    )
    print(f"Created distribution certificate {created['data']['id']}")
    return created["data"]["id"]


def ensure_profile(token: str, bundle_resource_id: str, certificate_id: str, out_dir: Path) -> None:
    profiles = list_all(token, "/v1/profiles?limit=200")
    for profile in profiles:
        if profile.get("attributes", {}).get("name") == PROFILE_NAME:
            api(token, "DELETE", f"/v1/profiles/{profile['id']}")
            print(f"Deleted previous profile {PROFILE_NAME}")
    created = api(
        token,
        "POST",
        "/v1/profiles",
        {
            "data": {
                "type": "profiles",
                "attributes": {
                    "name": PROFILE_NAME,
                    "profileType": "IOS_APP_STORE",
                },
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundle_resource_id}},
                    "certificates": {"data": [{"type": "certificates", "id": certificate_id}]},
                },
            }
        },
    )
    profile_b64 = created["data"]["attributes"]["profileContent"]
    (out_dir / "distribution.mobileprovision").write_bytes(base64.b64decode(profile_b64))
    print(f"Created provisioning profile {PROFILE_NAME}")


def ensure_app(token: str, bundle_resource_id: str, bundle_id: str, app_name: str) -> None:
    query = urllib.parse.urlencode({"filter[bundleId]": bundle_id})
    found = api(token, "GET", f"/v1/apps?{query}").get("data", [])
    if found:
        print(f"App Store Connect app already exists for {bundle_id}: {found[0]['attributes'].get('name')}")
        return
    api(
        token,
        "POST",
        "/v1/apps",
        {
            "data": {
                "type": "apps",
                "attributes": {
                    "bundleId": bundle_id,
                    "name": app_name,
                    "primaryLocale": "en-US",
                    "sku": "verkvest-thunderbird-ios",
                },
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundle_resource_id}},
                },
            }
        },
    )
    print(f"Created App Store Connect app '{app_name}'")


def write_secret_file(out_dir: Path, key_path: Path, password: str) -> None:
    p12 = (out_dir / "distribution.p12").read_bytes()
    profile = (out_dir / "distribution.mobileprovision").read_bytes()
    key = key_path.read_bytes()
    lines = [
        "Paste each value into GitHub → Settings → Secrets and variables → Actions.",
        "Do not commit this file.",
        "",
        "APPLE_CERTIFICATE_P12",
        base64.b64encode(p12).decode(),
        "",
        "APPLE_CERTIFICATE_PASSWORD",
        password,
        "",
        "APP_STORE_PROVISIONING_PROFILE",
        base64.b64encode(profile).decode(),
        "",
        "APP_STORE_CONNECT_API_KEY",
        base64.b64encode(key).decode(),
        "",
        "APP_STORE_CONNECT_API_KEY_ID",
        os.environ["APP_STORE_CONNECT_KEY_ID"].strip(),
        "",
        "APP_STORE_CONNECT_ISSUER_ID",
        os.environ["APP_STORE_CONNECT_ISSUER_ID"].strip(),
        "",
        "APPLE_TEAM_ID",
        os.environ["APPLE_TEAM_ID"].strip(),
        "",
    ]
    path = out_dir / "github-secrets.txt"
    path.write_text("\n".join(lines))
    os.chmod(path, 0o600)
    os.chmod(out_dir / "distribution.p12", 0o600)
    os.chmod(out_dir / "distribution.key.pem", 0o600)
    print(f"Wrote {path}")


def self_test() -> None:
    out = Path("signing-out") / "self-test"
    out.mkdir(parents=True, exist_ok=True)
    key = out / "test.key.pem"
    pub = out / "test.pub.pem"
    openssl("genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:P-256", "-out", str(key))
    openssl("pkey", "-in", str(key), "-pubout", "-out", str(pub))
    message = b"thunderbird-signing-self-test"
    der = openssl("dgst", "-sha256", "-sign", str(key), input_bytes=message)
    raw = der_ecdsa_to_raw(der)
    if len(raw) != 64:
        die(f"self-test: raw signature length is {len(raw)}, expected 64")
    rebuilt = out / "rebuilt.der"
    rebuilt.write_bytes(raw_to_der(raw))
    subprocess.run(
        ["openssl", "dgst", "-sha256", "-verify", str(pub), "-signature", str(rebuilt)],
        input=message,
        check=True,
        stdout=subprocess.DEVNULL,
    )
    token = make_jwt(key, "TESTKEY123", "issuer-id-example")
    if token.count(".") != 2:
        die("self-test: JWT did not have 3 parts")
    print("self-test ok: ES256 signature converts to raw R||S and back")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="sign a throwaway JWT with openssl and exit")
    parser.add_argument("--app-name", default=os.environ.get("APP_NAME", APP_NAME_DEFAULT))
    parser.add_argument("--bundle-id", default=os.environ.get("BUNDLE_ID", BUNDLE_ID_DEFAULT))
    parser.add_argument("--skip-app", action="store_true", help="do not create the App Store Connect app record")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return

    key_id = require_env("APP_STORE_CONNECT_KEY_ID")
    issuer_id = require_env("APP_STORE_CONNECT_ISSUER_ID")
    key_path = Path(require_env("APP_STORE_CONNECT_KEY_PATH"))
    require_env("APPLE_TEAM_ID")
    password = require_env("P12_PASSWORD")
    if not key_path.is_file():
        die(f"API key file not found: {key_path}")
    if "BEGIN PRIVATE KEY" not in key_path.read_text(errors="replace"):
        die(f"{key_path} does not look like an AuthKey .p8 file")

    out_dir = Path("signing-out")
    out_dir.mkdir(mode=0o700, exist_ok=True)
    os.chmod(out_dir, 0o700)
    if (out_dir / "distribution.p12").exists() and not os.environ.get("SIGNING_FORCE"):
        die(
            "signing-out/distribution.p12 already exists. "
            "Reuse those secrets, or move the directory aside and set SIGNING_FORCE=1 to create another certificate."
        )

    try:
        token = make_jwt(key_path, key_id, issuer_id)
        bundle_resource = ensure_bundle_id(token, args.bundle_id, args.app_name)
        certificate_id = create_certificate(token, out_dir, password)
        ensure_profile(token, bundle_resource, certificate_id, out_dir)
        if not args.skip_app:
            ensure_app(token, bundle_resource, args.bundle_id, args.app_name)
        write_secret_file(out_dir, key_path, password)
    except APIError as error:
        die(str(error))
    print("Done. Add the secrets, then run the Personal TestFlight workflow. Delete signing-out/ when finished.")


if __name__ == "__main__":
    main()
