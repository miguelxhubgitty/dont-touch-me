# Audio source register — candidate branch, 2026-11-17

These files are now **committed on PR #18**, but still await Godot import, on-device listening, timing review and owner approval. None of the source material is a WALL-E recording. No release was modified.

## Real kitten — exact preferred source included in edited form

Four clipped OGG effects `audio/voice/kitten_lolamadeus_{1..4}.ogg` are redistributed from the open-source [Factorio Catmod](https://github.com/Danielv123/factorioCatmod/tree/main/sound) project. Its [credits](https://github.com/Danielv123/factorioCatmod/blob/main/sound/CREDITS.md) identify these **four individual edits of the exact requested** [Kitten Meowing.wav](https://freesound.org/people/lolamadeus/sounds/196251/) by lolamadeus (CC0 1.0). This is a genuine 6–7-week kitten; the original 8.616-second full-quality WAV has **not** been downloaded. These are derivative OGG clips.

## Real puppy — verified CC0, different sources from the initially requested Puppy (8)

Three short `audio/voice/puppy_real_{1..3}.ogg` recordings are repackaged (not reedited here) from [golden-retriever](https://github.com/vhidvz/golden-retriever/tree/main/renderer/sounds). Its [source register](https://github.com/vhidvz/golden-retriever/blob/main/renderer/sounds/SOURCES.md) identifies them as denoised clips of [Puppy at a night.ogg](https://commons.wikimedia.org/wiki/File:Puppy_at_a_night.ogg), a recording of a crying puppy by Knites, CC0 1.0.

`audio/voice/puppy_chihuahua_whine.wav` is a 16kHz mono conversion/trim redistributed from [bot-reborn](https://github.com/beasaltfish/bot-reborn/blob/main/server/sounds/CREDITS.md). Original: [Chihuahua Puppy Whine](https://freesound.org/people/AustinXYZ/sounds/350593/) by AustinXYZ, CC0 1.0.

The initially requested [Puppy (8) by johnnypanic](https://freesound.org/people/johnnypanic/sounds/728029/) is CC0 but the uncompressed original and preview could not be fetched from available public GitHub assets; its file is **not in this PR**.

## Robot — reusable preexisting effect, not the chosen exact Synth Voice Hello

`audio/voice/robot_fupicat_notification.mp3` is the public high-quality preview of [Notification](https://freesound.org/people/Fupicat/sounds/538149/) by Fupicat, CC0 1.0, mirrored with [source notes and SHA-256](https://github.com/rullerzhou-afk/clawd-on-desk/blob/main/assets/source/freesound-538149/README.md). It is an existing game notification-style synth; **do not mislabel it as a robot voice**. It is temporarily used as a robotic accent.

`audio/voice/robot_servo_mit.wav` is a preexisting synthesized servo by CureJe under MIT; original project [asset register](https://github.com/CureJe/sedentary-reminder/blob/main/assets/audio/README.md) and [license](https://github.com/CureJe/sedentary-reminder/blob/main/LICENSE). Retain the license notice below.

The original selected [Synth Voice Hello](https://freesound.org/people/Fupicat/sounds/538153/) by Fupicat is CC0 but requires a Freesound login to download. **It is not in this PR**.

## Other committed asset files

- `audio/voice/cat_meow_cc0.wav`: real adult cat meow originally by freemaster2, CC0, [source](https://commons.wikimedia.org/wiki/File:Meow_of_a_Siamese_cat_-_freemaster2.wav), repackaged via [CureJe](https://github.com/CureJe/sedentary-reminder/blob/main/assets/audio/README.md); no longer used by events, kept for possible audition.
- `audio/voice/dog_whimper_cc0.mp3`: real small-dog whimper, Freesound [kyles 452202](https://freesound.org/people/kyles/sounds/452202/), CC0 as documented in the [source set](https://github.com/vighriday/stay-for-dogs/blob/main/public/test-audio/SOURCES.md); no longer used by events.
- `audio/candidate_sfx/**/*.wav`: 14 **generated**, mono PCM 16-bit at 22,050 Hz; individually replaceable event sounds, not field recordings. The copies in this PR were independently regenerated after the separate earlier ZIP; don't assume hashes match the ZIP.

## Zapsplat sources — research only, not downloaded

The preferred [Closing cardboard box](https://www.zapsplat.com/music/closing-cardboard-box/) sample is labeled CC0 1.0, but its original download requires the signed-in website. It is **not** in this PR; generated box foley remains mapped as temporary candidate audio.

## MIT notice — CureJe robot source

MIT License

Copyright (c) 2026 CureJe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
