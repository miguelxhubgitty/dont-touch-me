# Google Play Data safety — owner review draft

Audit date: 2026-10-29. Scope: the version 1.0 game in `scripts/blob.gd`, `main.tscn`, `project.godot`, Android export presets, and the generated Android APK manifest. Release tools, tests, GitHub, and store services are not app runtime features.

## Code findings

- The shipped scene contains one Node2D with one GDScript. The script processes pointer coordinates, timers, a random generator, annoyance, expressions, and drawing geometry in memory.
- No gameplay FileAccess/DirAccess writes, databases, player profiles, account identifiers, analytics SDKs, advertisements, billing, chat, user-content uploads, or authentication.
- No HTTPRequest, HTTPClient, WebSocket, multiplayer peer, network URL, shell execution, or external service calls in shipped gameplay code.
- Android export disables INTERNET. The test APK manifest has no `uses-permission` declarations. Manifest checks are repeated on the final APK in `BUILD_REPORT.md`.
- Godot may write local technical logs/cache. The game has no code to upload them. Local engine diagnostics are not a claim that no filesystem activity occurs.
- This is code/manifest inspection, not packet-capture testing or a source-level audit of every line of the compiled Godot engine. The iOS binary remains unbuilt and unaudited.

## Suggested Console answers — verify the final release AAB

| Question | Suggested answer | Basis |
| --- | --- | --- |
| Does the app collect or share required user data types? | **No** | No off-device data transmission by the game or embedded collection SDKs identified. |
| Data shared with third parties | **None** | No sharing path in game code. |
| Account creation methods | **App does not allow users to create an account** | No sign-in or account system. |
| Account deletion | Not applicable to in-app accounts | There are no in-app accounts or stored profiles. Do not create a fictitious deletion website. |
| Advertising ID | **Not used** | No ad SDK/ID access; no AD_ID permission. |
| Ads declaration | **No ads** | No advertisements or ad SDK. |
| In-app purchases | **None** | No billing implementation. Store purchase of the app itself, if chosen later, is separate. |
| Data encrypted in transit / deletion mechanisms | Follow the Console's no-collection branch; do not claim an encryption feature | The game has no data transit service. |
| Independent security review / certifications | Do not claim one | No external certification was obtained. |

Google still requires a Data safety form and privacy-policy URL for apps with no collection. The operator must verify declarations for the final release binary, all included libraries, and the selected business/audience model. If any SDK, crash reporting, login, monetization, or networking is later added, repeat the audit before release.

The support link is a separate GitHub website. Voluntary public issue content and GitHub-hosted website traffic are not silently treated as in-app collection; disclose the actual support/website practices in the policy.

Official guidance: [Data safety definitions and form](https://support.google.com/googleplay/android-developer/answer/10787469).
