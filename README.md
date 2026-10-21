# Thunderbird for iOS — personal TestFlight fork

Personal build of [Thunderbird for iOS](https://github.com/thunderbird/thunderbird-ios) so it can be installed on one iPhone through TestFlight with an Individual Apple Developer account, including from a machine that is not a Mac.

The imported upstream commit is `cb338c68151cc6ed5fc755bbc38d260a4c0ca8b7` (2026-10-15, “Merge pull request #553”). License remains [MPL-2.0](LICENSE). See [UPSTREAM.md](UPSTREAM.md) for how to merge later upstream changes. The step-by-step owner guide is [README_RU.md](README_RU.md).

This environment has no Mac and no Apple credentials, so the app has not been compiled here. The first real compile is the **Xcode Build** workflow on a GitHub-hosted `macos-26` runner. The first installable build is **Personal TestFlight**, after the signing secrets exist.

## What the code does today

Upstream’s README still says mail is not implemented. That text is behind the code at the imported commit.

- Account setup UI: autoconfig (Thunderbird ISPDB), manual IMAP/SMTP/JMAP servers, a password field, and an OAuth browser sheet.
- IMAP library: connect, `LOGIN`, list, fetch, flags, idle. The inbox screen calls `account.emails()` for the first account and shows those messages when the fetch returns at least one.
- Until that fetch returns mail, the inbox shows **sample messages**, with a banner saying so.
- SMTP library can construct a client for implicit TLS (port 465) and STARTTLS, including the host and port from autoconfig. The compose screen’s send button does not call it.
- JMAP exists for Fastmail setup. Loading the inbox for a JMAP account throws and the sample list stays.

## What does not work

- **Gmail.** The Google sign-in sheet can run, but IMAP logs in with the `LOGIN` command. Gmail expects `AUTHENTICATE XOAUTH2`, so a Google access token does not open the mailbox. There is no mail.ru OAuth client either. mail.ru, inbox.ru, bk.ru, and list.ru are in the ISPDB; autoconfig prefers OAuth2, and the authentication picker can be switched to **Password**. mail.ru expects an app password for external clients. Reading INBOX over password IMAP is the path that is actually wired up.
- **Sending mail, push, real folder lists.** Compose does not send. The drawer does not load mailboxes from the server (`MailboxDropdownRowView` still has a “load the list” TODO).
- **OAuth client ids** for AOL, Fastmail, Google, Microsoft, Thundermail, and Yahoo are the public ids from upstream. Redirect schemes stay `net.thunderbird.ios` and `msauth.net.thunderbird.ios` so those registrations still match. A personal Google iOS client can be injected at build time with the `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_URL_SCHEME` secrets. That fixes the browser step only.
- The upstream OAuth callback listened on the first URL scheme, while Microsoft’s redirect uses `msauth.` plus that scheme. The callback now uses the scheme from the redirect URI.

Minimum OS is iOS 18 (iPhone XR and newer).

## CI

GitHub Actions, same shape as upstream: `macos-26`, Xcode 26.4, fastlane `beta` for TestFlight.

| Workflow | When | Needs secrets |
| --- | --- | --- |
| [Xcode Build](.github/workflows/test.yml) | push and pull request to `main` | no |
| [Personal TestFlight](.github/workflows/personal-testflight.yml) | manual | yes |

Xcode Cloud and Codemagic were not used. Upstream already ships this GitHub Actions path, so merges stay small, and there is no second vendor account. Public repositories: standard runners, including `macos-26`, are free. Private repositories on GitHub Free include 2,000 minutes/month; macOS is billed at $0.062/minute (Linux is $0.006), and the included quota is consumed about 10× faster, roughly 200 minutes of macOS. A full simulator build can use 30–60 minutes, and Swift Format is a second macOS job on every push. A public repo avoids that. Apple Developer Program (Individual) is separate and required for TestFlight; Apple lists it at $99/year in the US.

Signing secrets are created with `scripts/bootstrap_signing.py` (openssl + App Store Connect API, no Mac) and stored in GitHub Actions secrets. Nothing secret is committed. `signing-out/` is gitignored.

Bundle id: `com.verkvest.thunderbird`. Mozilla’s team id `BUMSKVQ3D9` is cleared. Release signing stays manual; fastlane writes the team id and profile from CI secrets.
