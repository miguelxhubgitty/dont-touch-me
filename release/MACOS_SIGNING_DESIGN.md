# macOS signing and packaging correction

The Alpha macOS export disabled signing, retaining the engine-template signature without sealing the finished app's resources. CRC checks and executable permissions alone did not detect this. This design changes release tooling only; gameplay, artwork, version numbers, release tags and other platform outputs stay unchanged.

1. New macOS presets use Godot's built-in ad-hoc signing. Synchronization migrates an existing disabled macOS signer to this default, while preserving explicitly configured external/Apple signers and notarization settings. Do not rewrite Windows or other preset signing options.
2. Reject a macOS ZIP without exactly one app executable, executable permissions and a nonempty app resource-seal manifest. On macOS, extract safely and require strict verification for all architectures with Apple's codesign. Cross-host checks must not claim native signature verification or Gatekeeper trust.
3. Apply the same guard before packaging, retaining app file bytes and UNIX permissions. Change only the macOS export/package cache recipe so previously validated unsigned artifacts are not silently reused. Keep other platform cache recipes unchanged.
4. Record ad-hoc signing as local integrity, not Developer ID trust, notarization or native runtime validation. Keep the publisher's existing no-replacement default; this owner's explicitly approved one-time asset correction is a separate bounded operation with backups and public verification.
5. Test preset migration/isolation, missing-seal and unsafe-path rejection, packaging byte/mode preservation, and a real built-in-signed Godot export verified by codesign. Run the existing Python regression suites and the repository's required PowerShell workflow integration check.

No changes to the active release source or gameplay are needed. This branch targets main for future release preparation; no PR is merged automatically.
