# Upstream

This repository is a personal fork of [Thunderbird for iOS](https://github.com/thunderbird/thunderbird-ios).

| | |
| --- | --- |
| Upstream | https://github.com/thunderbird/thunderbird-ios |
| License | [Mozilla Public License 2.0](LICENSE) |
| Imported commit | `cb338c68151cc6ed5fc755bbc38d260a4c0ca8b7` |
| Commit date | 2026-10-15 09:13:19 -0400 |
| Subject | Merge pull request #553 from Emifus/flag-implementations |

The fork is not affiliated with MZLA Technologies or the Thunderbird project. The app bundle identifier in this fork is `com.verkvest.thunderbird`.

The import kept the upstream git history (`git merge upstream/main --allow-unrelated-histories`), so later upstream work can be merged:

```sh
git remote add upstream https://github.com/thunderbird/thunderbird-ios.git   # once
git fetch upstream
git merge upstream/main
```

Expect conflicts in the bundle identifier, `fastlane/Fastfile`, `Thunderbird/Thunderbird/Info.plist`, and `.github/workflows/test.yml`. Keep `com.verkvest.thunderbird` when resolving those.
