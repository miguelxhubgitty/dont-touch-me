# Stage 4 Android Privacy Policy restoration

Status: approved for implementation and testing. Based on `origin/main` at `e76ab1f`.

## Historical and current behavior

The code-3 preparation commit `a10dba8` adds a `PrivacyHUD` canvas layer and a flat `Privacy Policy` button. The bottom-right footprint is 200 × 58 logical units, with a 24-unit margin, 22-unit Space Grotesk type and dark text. Its native screen touch opens the URL on press and accepts the event. The normal Button activation also opens the URL. Both touch-to-mouse and mouse-to-touch emulation are disabled in current development. The blob listens in `_unhandled_input`, so the button can prevent pokes and misses in its own GUI handler.

## Proposed port

- Restore the historical layer, label, dimensions, style, offsets and activation timing in the existing main scene. Use the development font on basic-font main and the historical Space Grotesk resource when the approved typography layer supplies it.
- Keep the HUD hidden outside Android. Keep the control responsible only for its own rectangle and input. Use Godot's safe rectangle to shift it inward on screens where the original margins would overlap system UI. Preserve the normal 24-unit margins in the available area.
- Leave orientation, audio HUD, gameplay input, project/export settings and release history untouched. Use the existing URL and Godot's OS browser handoff.

```text
ready:
    hide the HUD outside Android
    on Android, connect normal Button activation to open_policy
    position the button and refresh when viewport geometry changes or focus returns

position:
    intersect Android's usable display rectangle with the game window
    convert the resulting physical rectangle to HUD coordinates using
        the viewport transform, including screen/window origin once
    when the platform reports no usable rectangle, use the visible viewport
    anchor inside that rectangle at the original lower-right margins

GUI input:
    accept native touch presses, releases and drags delivered to this button
    consume emulated pointer events before Button can activate
    on a non-canceled touch press, open_policy once

open_policy:
    ask the OS to open the known privacy URL
    log a warning if the platform rejects the handoff
```

## Acceptance checks

- Run a focused Godot test with the real main scene. Assert that the control is hidden in a normal desktop run and that the platform gate excludes iOS. Exercise the Android GUI path with synthetic touch in the local harness and replace only the browser launch in that test. Assert one request per tap and no change in annoyance, reaction, inactivity, click tracking or audio trace. Verify that a touch immediately outside still reaches gameplay.
- Test original placement without insets, then synthetic bottom/right and asymmetric safe rectangles with portrait, wide and landscape viewport sizes. Include viewport scaling, translation within the window, and nonzero window positions. Keep the authored orientation unchanged. Check that opening and closing the existing volume panel still works.
- Run relevant gameplay and audio checks. Verify the HTTP policy page. Where a test device is available, check native Android visibility, system navigation/cutouts, browser open, and return to the game. A synthetic layout or browser stub only verifies the local code path.
