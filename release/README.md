# Don't Touch Me — complete version 1.0 release materials

This folder contains the publishing handoff, not additional gameplay. The project remains Godot 4.7.2, GDScript, offline, and exactly 16 reactions.

| Material | Location |
| --- | --- |
| All icons, feature graphic, and 20 actual gameplay captures | `assets/` — see `assets/README.md` and `assets/manifest.json` |
| Store descriptions, subtitle, keywords, and release notes | `STORE_LISTING.md` (copyable); `listing.json` (validated source fields) |
| Privacy policy | `PRIVACY_POLICY.md`; ready-to-host HTML at `../docs/privacy.html` |
| Google Play declarations | `DATA_SAFETY.md` |
| Apple declarations / native privacy checks | `APP_STORE_PRIVACY.md` |
| Content-rating suggestions / owner decisions | `CONTENT_RATING.md` |
| Free policy hosting steps | `PUBLISH_PRIVACY.md` |
| Mac/Xcode export handoff | `IOS_EXPORT.md` |
| Every remaining submission step by responsibility | `RELEASE_CHECKLIST.md` |
| Executed test/build results | `BUILD_REPORT.md` |
| Reproducible graphics/notices/validation scripts | `tools/` |

Generated executables, APK, AAB, archives, and SHA-256 manifests belong under ignored `../builds/`. They are **not** downloadable from a source clone. The AAB preparation preset deliberately has no production signature; no production key, developer account, payment, store submission, hosting activation, or physical-device test is represented as completed.

Apple screenshot dimensions are prepared, but the images are Windows Godot renderer captures, not verified iOS-device captures. Compare/replace them on the Mac before final upload. No gameplay or OS UI was fabricated.

The public repository has no game-code/art license assigned by this task. Commercial publication remains the owner's decision, including ownership and name clearance. Engine and bundled-component notices are generated in `../THIRD_PARTY_NOTICES.txt` and included in app exports.
