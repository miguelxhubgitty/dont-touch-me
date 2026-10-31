# Internal Development Journal — Don't Touch Me

**Audience:** project owner. Internal, detailed, source-grounded. Not public devlog content.

## Purpose
A living, readable explanation of every important part of the game, from player experience through implementation and release. Record *why* things work as they do, not just *what* changed. Make it possible to question any mechanic, formula, parameter, animation, edge case, test, or release decision with an exact source reference.

## Required sections to maintain
1. **Current snapshot:** version, Git branch and commit, what is live versus locally developed, verified facts and unverified claims.
2. **Player experience:** walkthrough from first launch; click/touch; idle, annoyance, relaxation, sleep, wake; all 15 normal reactions and the special reaction.
3. **Mechanic reference:** variables, defaults, thresholds, timers, random pools, weighting/repetition rules, state changes, interruption rules, recovery, resize/focus behavior, and edge cases. Source function/file references and worked examples.
4. **Animation and rendering:** geometry, transforms, drawing order, timing, hit detection, face/eye attachment, sleeping movement, aspect ratios, performance choices. Explain observations separately from confirmed root causes.
5. **Project anatomy:** Godot version, scene tree, scripts, exported resources, typography, platform configuration and reasons for separation.
6. **Testing:** suites, exact meaning and limitations of checks; smoke tests vs device tests; known defects and regression coverage.
7. **Distribution and operations:** per-format builds, release branching, aesthetic integration, artifact caches, itch.io, website, signing and approvals. Distinguish a draft, upload, live publication and verified availability.
8. **Decision history:** issue, alternatives, chosen solution, rationale, trade-offs, linked commits and what was deliberately deferred.
9. **Open questions and future ideas:** status [idea | planned | in progress | tested | shipped | rejected], priority, acceptance criteria, prerequisites; link to `plans/` and `GAME_ROADMAP.md`.
10. **Change-by-change entries:** date, scope, before/after user experience, technical reason, affected files/functions, tests run, risks, resulting commit, release destination.
11. **Glossary and question index:** explain all technical terms in accessible English and point common questions to exact sections.

## Editorial rules
- Explain in plain English first, technical detail second, examples third; be exhaustive but not repetitive.
- Source facts from the actual code, tests, and Git history. Never invent or infer exact values, implementation choices, or test results. Mark unknowns explicitly.
- Keep **planned** changes distinct from **implemented** and **published** work.
- Record failed attempts and unresolved bugs when relevant; do not quietly erase them.
- Use links to repository files, functions and commits. Do not copy secrets, tokens, private keys or confidential business information.
- Append meaningful dated entries rather than rewriting history; update the current reference sections when behavior actually changes.
- Public devlogs are **separate**. Their brief, dry, critical Butter Boy voice is not required here.

## Audited reference — October 31, 2026

This journal is now populated against actual source and Git history. Companion chapters are [the complete implemented pseudocode](ALPHA_BEHAVIOR_SPEC.md) and [the source/evidence audit](ALPHA_SOURCE_AUDIT.md). Together they explain every controller function, all16 reactions, calculations, examples, historical distinctions and evidence limitations. “Internal” means owner-oriented, not private: this repository is public; no confidential information belongs here. Dates use America/New_York.

### Searchable question index

