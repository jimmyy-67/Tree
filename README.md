# Tree?

Pine tree rendered as vector assets inside a retro terminal frame, with ten
switchable wind animations.

Everything on screen is generated from code. There are no images, fonts or
audio files to license: the tree is grown procedurally from a whorl
description, drawn as tapered polygons and strokes, and deformed every frame by
a cantilever wind model. The only dependency is Godot, which is MIT licensed.

## Controls

| Key | Action |
| --- | --- |
| `1`-`9`, `0` | Pick a wind variant |
| `N` | Next variant |
| `A` | Toggle auto cycling |
| `S` | Playback speed: quarter, normal, frozen |
| `D` | Debug overlay |
| `Q` / `Esc` | Quit |
| any other key | Grow a new tree |

## How the motion works

The wind is not a looped pose. The trunk curves like an elastic beam, lateral
offset growing with the square of the height, so the base stays put and the
crown bends. Each branch adds a rotation proportional to its own length, so long
low branches whip while the spire barely moves. A perpendicular component
foreshortens the branch instead of swinging it, which is how motion in depth
shows up in a flat projection. Each grass blade samples the wind at its own
height for the same reason.

Every variant is built only from integer harmonics of the loop phase, so frame
30 lands exactly on frame 0. Switching variants never pops: both are evaluated
and blended over 0.45 s, applied to the evaluated deformation rather than to the
parameters.

## Requirements

Godot 4.7 or newer.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).

Copyright (c) 2026 Jimmyyy_
