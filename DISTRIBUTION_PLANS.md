# Don't Touch Me — Distribution Plans

Updated: 2026-10-29

**Status key:** Not verified = no confirmed public upload; Uploaded = file submitted but not published; Published = live URL verified; Rejected = submission declined. Do not mark Published without a working public destination link.

**Current position:** Game source and release preparation are on GitHub. This does **not** mean the game has been published to any of the destinations below. All distribution statuses start **Not verified** pending checking each destination.

| Destination | Format | Submission / destination | What's needed | Priority | Upload status | Public game URL | Date |
|---|---|---|---|---|---|---|---|
| itch.io | Web (HTML5), Windows ZIP, Android APK | [Open](https://itch.io/game/new) | Free account; upload builds and screenshots | Priority 1 | Not verified | — | — |
| Game Jolt | Web / Windows / Android if supported | [Open](https://gamejolt.com/) | Creator account; game page and builds | Priority 1 | Not verified | — | — |
| Newgrounds | Web (HTML5) | [Open](https://www.newgrounds.com/projects/games) | Browser build; submission review | Priority 2 | Not verified | — | — |
| GitHub Releases | Windows ZIP, Android APK | [Open](https://github.com/miguelxhubgitty/dont-touch-me/releases) | Attach versioned binaries to release | Priority 1 | Not verified | — | — |
| GitHub Pages | Web (HTML5) | [Open](https://pages.github.com/) | Test web export; enable Pages | Priority 1 | Not verified | — | — |
| Cloudflare Pages | Web (HTML5) | [Open](https://pages.cloudflare.com/) | Free deployment; test browser compatibility | Optional | Not verified | — | — |
| CrazyGames | Web (HTML5) | [Open](https://developer.crazygames.com/) | Submit for review; platform integration if required | Priority 2 | Not verified | — | — |
| Poki | Web (HTML5) | [Open](https://developers.poki.com/) | Apply; review commercial terms/exclusivity | Optional | Not verified | — | — |
| Playgama | Web (HTML5) | [Open](https://developer.playgama.com/) | Check SDK/integration and approval | Priority 2 | Not verified | — | — |
| GameDistribution | Web (HTML5) | [Open](https://gamedistribution.com/) | Check publishing terms and technical requirements | Optional | Not verified | — | — |
| Y8 | Web (HTML5) | [Open](https://www.y8.com/) | Verify developer submission route | Optional | Not verified | — | — |
| GamePix | Web (HTML5) | [Open](https://www.gamepix.com/) | Verify developer onboarding and requirements | Optional | Not verified | — | — |
| Coolmath Games | Web (HTML5) | [Open](https://www.coolmathgames.com/) | Editorial acceptance required | Optional | Not verified | — | — |
| Armor Games | Web (HTML5) | [Open](https://armorgames.com/) | Editorial acceptance required | Optional | Not verified | — | — |
| Google Play | Signed Android AAB | [Open](https://play.google.com/console/signup) | $25 developer registration; identity, closed test if applicable; store review | Later | Not verified | — | — |
| Apple App Store | Signed iOS build | [Open](https://developer.apple.com/programs/enroll/) | $99/year; Mac/Xcode; account, review | Later | Not verified | — | — |
| Samsung Galaxy Store | Android package per current seller requirements | [Open](https://seller.samsungapps.com/) | Seller account and approval; device testing | Priority 2 | Not verified | — | — |
| Microsoft Store | Windows packaged build | [Open](https://partner.microsoft.com/dashboard) | Account and packaging/certification requirements | Later | Not verified | — | — |
| Steam | Windows / Linux / macOS build | [Open](https://partner.steamgames.com/) | $100 app fee; store setup and review | Later | Not verified | — | — |
| Epic Games Store | Windows build | [Open](https://dev.epicgames.com/portal/) | Per-game submission fee and store requirements | Later | Not verified | — | — |
| Amazon Appstore | Android / Fire-compatible build | [Open](https://developer.amazon.com/apps-and-games) | Check current device support and submission eligibility | Optional | Not verified | — | — |
| F-Droid | Open-source Android package | [Open](https://f-droid.org/en/docs/Submitting_to_F-Droid/) | Open-source licensing/reproducible build rules | Optional | Not verified | — | — |
| Uptodown | Android APK | [Open](https://www.uptodown.com/) | Check developer submission and verification process | Optional | Not verified | — | — |
| Aptoide | Android APK | [Open](https://www.aptoide.com/) | Check publisher onboarding and security checks | Optional | Not verified | — | — |
| Own website | Web (HTML5) or direct download | [Open](https://github.com/miguelxhubgitty/dont-touch-me) | Set up hosting/domain; post player link | Optional | Not verified | — | — |

## Release procedure

1. Confirm the actual generated binaries and browser export work, rather than relying on a build report alone.
2. Upload to a destination, record **Uploaded** with the date.
3. Once accepted and accessible, record **Published** and the exact public URL.
4. Keep APK/AAB signing credentials out of Git. Update the version and attach release notes when publishing new builds.
5. For browser portals, validate Godot HTML5 export on mobile and desktop browsers; approval or SDK changes may be needed.
6. Fees, platform requirements, and supported formats can change. Verify the destination's latest policy before submission.

## Publisher identity

Your Northwest screenshot identifies the business as **One Tru Thing Only LLC**. Its legal active status, good standing, and use as publisher are **not verified by this screenshot**. Working studio-name idea: **One Pass** (name availability not verified).

## Notes

- GitHub source commits are not the same as a GitHub Release containing downloadable game builds.
- The existing Android test APK is different from a signed, production-ready AAB.
- The iOS version still requires a macOS/Xcode export and verification.
