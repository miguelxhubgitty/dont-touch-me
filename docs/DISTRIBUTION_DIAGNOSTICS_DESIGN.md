# Local distribution diagnostic design — 2026-11-01

The task is to separate archive corruption, executable signature integrity, app-bundle signing, and Gatekeeper trust before proposing a release change. No gameplay or visual-design change is required.

Use a scratch copy of release commit `7af0d6dc06372713ca223cfb0e02e92fd5b9f0cf` outside Git. Compare the published executable with the installed Godot 4.7.2 release template, reproduce the current signing-disabled export, and generate a second export with local ad-hoc app signing. Compare executable/resource hashes and ZIP round trips. Test signature verification separately from Gatekeeper assessment: ad-hoc integrity is not Developer ID trust or notarization.

Keep the published ZIP and its quarantine metadata unchanged. Put corrected local exports under `WorkstationSetup/distribution-lab/exports`; do not overwrite the GitHub release, tags, source presets, artwork, or gameplay. Do not disable Gatekeeper or remove quarantine to claim a passing distribution test.

For iOS, inspect installed runtime availability and recent Apple installation logs before any retry. Boot an Intel-compatible runtime if available. Inspect the actual Xcode Personal Team and configure only free local development signing. Never invent a Team ID. Use scratch export presets and generated Xcode projects outside the repository. Simulator builds and device signing are separate gates; a Simulator success does not imply physical-device or App Store readiness.

Record exact commands, versions, hashes, failures, observed UI outcomes, and remaining manual/account requirements in a separate results document. Required source/tooling changes, if any emerge, need a focused design update before implementation; this diagnostic plan does not authorize gameplay changes or publication.

The generated iOS project hard-codes arm64, preventing destination matching for an Intel Simulator. For the scratch generated project only, use Xcode's standard architecture variable so device builds remain arm64 and Intel Simulator builds select x86_64. The command-line build also stalls in Interface Builder tooling, with SkyLight connection errors in its logs; retry through the GUI Xcode build session to distinguish a launch-context problem from a project failure. Do not remove the launch storyboard or alter app visuals to bypass the compiler.

The standard architecture setting still selected arm64 in Xcode's GUI and produced an arm64 `_main` linker error. An explicit x86_64 Simulator build succeeded. Keep the standard device setting and add an SDK-specific x86_64 Simulator override only in this Mac's generated scratch project. This is local host configuration, not a change to the released game's source or assets.
