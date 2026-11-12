# WANDIEL Android Alpha review exports

Source runtime: `9788e0343cb888a31ea9092f7409e2455a961261` (audio-free Public Alpha).
The source changes are limited to Android packaging, release metadata, docs
and tests. The frozen release tag and historical artifacts remain authoritative
for the original public builds. These new files are local review outputs only.

Both files use `com.wandiel.donttouchme`, version `0.1.0-alpha`, code `2`,
min SDK 24, target SDK 36, and ARM64. No Android permissions were declared
in the inspected manifests. Both files are unsigned and require an authorized
signing identity before installation or store delivery.

| Unsigned review output | SHA-256 |
|---|---|
| DontTouchMe-v0.1.0-alpha-wandiel-unsigned.apk | `1797dd71788ef52675cf85c06021c9aa2c44ccbee2d52bf7b085e7d4f9028334` |
| DontTouchMe-v0.1.0-alpha-wandiel-unsigned.aab | `153d01e8d7fbbdcb7db3ba8d8b19cd2a2968fa6c88772dfd3eaf777088cf0df1` |

The APK passed 16 KiB zipalign and the AAB passed Bundletool 1.18.3.
All four packaged native library copies passed ARM64 ELF and 16 KiB
load-alignment checks. Game assets match the original except for regenerated
Godot indices and the binary scene identifier. Godot loaded both binary
scenes and matched node types, paths and properties. The APK also contains
Android baseline profile metadata. The behavior, release, package, typography
and Python checks passed. No physical-device installation was performed.
The APK inspector repeated the themed-icon resource warning present in the
old APK. Confirm the launcher icon on a Galaxy device before submission.

The owner reports no APKs or AABs uploaded to Samsung or Amazon and no Apple
app uploads. Unused draft package records, store certificates and version-code
history still require account confirmation. Store rules and signing continuity
are covered in [Android identity and signing](ANDROID_IDENTITY.md).
