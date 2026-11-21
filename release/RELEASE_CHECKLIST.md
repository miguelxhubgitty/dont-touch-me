# Only the owner's remaining tasks — version 1.0

## Organization identity (November 11, 2026)

D&B confirmed an existing D-U-N-S match for **ONE TRU THING ONLY LLC** in a resolved November 10, 2026 inquiry. Its revised data was expected to propagate within 24–48 hours; actual downstream visibility and the reported legal-form classification still need checking. **WANDIEL** is the brand; the LLC remains the legal entity until a formal rename is completed. Neither Apple nor Google organization enrollment is confirmed by the D&B response. The detailed resolution record is private and must not be copied to this public repository.

## Google Play

- [ ] Open the existing `com.wandiel.donttouchme` app in Play Console. Confirm the highest version code in App bundle explorer and across tracks. Set a greater code before preparing the update. Code 4 is the local candidate above the verified code-3 artifact.
- [ ] Confirm publisher/legal identity, name/content rights, audience, countries and pricing. Use support@wandiel.com for customer support/review contact and hello@wandiel.com for business enquiries. Approve the privacy, Data safety and content-rating answers in the prepared documents. Use the published privacy URL: https://miguelxhubgitty.github.io/dont-touch-me/privacy.html and support URL: https://miguelxhubgitty.github.io/dont-touch-me/.
- [ ] Compare the earlier upload signer with the current **Upload key certificate** in Play Console. After approval, use that existing authorized key and keep the original unsigned AAB intact. Follow [PRODUCTION_SIGNING.md](PRODUCTION_SIGNING.md).
- [ ] Carry forward a reviewed in-app Privacy Policy control on Android and test native touch and browser return. The published-line Alpha has an Android-only button. Current `main` has no equivalent control.
- [ ] Test the game on physical Android phones/tablets, including all reactions, touch precision, safe areas, app switching/lock, performance and update/signing behavior. An Android 9 BlueStacks session passed at two display profiles; newer Android versions and physical devices still need testing. Resolve any device findings before production.
- [ ] After upload authorization, use the existing app's internal testing track to test the update. Review Play's SDK, generated APK, 16 KB compatibility and pre-launch reports. Verify installation and upgrade on a 16 KB Android configuration and on a representative physical device.
- [ ] Confirm current store assets and declarations against the update. Submit for review and approve rollout separately.

## Apple App Store

- [ ] Arrange access to a Mac with supported macOS, Godot 4.7.2/templates and current required Xcode/iOS SDK (presently Xcode 26+/iOS 26+ SDK, deployment iOS 13+). Sign in to or enroll/join your intended Apple Developer Program team, handle any membership payment yourself and supply the actual Team ID.
- [ ] Register/confirm the bundle ID and chosen iPhone/iPad families. Follow IOS_EXPORT.md to configure your real signing/provisioning, export the Xcode project and produce a Release archive. Resolve archive validation, entitlements, SDK/privacy manifests, approved API reasons and export-compliance declarations against the actual iOS binary.
- [ ] Test on iPhone and iPad if supported, including safe areas, touch, lifecycle and mobile performance. Verify or replace the prepared Apple-sized reference renders with native captures. They are dimension-ready Godot renders, not iOS device-test evidence.
- [ ] Create the matching App Store Connect record, confirm legal/publisher identity, content rights, audience/age-rating answers, pricing/countries and privacy answers; supply a real review/support contact. Use the published privacy URL above and the prepared listing/icon material. Do not select Kids Category without making and checking that audience decision.
- [ ] Upload the validated signed archive through Xcode, complete TestFlight testing, and provide accepted native-verified iPhone screenshots plus iPad screenshots if that family is enabled. Increase the build number for replacement uploads as required.
- [ ] Select the tested build, complete all store declarations/review notes, respond to any App Review findings and make the final submission/publication decision yourself.
