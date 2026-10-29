# Apple App Privacy — owner review draft

Based on the same version 1.0 source audit as `DATA_SAFETY.md`. No iOS binary has been built on this Windows PC.

## Proposed declarations

- **Data collected:** No — suggested label **Data Not Collected**, provided the final iOS binary and any integrated SDKs match this audited offline design.
- **Tracking:** No. The game has no cross-app tracking, advertising identifiers, advertising SDKs, or tracking domains.
- **Account creation / deletion:** No accounts exist in the game.
- **Permissions:** The gameplay needs no camera, microphone, location, photos, contacts, notifications, or tracking permission. Inspect the generated Info.plist and remove any unnecessary capability or usage-description entries before archiving.
- **Privacy-policy URL:** Use https://miguelxhubgitty.github.io/dont-touch-me/privacy.html, published and publicly verified. Confirm the declarations as the owner before submission.

## Required Mac-side verification

1. Export with Godot 4.7.2 on macOS/Xcode using the intended team and bundle ID.
2. Inspect the archive's embedded frameworks, signing, entitlements, Info.plist, and **PrivacyInfo.xcprivacy** manifests. Godot's native code may use required-reason APIs even though the game's GDScript does not collect data. No required-reason API declaration has been invented here.
3. Use Xcode archive validation/privacy reporting to resolve missing SDK signatures, manifests, and approved API reasons. A privacy label and a privacy manifest serve different purposes; a no-collection answer does not remove manifest obligations.
4. Test on iPhone, inspect platform diagnostics/network behavior, and verify that no additional plugin or SDK changes the data practices.
5. Confirm the final App Privacy form as the developer. Do not submit this draft blindly or claim an external privacy certification.

Local engine caches/diagnostics and separately initiated GitHub support communication are explained in the policy. They do not imply an in-app analytics service. Any future automatic crash upload, analytics, account system, ad SDK, or purchase integration requires a new assessment.

Official guidance: [App Privacy details](https://developer.apple.com/app-store/app-privacy-details/), [managing App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/), [privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files).