| Owner question / search phrase | Answer location |
| --- | --- |
| Which exact source was published? Is main the same? | [Current snapshot](#current-snapshot); source audit baseline comparison |
| Why does main look different from itch? | [Typography decisions](#typography-and-branch-decisions); pseudocode §11 |
| What happens on the first tap? | [Player walkthrough](#player-walkthrough); pseudocode §2–3 |
| Why does the box ignore me? Can I tap peek eyes? | Pseudocode §2, §7 BOX; [Mechanic reference](#mechanic-reference) |
| Which reactions belong to which tier? Weighted or random? | Pseudocode §3, §7 |
| Can fast tapping guarantee all reactions? | Pseudocode §3: exclusive pools and no discovery guarantee |
| Can I interrupt waking, hiding or running? | Pseudocode §5 and §7 WAKE/BOX/RUN |
| How much annoyance per tap? How fast does it decay? | Pseudocode §3–4 |
| Can it sleep while still annoyed? | Pseudocode §4:100→about14 example |
| Does leaving the app count as idle time? | [Platform behavior](#platform-specific-behavior); pseudocode §4 |
| Why do sleeping eyes jump? Fixed yet? | [Known issues](#known-issues-and-evidence-gaps) |
| Are eyes separate sprites? Why can an interruption snap? | Pseudocode §5, §8–9 |
| How long is every animation? How far does it jump? | Pseudocode §6–7 |
| Does a sign block input? Does flattening prevent taps? | Pseudocode §2, §7 SIGN/FLATTEN |
| Why does running return to center? | Pseudocode §5, §7 RUN |
| How are speech, shadow, props and screen scaling calculated? | Pseudocode §8–11 |
| What was really tested on phones? | [Testing](#testing-and-validation); source audit evidence limits |
| Which builds are public versus prepared? | [Distribution](#distribution-and-release-operations) |
| Where do signing keys, artifacts and notices go? | Distribution section, `.gitignore`, signing guide |
| Has sound, trust, petting or customization been added? | [Future work](#planned-future-behavior) |
| Why were these particular constants chosen? | [Decisions](#recorded-decisions-and-unknown-motivations) |
| How do future approved changes stay documented? | [Change protocol](#ongoing-change-protocol), `AGENTS.md` |

### Current snapshot

| Category | Immutable identity | Meaning |
| --- | --- | --- |
| **Published Alpha runtime** | Export source `9788e0343cb888a31ea9092f7409e2455a961261`; preserved at tag `v0.1.0-alpha` → `d61c86568b40c23a291db7aa2757ffe82e1896e8` |15 regular reactions + WAKE, approved typography, Alpha version metadata. Tag was created at preparation, before publication. |
| **Publication record** | Release commit `6bf3a467bdc994f5a29ebf47975bb10b0c499fc1`, merged at `c2ea4a003403c7568944e74dd069e03a9e9d2bff` | Existing Windows/Web packages made public October31; no runtime change. |
| **Development snapshot** | Latest fetched main `8cee57ced64e5640872518e2a3822a6e93c65d03` | Same controller mechanics, engine fallback font, main project still1.0.0/code1, catalog planning0.1.0-alpha/code2. |

This documentation branch starts directly at that main commit. Runtime paths (`scripts`, `assets`, scene, project and export settings) are identical between9788e03, the Alpha tag and the recorded publication tip. Main differs in typography calls/filtering and release settings/assets, not reaction calculations. “Current” is a pinned audit snapshot, not a guarantee about future moving main.

Recorded live destination: [wandiel.itch.io/dont-touch-me](https://wandiel.itch.io/dont-touch-me), No payments, In development, Public Alpha, browser play and Windows download. This task reads Git publication evidence; it does not freshly certify server state or download/inspect binaries. Main's older distribution tables and preparation reports retain earlier unpublished snapshots. Use the later release-branch publication record for historical publication status, not an old all-unpublished table.

### Player walkthrough

Launch shows a warm portrait canvas, title, two small captions, black blob, white eyes and faint shadow. It breathes, wobbles, blinks and looks around. No menu, tutorial modal, score, level, win/lose condition, persistent progress or sound exists.

A left click/finger press on its **current visible shape** adds7–10 hidden annoyance. First hit chooses blink, side-eye or squish, dismisses the introductory text and flashes short touch marks. Background presses do nothing. Quick successive hits escalate through complaints, evasive motion, defensive gestures, hiding and running. Selection is uniform among the current tier except the last started reaction; older tiers aren't retained. Rapid escalation can skip seeing earlier reactions.

After2.5 simulation seconds without an accepted hit, annoyance decays4 points/second. At24 seconds idle, once any reaction has finished, it sleeps with slow breathing, thin eyes and rising z/Z. Sleep doesn't require zero annoyance. A successful body hit adds annoyance, wakes and starts “I was DREAMING.”; another hit can interrupt WAKE. Restart resets all memory. Losing focus freezes automatic time, so unfocused real-world time doesn't advance sleep. See pseudocode §1–7 for exact ordering and exception cases.

### Game architecture and scene organization

| File/resource | Responsibility | Alpha versus main |
| --- | --- | --- |
| `project.godot` | Entry, version,720×1280 canvas,432×768 preview, portrait, input emulation disabled, Compatibility renderer/background/icon | Alpha0.1.0-alpha; main1.0.0; common layout/input |
| `main.tscn` | One root `Node2D` named DontTouchMe with blob script | Identical |
| `scripts/blob.gd` | Entire input, hit detection, annoyance, timers, reaction state, pose and drawing | Common mechanics; font/filter differences |
| `scripts/typography.gd` | Measures/draws cached phrases or fonts | Alpha only |
| `assets/fonts/`, `assets/typography/` | Space Grotesk/OFL/title variation, ten whole-phrase images/metrics | Alpha only; no Ink Free font distributed |
| `icon.svg`, `assets/icon_*` | Launcher resources | No gameplay logic |
| `export_presets.cfg` | Exports, excludes/notices, version/build settings | Main3 presets; Alpha6 including Web/Linux/macOS |
| `tests/` | Behavior/layout/fingerprint, optional rendering, packaging fixtures | Alpha additionally typography; later release additionally itch tests |
| `release/tools/` | Authoring, validation, integration, packaging, reports | Operator tools, not game runtime |
| `release/catalog/`, `release/distribution/` | Shared metadata, platform prerequisites and publication records | Some main records predate published release records |
| `release/assets/` | Historical store captures with fingerprints | Not used to animate the character |
| `plans/`, `GAME_ROADMAP.md` | Proposals | No runtime effect |
| `docs/` | Public support/privacy and owner-oriented implementation docs | Not confidential storage |
| ignored `builds/`, `test-output/`, `.godot/` | Local outputs, QA and caches | Not source-controlled; may be absent on another machine |

There are no child eye nodes, physics bodies, collision nodes, animation players, tweens, plugins, backend, HTTP requests, accounts, analytics, ads, purchases, currency, audio players or save storage in the controller. Bundled resource loading isn't content downloading. Web hosting still involves an external host; native offline gameplay doesn't imply the host collects no connection data.

### Mechanic reference

Pseudocode §1 lists **every** variable/default, §2 input/hit order, §3 exact pools/boundaries, §4 update order/timers, §5 interruptions and movement, §6 base pose/math and §7 all16 reaction branches. This companion specification is the detailed mechanic chapter of this journal, including worked examples and test references per system.

There are three layers of state. Session behavior consists of annoyance, idle time, sleep, last-started reaction, clock and random generator. Active reaction consists of one enum value, elapsed time and movement origin/destination/direction. Derived drawing pose consists of position/scale/angle, eye opening/gaze, prop amounts and speech. `_update_pose` resets the drawing pose to breathing defaults, then applies exactly one reaction's formulas.

This prevents competing animations from accumulating corrupted scales or positions. It doesn't blend interrupted poses: a jump interrupted by another hit can snap to anchor.y; shake displacement can become the next resting x. RUN/BOX protection is in `touch_at`, not in `begin_reaction`; tests directly calling the helper can bypass that protection. Resize clears reaction/recenters even during escape, retaining annoyance, sleep, timers and last reaction. Wake takes precedence over ordinary selection; annoyance increment happens first.

Annoyance isn't a permanent idle facial expression. It selects a pool when input arrives; reaction pose supplies expression. It decays during long reactions too. All blinks/gaze timers continue while asleep/reacting, even if visually overridden. Natural idle blinking doesn't count as a reaction or change repetition history. The last started reaction includes interrupted ones and WAKE, not merely completed animations.

Hit shape is the current transformed80-point outline. Peek eyes accept before cardboard/flaps reject; other exposed body then accepts. Sign/hand/speech/shadow/z marks have no independent hit shapes. Turning and flattening alter the visible polygon but never grant total immunity. Pseudocode §2 documents rectangular cardboard versus rounded drawing and edge/pixel limitations.

### Animation and rendering

| Animation group | Complete contents / detailed reference |
| --- | --- |
| Idle | Awake/sleep breathing, wobbling outline, discrete random gaze,0.17-second natural blink; pseudocode §4/§9 |
| Calm | Surprise blink/stretch, directed side-eye/tilt, damped squash; §7 reactions1–3 |
| Annoyed | Narrow eyes/angular oscillation, Don't tilt, Seriously asymmetric eyes/upward gaze, eased slide; reactions4–7 |
| Angry |175-unit hop,11 horizontal/9 angular shake cycles, pancake, eye-fade turn/rear arc, swelling STOP/jitter, raised NO sign; reactions8–13 |
| Furious | Shared shout/sign, cardboard rising/peek eyes, offscreen exit/wait/peek/return with hopping; reactions12–15 |
| Wake |100-unit startle, oversized eyes then abrupt squint, complaint; reaction16 |
| Secondary | Shrinking jump shadow, fading touch ticks, introduction fade, speech hold/fade/vertical offset, rising/fading sleep letters; §8–10 |

Normal eyes share body rotation/scale, with local centers shifted by gaze. The locally wobbling outline doesn't deform the eye-center coordinates. Props, box eyes, speech and sleep letters are drawn after restoring the identity transform, so don't inherit body squash/tilt. Eyes have minimum vertical radius2 even asleep. Alpha handwritten **text** uses images, but the character itself remains procedural.

“Smooth animation” needs precision: easing/sine formulas are continuous inside phases; gaze updates, state switches, interruptions, RUN's phase scale change and WAKE's eye switch are discrete. Existing tests verify valid/completing poses, not universal visual continuity. There is no sprite rig, skeletal constraint solver, physics jump, velocity/friction system, custom safe-area solution or separate dynamic layout engine. Fixed logical margins and reference scaling are described exactly in pseudocode §9.

### Typography and branch decisions

`c0bfa4e` installed approved actual-game typography: Space Grotesk, title weight600, cached complete Ink Free phrases. Runtime lookup is exact-string based, with stored advance/ascent and size/160 scaling; unknown strings fall back to Space Grotesk. Ten phrases include one marketing-only phrase, not an extra reaction. No installed Windows font is needed during play, and no proprietary Ink Free font file/per-glyph atlas is shipped. This is a source-confirmed implementation choice, not a comprehensive legal opinion about all artwork rights.

`c739782` restored fallback-font gameplay development on main while retaining aesthetic history. Because the old font commit is already an ancestor, normal merging doesn't reapply reverted presentation. The release helper applies a reviewed three-way patch using fixed base `5be3a20`, not moving main; otherwise later gameplay could enter the inverse patch. A temporary Git index detects conflicts before touching real files. Tests simulate later gameplay/version edits and overlapping font edits.

New releases start from current main, integrate only approved presentation, validate, freeze words/gameplay and explicitly finalize artwork once. Reuse cached phrases unless wording/treatment changes. Do not replace the whole script from an old aesthetic tree or merge a finished release wholesale into main. This documentation task ran no generators and touched no approved artwork.

### Platform-specific behavior

**Windows:** native mouse path shares touchscreen logic. Preview432×768/reference720×1280. Alpha unsigned x86_64 output embeds project data. Recorded120-frame exported-executable headless smoke detects startup/runtime failure, not complete graphical compatibility. Public Windows download verification compared unpacked file bytes because itch can reconstruct ZIP containers.

**Android:** native pressed screen touch, duplicate emulation off, portrait ARM64. Alpha0.1.0-alpha/code2 differs from old1.0/code1 reports. Debug APK is testing only; release-mode AAB is unsigned and needs authorized signing. Recorded minSDK24/target36/alignment belong to the specified artifact. No runtime network permission. No separate Android gameplay implementation or per-finger lock.

**Web:** Alpha adds single-thread export, canvas resize policy2 and initial canvas focus, no PWA. Release handoff requires HTTP(S), WebAssembly and WebGL2. Godot4.7 startup handling is browser test tooling, not gameplay. Recorded desktop/mobile-sized browser checks use desktop Chromium/software WebGL, not a physical mobile browser. Host/browser focus/fullscreen/resize behavior isn't exhaustively certified by the shared application-focus handler.

**Linux/macOS:** cross-export structure/package checks exist; native runtime unverified on the Windows host. macOS Universal is unsigned/not notarized. No native-compatibility claim follows from source visibility or a structurally valid ZIP.

**iOS:** intended shared GDScript/portrait implementation, but no actual Team ID/provisioning/archive/device validation in Alpha. Windows template files aren't Xcode/SDKs. The older `release/IOS_EXPORT.md` has1.0 examples: use the versioned release catalog, not those old values, for an Alpha operation. Native Mac/Xcode/signing and validation remain prerequisites.

**Shared resize/focus:** changed logical size cancels reaction and recenters without resetting annoyance/sleep/history. Focus loss stops automatic processing, not direct helper calls or an explicit input flag. No wall-clock catch-up/save-resume/safe-area query. Four ordinary logical layouts are numerically covered; arbitrary tiny, landscape and notched displays aren't certified.

### Testing and validation

These are **historical results**, not reruns made to write this document. Test source was inspected to distinguish assertions from claims.

| Evidence | Recorded result | What it means / limitations |
| --- | --- | --- |
| Alpha `behavior.gd` |320,270 checks passed | Tier boundaries/250 sampled selections per boundary,16 lifecycles, polygon vertices/bounds, box eyes/shield, spam/protected escape,1000 hits, sleep/wake/input/resize. Many checks repeat vertex assertions, not320,270 unique scenarios. |
| Alpha `release.gd` |237,076 passed | Four actual logical SubViewport sizes, dispatched input,41 pose samples/reaction, direct16×16 helper transitions, focus flags, thresholds,3×6000-frame seeded sessions. Not device evidence. |
| `fingerprints.gd` |17 passed | LF/CRLF equivalence, real source/binary changes/missing/unknown modes rejected. Hashes identify content, not visual quality. |
| Alpha `typography.gd` |127 passed | Font/weight, phrase coverage, transparency/metrics/width, title fit, no Ink Free font file. Absent intentionally on main. |
| Alpha package |205 passed | Metadata limits, captured-source fingerprints, images/formats, exclusions/notices/configuration. Earlier main179/aesthetic196 are different snapshots. |
| Python distribution |14 tests passed | Free-policy/catalog/path/version, export tampering/reuse, notices, executable ZIP bits, stale validation and unavailable outputs. Fixture checks, not fresh exports. |
| Branch workflow |19 assertions passed | Isolated local clone: clean-branch guards, preservation of later gameplay/version, conflict preflight, no capture replacement. |
| Render suite |18 states +4 aspects historically | Contact sheets sample one pose/reaction plus idle/sleep, not full motion videos. |
| Alpha Windows/Web |120-frame Windows smoke; browser432×768 and390×844 startup/click/touch/resize, no recorded runtime errors | Desktop automated export/browser evidence, not physical phone performance. |
| Earlier Android9 BlueStacks |Then-existing1.0 APK at900×1600 and720×1280 portrait profiles | Pre-Alpha evidence; no claim Alpha APK was device-tested. No newer Android/16 KB runtime/physical/iOS evidence. |
| Publication |Public hosted startup + Windows download content match | Recorded availability then, not exhaustive compatibility or current hosting recertification. |

Retained historical failures/corrections: stale sleeping state initially contaminated an escape-spam test; isolating `asleep`/`idle_time` resolved setup. Windows newline differences caused false capture hashes; text-only normalization preserved actual-change detection. Three-way `--check` could predict conflict without failing; temporary index fixed preflight. Android Gradle shutdown/daemon issues were recorded as tooling evidence; warnings weren't called device testing. Initial itch push failed on email verification; subsequent owner verification permitted uploads.

For future implementation run the normal import/behavior/release/fingerprint checks in `BRANCH_WORKFLOW.md`, check exits and script error output, add visual/device evidence when required. Rendering is optional for pose/layout investigation; marketing generators run only at freeze. Jitter work needs uninterrupted multi-cycle visual evidence because current suites don't measure temporal eye smoothness. This documentation pass's own static verification is in the source audit.

### Distribution and release operations

Editable source of release information is `release/catalog/game.json`: Alpha0.1.0-alpha, native0.1.0, Windows0.1.0.0, Android code2, stable application ID `com.littlebutterflyproductions.donttouchme`, WANDIEL brand and recorded legal publisher. Owner still confirms rights, audience, account status and actual declarations. Listing views are generated, not independent metadata authorities. Main may hold a catalog referring to aesthetic resources not installed yet. Don't run sync on this documentation branch: it changes project/export settings and is release-only.

`release/tools/release.py` validates catalog, synchronizes metadata, checks tools, validates engine/source/captures, finalizes assets, exports clean source, packages/reuses formats and writes manifests/checksums/reports. Cache keys include runtime/config/engine/template fingerprints and byte-verified output. Shared metadata/notices can need repackaging without engine export. A file alone isn't a successful export; exits/logged runtime errors remain failures. Outputs/receipts live ignored under `builds/v<version>/` and aren't guaranteed present on every checkout.

Prepared formats are Windows, Web, debug Android APK, unsigned AAB, Linux and macOS; iOS explicitly unavailable. Platform checklists reuse compatible artifacts. A25-platform registry means preparation records, not25 live publications. Portal integrations, production signing/review and native testing remain separate. F-Droid is blocked by the original code/art lacking a FOSS license; public code visibility isn't a license grant.

Only Windows and HTML5 are recorded public on itch, project5273390; windows/html5 upload IDs20184231/20184236 and completed builds2263119/2263122. Existing bytes were reused. Old “prepared, not published” reports describe their original time. Butler status doesn't prove visibility; hidden upload flags don't hide an existing public page. Draft uploads required actual-page confirmation, and the later adapter refuses pushes to the recorded published listing. Future updates need their own version/validation/publication authority. Public devlogs similarly require approval.

Pages support/privacy were published from main `/docs` earlier. The later publication record explicitly notes hosted policy still says1.0/October29 and lacks Alpha web-host context; itch disclosed this and linked host privacy. Don't claim that hosted policy was updated here. Separate website deployment is outside this game task; source pushes aren't authorization for DNS/accounts/payments/submission.

Signing remains owner-controlled outside Git. `.gitignore` excludes builds/imports/export credentials, key formats/profiles and APK/AAB/IPA/PCK. Debug signing isn't production identity. `release/PRODUCTION_SIGNING.md` describes key generation, separate password storage, independent encrypted backups and verification; no production key was created here. Aesthetic builds include engine notices and Space Grotesk OFL. Engine notices do not license the original game.

### Recorded decisions and unknown motivations

| Decision | Verifiable reason/evidence | Trade-off or unknown |
| --- | --- | --- |
| Single clock/derived pose | blob top comment explicitly avoids asynchronous reactions/overlapping tweens | Prevents conflicts; doesn't blend interruptions. No archived tween prototype comparison. |
| BOX/RUN protection | touch handler comment says escapes must finish under frantic tapping | Hits can still add annoyance/flash; no restart. |
| Shared silhouette/flaps | `46eeff3` adds shielding/peek-eye checks and shared flap polygons | Not antialiased-pixel-perfect. |
| Procedural minimalist character | Initial implementation meets small comedy/asset constraints | Per-draw polygons/styles allocated; no ordinary-phone profiling record. |
| Whole-phrase handwriting | `c0bfa4e`, runtime/authoring comments: complete images, no proprietary font shipped | New dialogue needs coverage/finalization; runtime fallback remains. |
| Basic main/styled release | `c739782`, workflow instructions separate quick gameplay iteration from artwork generation | Development preview differs from public presentation. |
| Fixed integration base/temp index | workflow report and paired fixes preserve future edits/reject overlap | Conflict requires review, not whole-file replacement. |
| Portable text hashes | inventory/source-fingerprint changes normalize only equivalent newlines | Actual content/binary changes still fail; historical manifests retained. |
| Separate Alpha/engine versions | `9788e03` sets game0.1.0-alpha, engine remains4.7.2 | Old1.0 docs aren't Alpha release settings. |
| Free/no payments | Catalog/tests/publication record enforce this release policy | Future cosmetics are an idea, not implemented monetization. |
| Exact tuning constants | Source proves every value, including7–10,24 seconds and155 movement | No preserved experiment/rationale explains each choice. Don't invent playtest psychology or rejected alternatives. |

### Change-by-change history and milestones

**2026-10-29 — first playable (`9307c4b`).** One scene/controller implements15 reactions plus wake, hidden annoyance, procedural body/props, input, idle breathing/blinks, portrait layout and exports. No earlier in-repository prototype exists to compare. The single-clock architecture is already present; motivations beyond source comments and committed goals aren't recoverable.

**2026-10-29 — Android/import and correctness (`ca4c5d8`, `46eeff3`).** Enabled Android texture imports. Covered cardboard previously counted as body: added shielding and clickable visible peek eyes. Shared `_box_flaps` between hit/render geometry; themed launcher uses blob art. Broader validation retained exactly16 reactions. Source diff verifies actual before/after, not just commit title.

**2026-10-29 — package/policy/audit (`ecdb9bb`, `b301c9e`, `a6bacc4`, `58523bb`).** Built release graphics/listings/privacy/rating drafts/notices/checklists/signing guidance. Published Pages, reinspected old1.0 Android packages, recorded two-profile Android9 emulator pass and no physical/iOS claims. Fixed portable inventory hashing; concurrent distribution/business docs merged normally. `f902ddf` later removed public business README. Historical reports aren't rewritten into Alpha results.

**2026-10-30/31 — presentation and integration (`c0bfa4e`…`7ea86fc`).** Approved actual-runtime fonts/phrase images, then basic main restoration `c739782`. `5be3a20` establishes fixed integration base. Main/aesthetic paired tooling fixes add portable validation and temporary-index preflight; overlap regression cases preserve newer gameplay/version. `WORKFLOW_VALIDATION.md` records19 assertions and suites on basic/aesthetic/integrated fixtures. No new mechanics.

**2026-10-31 — Alpha preparation (`a35fb02`, `9788e03`, `d61c865`).** Fresh release from main `7ea86fc`; approved typography applied at `a35fb02`, Alpha version/art frozen at `9788e03`, which is actual export source. Multi-format pipeline added by related release/main commits `78356d9`/`6842e56`; Web/Gradle startup fixes `4713bc1`/`a250b99`; engine/error-evidence fixes `ede5a6c`/`df018a8`. Paired hashes reflect changes on distinct ancestry, not separate game versions. `d61c865` records local artifacts and milestone tag, explicitly before publication. iOS unavailable.

**2026-10-31 — draft uploads and Windows platform correction.** `b8c04e9` adds Butler guards. First push blocked by account email; after owner verification `2d0e3b6` records both completed private channels. `ee0372c` integrates related tooling on main. `0815422` fixes Windows checkbox without duplicate upload; `abfe1eb` records it on main. Private hosted browser startup observed. No Linux/mac upload without native validation.

**2026-10-31 — proposals only (`b9fa56f`, `d79c3b4`, `ed70cc4`, `2c5a708`).** Future audio/expansion roadmap, reported sleep-eye jitter, explicit separation of plans from implementation, preferred hidden-sleep-eye proposal. No sound or hidden sleep eyes implemented. Investigation/visual acceptance still pending.

**2026-10-31 — public release (`6bf3a46`, merge `c2ea4a0`).** Owner authorized public itch visibility. Existing HTML5/Windows packages reused. Public page/browser startup/download checked; downloaded Windows file contents matched original package, while reconstructed ZIP container wasn't assumed byte-identical. Older hosted policy label remained explicitly outstanding. These records live on the release branch, not audited main.

**2026-10-31 — documentation gate (`9c5becb`, `1741ec2`, `8cee57c`).** Journal scaffold/standard, separate Butter Boy public voice, explicit owner-approved pseudocode before meaningful behavior changes. Scaffold was not evidence of comprehensive documentation until populated here. Existing Alpha behavior isn't retroactively a feature proposal.

**2026-10-31 — this documentation branch.** Created complete behavior reference/source audit, populated this journal and clarified required AGENTS sequence. Read pinned Alpha, current main, plans and history; document all controller branches, tests, baseline differences and gaps. Static verification results live in source audit. No gameplay/audio/graphics/configuration/binaries/tags/publication changed. Find resulting commit with `git log -- docs/ALPHA_BEHAVIOR_SPEC.md`; it is a review PR, not a merge/release.

### Known issues and evidence gaps

Only focused plan under `plans/` is [sleep-eye-jitter.md](../plans/sleep-eye-jitter.md): owner observed small eye jumps during sleep/breathing. Preferred proposal hides fully sleeping eyes and restores on wake, keeping body breathing; smooth anchoring is an alternative. Investigation also refers to preserving expression/placement. Resolve those precise choices in owner-approved pseudocode before implementation rather than silently treating conflicting prose as permission. Root cause is unverified. Continuing discrete idle gaze is a source fact, not proof it causes the reported artifact.

Other limits in pseudocode §12: interruption snaps, RUN phase pose switches, tiny-width clamp intervals, no safe-area handling, direct helpers trusting callers, no guaranteed discovery, focus handler changing processing only. These are source-derived limitations/unsupported cases, not all reproduced crashes. No game bug was fixed here.

Missing evidence: why each tuning number was selected, earlier unpublished prototypes, temporal eye-smoothness assertions, Alpha physical/newer-Android/iOS/native-Linux/native-macOS certification, current server/account/legal status. Export/tag identity is corroborated by Git runtime-tree equality and recorded provenance; no new binary/server download or reverse engineering was done in this task. Stronger binary provenance would require separately scoped artifact/PCK verification.

### Planned future behavior

| Item | Status | Priority, dependencies and acceptance |
| --- | --- | --- |
| Sleep-eye stability | Planned, not implemented | Next gameplay patch per plan: reproduce cycles/root cause, approve hide/restore or anchoring pseudocode, visual multi-cycle and regression evidence. |
| Audio personality | Idea/design roadmap; no clips/code | Choose quiet/ambient/music/vocal direction, event-to-sound map, original/licensed clips, buses/mute/focus/browser behavior, then approve. |
| More idle/reactions | Idea | No approved count/timing/target version; preserve16 until approved. |
| Counters/statistics | Idea | No tracking/display/save implementation; design persistence/privacy/UI first. |
| Outfits/furniture/customization | Idea | No inventory/unlock system; art/scope/performance unapproved. |
| Trust/petting from respectful approach | Idea | No trust variable/threshold, slow-motion/hover gesture or progression exists. |
| Cosmetic monetization | Possible idea | Current pipeline free/no payments; store design and new authorization required. |
| Native iOS/broader Android validation | Release prerequisite, incomplete | Tools/signing and actual device evidence, not an implemented mechanic. |
| Hosted policy Alpha/hosting label | Outstanding documentation follow-up | Recorded at publication; not changed under this source-documentation scope. |

Sources: [GAME_ROADMAP.md](../GAME_ROADMAP.md), sleep plan, immutable publication report and release handoff. No invented schedules, approvals or implementation progress.

### Ongoing change protocol

**Proposal → Pseudocode → Owner approval → Implementation → Testing → Journal update → Release preparation.** Proposal records current behavior/problem, intended behavior, edge cases/acceptance and target version. Pseudocode states branches/calculations before code. Explicit owner approval applies to that design, not all future gameplay. Material implementation deviation returns to approval.

Validate implementation against approved specification. Update plan status, English/pseudocode/diagrams, affected function/commit references, tests/limitations and this journal together. Preserve immutable Alpha reference when writing a later version. Prepare a new release through the basic-main/aesthetic/finalization/export gates; never silently rebuild/retag Alpha. Each journal entry records date, player-visible before/after, source, actual rationale/alternatives, approval evidence, validation, commit and release destination. Public devlogs remain separate approved publications.

### Glossary

| Term | Ordinary meaning |
| --- | --- |
| Alpha | Early public playable version, not certification for every device/store. |
| GDScript | Godot language containing game instructions. |
| Scene/node/Node2D | Saved arrangement of game objects; a two-dimensional drawable object. |
| Function/variable/constant | Named instructions; stored changeable value; intended fixed value. |
| Enum/state | Numbered named options; current condition/behavior. |
| Vector/logical canvas | x/y pair; coordinate space mapped to physical screen pixels. |
| Transform/local/world | Position+rotation+scale mapping; relative-to-body versus overall-canvas coordinates. |
| Polygon/silhouette/hit test | Joined points forming shape; body outline; checking allowed input area. |
| Occlusion | Cardboard covers body and blocks its touch area here. |
| Delta/clock/normalized time | Update seconds; accumulated simulation time; progress0…1. |
| Envelope/ease/lerp | Rise/fall multiplier; smoothed progress; numeric blend between positions. |
| Radians/PI/TAU | Angle units; half turn≈3.14159; full turn≈6.28318. |
| Opacity/alpha/antialiasing | Visibility0…1; transparency component; smoothing pixel edges. |
| Raster/mipmap | Pixel image; smaller texture versions for scaled display. |
| Font advance/baseline | Text layout width; reference line positioning letters. |
| Seed/random pool | Start value making test random sequence repeatable; eligible choices. |
| Clamp/threshold | Keep number in limits; boundary deciding a branch. |
| Tween/crossfade | Automatic interpolation object; blend old/new poses. This controller uses neither. |
| Headless/smoke/regression | Without a display; brief startup check; repeatable established-behavior check. |
| Viewport/SubViewport | Drawing/input area; separate area used for logical-layout tests. |
| Commit/branch/tag/PR | Saved snapshot; moving development line; named milestone; review request. |
| Three-way merge/temporary index | Combine using shared history; isolated staging area for preflight conflicts. |
| Fingerprint/SHA-256/LF/CRLF | Content identifier; hash method; Unix/Windows newlines. Text normalizes equivalent endings; images don't. |
| Export/package/artifact/manifest | Platform output conversion; arrange distributable files; result; recorded checksums/metadata. |
| APK/AAB/PCK | Android install package; Play input bundle; Godot packed resources. |
| Signing/provisioning/notarization | Cryptographic identity; Apple team/device authorization; macOS distribution verification. |
| Draft/uploaded/published/verified | Private prep; remote bytes accepted; public availability; evidence for a stated claim/time. Separate milestones. |

Glossary descriptions grant no approval, original-game license, store guarantee or physical-device testing claim.
