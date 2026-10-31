# Branch-workflow verification — October 31, 2026

## Scope and preservation

- Fetched and inspected `origin/main` at `c7397822bf4e4303404f57544b1c35f3db57165f` and `origin/aesthetic/typography-v1` at `c0bfa4e18b8d4050c810518d48df66bfa76acc22`.
- Main's gameplay script, main scene, project settings and export presets remain identical to the basic-font restoration. All 15 regular reactions, wake, annoyance/decay, sleep, interruption, shared hitboxes, input, focus handling and layouts are preserved.
- The aesthetic branch's gameplay script, typography runtime, Space Grotesk font/variation/license, ten cached Ink Free phrase graphics/import settings, export settings and existing store image bytes remain unchanged from `c0bfa4e`. Authoring/tests/tooling/documentation are the only updates. The inventory's documentation entry is refreshed for the updated authoring instructions; capture manifests and image fingerprints are unchanged.
- No typography or store artwork was regenerated. No exports, finished release tags, uploads, website/business changes, resets or force pushes were performed. Test fixtures are ignored local clones, never pushed.

## Existing suites, Godot 4.7.2

| Suite | Basic-font main | Aesthetic branch | Integrated future-gameplay fixture |
|---|---:|---:|---:|
| Behavior | 320,270 passed | 320,270 passed | 320,270 passed |
| Release/input/layout | 237,076 passed | 237,076 passed | 237,076 passed |
| Source-fingerprint regression | 17 passed | 17 passed | 17 passed |
| Typography | Intentionally absent | 127 passed | 127 passed |
| Existing release package | 179 passed | 196 passed | One expected stale-capture rejection |
| Saved release-asset inventory | 45 files verified | 45 files verified | Intentionally left historical |

Project imports completed with no script errors. Initial restricted runs could not write Godot's normal editor settings/logs; clean verification used normal local editor access. This is automated desktop evidence, not a new physical-device or store certification.

## Corrections and regression coverage

Fresh Windows checkouts initially produced false package failures: main's gameplay fingerprint and three aesthetic source fingerprints differed solely because Git checked text out as CRLF. New manifests normalize source text to LF and preserve raw binary hashes; legacy LF/CRLF text fingerprints remain verifiable. Regression tests reject actual source changes, changed binary bytes, missing sources/hashes and unknown modes. Original manifests/captures were not edited to make tests pass.

`tests/workflow.ps1` passed **19 integration/guard assertions** against an isolated local clone. It:

- rejects `main`, dirty trees and repeated application;
- preserves a simulated newer gameplay constant, project version and Android version codes;
- applies the actual runtime fonts/phrases and export license inclusion;
- verifies `-CheckOnly` leaves the real index and working tree untouched;
- verifies old store captures/manifests are not copied from the aesthetic snapshot;
- verifies cached font/phrase resources match the approved aesthetic branch;
- deliberately creates a conflicting font edit and verifies preflight rejects it without partial files or real-index changes.

The integrated fixture also passed the existing runtime/layout/typography suites. Package validation rejected its unchanged basic-font capture manifest for the expected source mismatch, demonstrating that fresh captures are still required at finalization. Both aesthetic authoring generators refused invocation without `--finalize-release`; no graphics were rendered by those rejection checks.

The fixed integration base is `5be3a20475bba305c3ca26a07141771792e6b309`, not moving `main`. A temporary-index merge detects real conflicts before applying. `git apply --3way --check` alone proved insufficient: it can exit successfully while predicting a conflicted merge, so the helper does not rely on that check.

See [BRANCH_WORKFLOW.md](BRANCH_WORKFLOW.md) for normal development, release integration, the single asset-finalization pass, exports, validation and annotated release tags. Do not merge completed release presentation wholesale back to main.
