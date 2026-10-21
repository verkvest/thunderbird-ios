# Thunderbird for iOS — personal TestFlight fork

Personal build of [Thunderbird for iOS](https://github.com/thunderbird/thunderbird-ios) so it can be installed on one iPhone through TestFlight with an Individual Apple Developer account, including from a machine that is not a Mac.

The imported upstream commit is `cb338c68151cc6ed5fc755bbc38d260a4c0ca8b7` (2026-10-15, “Merge pull request #553”). License remains [MPL-2.0](LICENSE). See [UPSTREAM.md](UPSTREAM.md) for how to merge later upstream changes. The step-by-step owner guide is [README_RU.md](README_RU.md).

This environment has no Mac and no Apple credentials, so the app has not been compiled here. The first real compile is the **Xcode Build** workflow on a GitHub-hosted `macos-26` runner. The first installable build is **Personal TestFlight**, after the signing secrets exist.

## What the code does today

This environment has no Mac, so none of the following was compiled or run here. The first compile is still **Xcode Build** on GitHub. Unit tests are written for the Swift Testing runner on that Mac; they were not executed on Linux.

The inbox is a real mailbox, not sample messages.

- Several accounts: a menu switches one inbox, or **All inboxes** merges them. Each account is fetched on its own, so one failure does not clear the others. The error line is the account name.
- Password and app-password sign-in. If ISPDB lists OAuth2 but this app has no client for that host (mail.ru, list.ru, bk.ru, inbox.ru), setup switches the account to **Password**.
- Folders come from IMAP `LIST` and open from the side drawer.
- Opening a message selects that mailbox and fetches the body by UID.
- Compose **Send** talks SMTP. Port 465 is implicit TLS. Port 587 is STARTTLS, then a second `EHLO`, then auth. Auth is `AUTH PLAIN`, `AUTH LOGIN`, or `AUTH XOAUTH2`. Reply, reply-all, and forward fill the draft.
- After a successful send, the message is `APPEND`ed to Sent (names such as Sent, Sent Mail, Отправленные, Enviados). Gmail (`smtp.gmail.com`) is skipped because Gmail stores the Sent copy itself. The APPEND writer is untested against a live server: it streams the literal and waits for a tagged `OK`. If a server’s continuation handshake does not match NIOIMAP, saving to Sent can stall even when SMTP already accepted the message.
- **Gmail OAuth.** IMAP uses `AUTHENTICATE XOAUTH2` and SMTP uses `AUTH XOAUTH2` with the Google access token. The SASL string is `user={email}\u{1}auth=Bearer {token}\u{1}\u{1}`. An expired token is refreshed over HTTPS before connect, and the new token is written only to the Keychain. Passwords and tokens are not written into the mail cache.
- A personal Google **iOS** OAuth client is what makes that token valid for bundle `com.verkvest.thunderbird`. Scope in the app is `https://mail.google.com/`. Without that client, the fallback is a Gmail app password and the Password authentication type. Upstream’s public client ids remain for other providers; their redirects still use `net.thunderbird.ios` and `msauth.net.thunderbird.ios`.
- JMAP inbox loading still throws. Fastmail setup is unchanged.

### iPhone

- Launch shows the cached headers first, then refreshes. The list is a lazy `List`. Each page is 40 headers. The last row loads the next page. Bodies are cached after they are opened. The cache is JSON under Application Support and does not store credentials.
- Swipe: archive, delete, mark read or unread, flag. Pull to refresh. Semantic colors for Dark Mode, Dynamic Type text styles, and a light haptic when a swipe action runs.
- Attachments can be handed to the system share sheet.
- Settings has a Face ID lock (device passcode if Face ID is unavailable) and a background mail check. The background task is `com.verkvest.thunderbird.refresh`: a short IMAP `STATUS`, then disconnect. It does not use IDLE. IDLE runs only while the app is in the foreground and a single account is selected. Low Power Mode skips scheduling another background check. A new unseen count posts a local notification.
- The drawer is capped at 320 points. Compose padding tightens on a compact width. Strings for the new screens are in English, Russian, and Spanish. Other languages fall back to English.

Minimum OS is iOS 18 (iPhone XR and newer). Smaller phones in that set, including SE-sized widths, use the same layouts.

## CI

GitHub Actions, same shape as upstream: `macos-26`, Xcode 26.4, fastlane `beta` for TestFlight.

| Workflow | When | Needs secrets |
| --- | --- | --- |
| [Xcode Build](.github/workflows/test.yml) | push and pull request to `main` | no |
| [Personal TestFlight](.github/workflows/personal-testflight.yml) | manual | yes |

Xcode Cloud and Codemagic were not used. Upstream already ships this GitHub Actions path, so merges stay small, and there is no second vendor account. Public repositories: standard runners, including `macos-26`, are free. Private repositories on GitHub Free include 2,000 minutes/month; macOS is billed at $0.062/minute (Linux is $0.006), and the included quota is consumed about 10× faster, roughly 200 minutes of macOS. A full simulator build can use 30–60 minutes, and Swift Format is a second macOS job on every push. A public repo avoids that. Apple Developer Program (Individual) is separate and required for TestFlight; Apple lists it at $99/year in the US.

Signing secrets are created with `scripts/bootstrap_signing.py` (openssl + App Store Connect API, no Mac) and stored in GitHub Actions secrets. Nothing secret is committed. `signing-out/` is gitignored.

Bundle id: `com.verkvest.thunderbird`. Mozilla’s team id `BUMSKVQ3D9` is cleared. Release signing stays manual; fastlane writes the team id and profile from CI secrets.
