# Playable audio candidate source register — November 17, 2026

**Review build only.** There are no sounds from the WALL-E franchise. The old noncommercial alligator file remains in the repository's history but no longer appears in the live audio event map on this branch. Do not export or publish until the obsolete asset is excluded from builds and all tests/owner listening pass.

| Repo candidate | Content | License | Original source and provenance |
|---|---|---|---|
| `audio/voice/cat_meow_cc0.wav` | Actual *cat* meow (not verified kitten) | CC0 1.0 | freemaster2, "Meow of a Siamese cat - freemaster2.wav", https://commons.wikimedia.org/wiki/File:Meow_of_a_Siamese_cat_-_freemaster2.wav ; pretrimmed/preprocessed in https://github.com/CureJe/sedentary-reminder/blob/main/assets/audio/cat.wav |
| `audio/voice/dog_whimper_cc0.mp3` | Small-dog whimper + movement (not verified puppy) | CC0 1.0 | kyles, https://freesound.org/people/kyles/sounds/452202/ ; redistributed MP3 in https://github.com/vighriday/stay-for-dogs/blob/main/public/test-audio/dog/452202-dog-small-whimper-run-flac.mp3 |
| `audio/voice/robot_servo_mit.wav` | Nonverbal servo startup (not a WALL-E sample or direct voice imitation) | MIT | original by CureJe, https://github.com/CureJe/sedentary-reminder/blob/main/assets/audio/mech.wav ; preserve the MIT notice below |
| `audio/candidate_sfx/**/*.wav` | 14 short synthesized UI/body/prop sounds | Original, created for this project | Independently regenerated from the earlier ChatGPT starter pack's algorithms; these are **not byte-identical** to that separate ZIP and should be auditioned independently. Mono PCM 16-bit, 22,050 Hz, target peak approximately -13 dBFS |

## Requested specific kitten/puppy/robot replacements (not yet downloaded)
- lolamadeus, "Kitten Meowing.wav", CC0, https://freesound.org/people/lolamadeus/sounds/196251/
- johnnypanic, "Puppy (8)", CC0, https://freesound.org/people/johnnypanic/sounds/728029/
- Fupicat, "Synth Voice Hello", CC0, https://freesound.org/people/Fupicat/sounds/538153/

Those Freesound sound pages are public, but the original download requires a logged-in account. Use the user's newly created login to download, then replace the three provisional `audio/voice/` files and event paths individually on a later review branch. Never share passwords.

## MIT notice for robot source

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
