# macOS and iOS testing status

Current as of November 1, 2026. This index consolidates the three local testing-documentation branches into one documentation-only change for main. Archived reports preserve the original observations and limitations; later evidence supersedes earlier blockers.

- [Verified macOS release correction](MACOS_RELEASE_CORRECTION.md): approved game-content comparison, native interaction checks, asset backups/replacement, anonymous checksums and website-link verification.
- iOS 26.5 Simulator installation and Intel Xcode build/launch succeeded. Simulated touches and inactivity sleep/wake were observed. A valid free Apple Development identity exists; physical-device provisioning still needs a connected/trusted device. See the [distribution diagnostic results](history/2026-11-01-distribution-results.md).
- macOS signatures now pass strict verification for all architectures, but ad-hoc signing is not Developer ID trust or notarization. “Apple could not verify” remains expected; no global security bypass was performed.

## Preserved reports and provenance

| Source branch | Preserved evidence |
| --- | --- |
| `docs/macos-native-testing-2026-10-31` | [Initial native game testing](history/2026-10-31-native-testing.md) |
| `docs/macos-ios-workstation-2026-10-31` | [Workstation audit and installation](history/2026-10-31-workstation.md) |
| `docs/distribution-diagnostics-2026-11-01` | [Design](history/2026-11-01-distribution-design.md) and [results](history/2026-11-01-distribution-results.md) |

The old workstation report's incomplete Simulator download and missing signing identity are historical. The later diagnostic report establishes a working Simulator and Apple Development identity. Its statement that the corrected ZIP was local-only is superseded by the release-correction receipt above. No historical report should be treated as current release metadata.

Automated checks and native/UI observations are explicitly distinguished in the reports. No physical iOS device or App Store approval is claimed. No release presentation, gameplay or assets are merged into main by this documentation change.
