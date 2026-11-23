# Don't Touch Me — Current state

Development baseline: Godot 4.7.2 stable on `main`, with the four-animation milestone integrated through [PR #33](https://github.com/miguelxhubgitty/dont-touch-me/pull/33). Use [the workflow](BRANCH_WORKFLOW.md) and [local checks](TESTING.md#development-test-runner) for new work.

## Implemented on main

- Mouse and native touch share the blob's hit rules. Accepted pokes roll +1.8–3.6 annoyance points before the gameplay streak multiplier. Blocked cardboard subtracts 1.8–3.6 and a background tap subtracts 0.9–1.8. Annoyance stays between 0 and 100. A streak expires 1.8 seconds after its first accepted poke or after 1.8 seconds without one. Four reaction pools avoid immediate repeats when selecting a new reaction. After three seconds, annoyance decays at 0.9 points per second for each second past the grace period, integrated over elapsed gameplay time.
- There are 17 regular reactions and one special wake reaction. Box cardboard and flaps block touches, peek eyes accept them, and BOX and RUN retain their protected timing. JUMP has ballistic flight, offscreen landing and return. Idle breathing, gaze, blinking, sleep and wake remain active. Sleep starts after 18 seconds of inactivity once the blob is free to sleep.
- The [Stage 2 scheduler](plans/idle-stage-2.md) uses stage thresholds at 3, 9, 12 and 18 seconds. It waits for active idles to finish before applying the latest stage. Existing Stretch and Humming retain their voice cues. Yawn, Microsleep, Fighting Sleep and Sleep Twitch are silent.
- [Stage 3 animation polish](plans/animation-polish-stage-3.md) smooths the coverage of the closed eyes while the blob sleeps. An accepted poke during Yawn triggers the reaction immediately and plays a 0.18-second startled blink on the face. The mouth closes during the first 0.036 seconds.
- Recoil is a 0.9-second reaction in the lowest annoyance tier. Near an edge it travels less without reversing. Puffer-huff is a 1.35-second reaction in the second tier. The inflated body accepts pokes and the attached spikes are visual only. Both support the authored renderer and procedural fallback.
- The normal scene uses a textured body and authored Godot AnimationPlayer poses with a procedural fallback. The existing controller owns timing, movement, props, speech and input. Development uses Godot's basic font.
- [PR #18](https://github.com/miguelxhubgitty/dont-touch-me/pull/18) integrated kitten, puppy, robot and interaction cues. The [event map](audio/blob_events.json) defines cue timing and enabled states, and the [source register](audio/candidate_pack/SOURCE_REGISTRY.md) records provenance and notices. Background misses have a sound, and blocked cardboard remains silent. Sound defaults to off on a fresh profile, stops playback immediately, and remembers the player's choice.
- PRs #21–#27 added click attenuation, interruption fades, voice gain balancing, an editor-only audition scene, SHAKE voice timing, variation on eligible poke sounds, and saved volumes for User SFX, Character Voice, Character SFX, Environment and Music. The Environment and Music controls have buses available for future content. PR #29 shortened the click streak reset to 0.45 seconds. Gains remain normal for clicks 1–4, then decrease by 6 dB per click to −30 dB from click 9 onward.

## Review queue and next work

GitHub snapshot, November 18, 2026. Recheck live PR status before acting.

| PR | State and scope |
| --- | --- |
| [#20](https://github.com/miguelxhubgitty/dont-touch-me/pull/20) | Draft sound-polish candidates. Separate from the merged audio starter pack. |
| [#10](https://github.com/miguelxhubgitty/dont-touch-me/pull/10) | Draft test teardown improvement. |
| [#4](https://github.com/miguelxhubgitty/dont-touch-me/pull/4) | Draft historical audio-first roadmap. Use this file and the current roadmap for present scope. |
| [#13](https://github.com/miguelxhubgitty/dont-touch-me/pull/13), [#15](https://github.com/miguelxhubgitty/dont-touch-me/pull/15), [#16](https://github.com/miguelxhubgitty/dont-touch-me/pull/16) | Separate draft publisher identity, future Android identity, and Amazon documentation work. |

The global Codex instructions carry the multiples-of-nine preference for flexible design values. Existing specifications, measurements, IDs and engine versions take precedence. Merged PR #28 established the repository copy.

Stretch ([#31](https://github.com/miguelxhubgitty/dont-touch-me/pull/31)), Humming ([#34](https://github.com/miguelxhubgitty/dont-touch-me/pull/34)), Recoil ([#32](https://github.com/miguelxhubgitty/dont-touch-me/pull/32)) and Puffer-huff ([#33](https://github.com/miguelxhubgitty/dont-touch-me/pull/33)) complete the animation milestone. Their cues landed in [#38](https://github.com/miguelxhubgitty/dont-touch-me/pull/38). Recognizable-song ideas, emotional stages beyond inactivity, trust and auras are deferred.

## Evidence and release boundary

- iOS shows the in-app Privacy Policy button, reusing the Android implementation ([plan](plans/ios-privacy-policy.md)). Android behavior is unchanged. **Known issue, to fix before release without unnecessarily changing Android:** a second-finger press before the first is released opens the policy twice, on both platforms. A native iPhone tap, Safari handoff and VoiceOver still need checking.
- The production **iOS** export preset uses the registered App Store bundle ID `com.littlebutterflyproductions.donttouchme`, minimum iOS 15.0 and the preview's orientation feature. It sits beside the unchanged development **iOS Orientation Preview** preset (`.orientationpreview`, iOS 14.0). Both presets use the transparent launch image and show the Privacy Policy button. The version/build, release presentation (Windows finalization pass), Distribution signing and a physical-iPhone test of the production build are still pending owner decisions. See [release/IOS_EXPORT.md](release/IOS_EXPORT.md).
- [Android identity reconciliation](release/ANDROID_IDENTITY.md) targets the existing WANDIEL Play app. Version code 4 is provisional until Play Console's upload history is checked. The published-line privacy control needs a separate approved port before an update can ship.
- [Stage 4 audio export hygiene](plans/stage-4-audio-export-hygiene.md) is in review. It preserves the current enabled cues and adds an approved-stream manifest, a generated MIT notice and export/receipt checks.
- Rapid automated audio shutdown has intermittently reported outstanding playback resources. A normal WASAPI window close after a tap exited cleanly in a prior check, which does not rule out every active-audio shutdown case. Compare exact conditions before labeling a warning harmless.
- The iPhone launch screen shows the plain game background instead of Godot's logo. Every iOS preset must point both storyboard image slots at `release/ios/launch-transparent.png` ([plan](plans/ios-launch-screen.md)).
- On the Intel Mac (AMD Radeon Pro 5500M, OpenGL 4.1), `tests/animation_sleep_eye_render.gd` fails "Sleep Twitch animates through its full duration" for the 288 px authored case, so `tests/run.ps1 -Mode full` stops there. It also fails on the unmodified source. Investigate it separately; the test stays as written.
- Desktop and synthetic viewport tests cover the development tree. Physical Android/iOS touch timing, audio latency, focus/background behavior and device performance still need direct testing. Browser autoplay and mobile audio also need real-browser checks against a separately approved web build.
- The published **v0.1.0-alpha** uses its frozen, audio-free runtime. Its 24-second sleep threshold, procedural presentation and approved release typography belong to that historical source. Use the [release manifest](release/distribution/manifest-v0.1.0-alpha.json) for provenance and the [distribution registry](release/distribution/platforms.json) for recorded destination status. A merged development PR does not update a public package.
- The [journal](docs/INTERNAL_DEVELOPER_JOURNAL.md) preserves historical results and decision context. The permanent foundation branch is a separate read-only historical reference for this workflow.
