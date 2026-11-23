# SkyrimVR-VRFreeCam-DD

Third-person VR free camera for the **player** while locked in a **Devious Devices NG** contraption
(pillory, X-cross, poles, chairs and other devices that use DD NG's `zadcFurnitureScript`).
**Skyrim VR only.** NPCs are not touched. 18+ (Devious Devices is an adult framework from LoversLab).

> **Read this first.** The two scripts in this release are the helper/API side of the patch.
> They do **not** change Devious Devices on their own. The actual hook is a modified copy of
> DD NG's own `zadcFurnitureScript`, which belongs to the DD NG team and is **not** redistributed
> here. The code we added to it is in the repo's [`reference/`](https://github.com/JezebelGraves/SkyrimVR-VRFreeCam-DD/tree/main/reference) folder
> (not in the release zip) so you can merge it into your
> own copy of the DD NG 0.4.2 source and compile it yourself. Without that merged script, installing
> this mod only gives you the console commands below (most of them will report "not locked").

## What it does (with the merged `zadcFurnitureScript`)
Based on the scripts in this repo and the `reference/` code:
- Pins your VRIK body on the device at the device's position and facing (VRIK `lockPosition=2`)
  and turns your character into the camera, held on a viewpoint looking at you. No `SetVehicle`
  and no `tfc` on the player. "Next view" moves the camera to another side of the device.
- Plays the DD pose idle on your body directly and re-sends it every few seconds (keep-alive),
  because DD poses are AI packages, which stop animating the VR player once the camera is free.
  The pose idle is read from DD's pose package with powerofthree's Papyrus Extender.
- Picks a calm (non-struggle) pose for you; DD struggle animations can be turned off.
- Blocks VRIK arms, body IK and posture and HIGGS hands while locked, and re-applies the block if
  something resets it.
- Also listens for the mapped Activate keys, since VR controllers don't always raise DD's Activate
  control event.
- Gives the camera back during a SexLab scene started by the device and takes it again afterwards.
- Release runs DD's own unlock first, then restores camera, VRIK, hands and controls.
- If **ZaZ VR Lock** (the separate `x812zl` patch) is installed, its core holds you instead of the
  built-in fallback. Without it, the plain `VRFreeCam` fallback is used.

## Contents

| Path | What |
| --- | --- |
| `Scripts/x812dd.pex`, `Source/Scripts/x812dd.psc` | DD VR helpers and the console / mod API |
| `Scripts/VRFreeCam.pex`, `Source/Scripts/VRFreeCam.psc` | Shared VR free-camera core. Byte-identical to the copy in the other VRFreeCam patches, so an MO2 conflict on this file is harmless. |
| `reference/DDVR_added_block.psc` | The functions and variables we appended to the end of `zadcFurnitureScript`. Not a complete script. |
| `reference/HOOKS.md` | The small call sites we added inside DD's own functions (our lines only). |

## Requirements
- Skyrim VR with **SKSEVR**: https://skse.silverlock.org/
- **VRIK Player Avatar**: https://www.nexusmods.com/skyrimspecialedition/mods/23416
- **PapyrusUtil** (VR build): https://www.nexusmods.com/skyrimspecialedition/mods/13048
- **powerofthree's Papyrus Extender** (VR build): https://www.nexusmods.com/skyrimspecialedition/mods/58296
- **HIGGS**: https://www.nexusmods.com/skyrimspecialedition/mods/43930 (`x812dd` calls `HiggsVR` directly)
- **Devious Devices NG 0.4.2** and its requirement **Devious Devices SE 5.2**:
  https://www.loverslab.com/files/file/29779-devious-devices-ng/
  The reference code was written against NG 0.4.2's `zadcFurnitureScript`; for another NG version,
  merge it into that version's source instead.
- Optional: **ZaZ VR Lock** (`x812zl` scripts, API version 2 or newer).

## Install (MO2)
1. Install the release zip `SkyrimVR-VRFreeCam-DD.zip` as a mod in MO2 (scripts only, no plugin).
2. Merge the repo's `reference/DDVR_added_block.psc` and `reference/HOOKS.md` into your own copy of DD NG 0.4.2's
   `zadcFurnitureScript.psc`, compile it (Caprica or the Creation Kit compiler, with DD NG, SKSEVR,
   PapyrusUtil, VRIK, HIGGS and Papyrus Extender sources on the import path), and put the resulting
   `zadcFurnitureScript.pex` in a separate local mod of your own.
3. Place both mods **below** Devious Devices NG in the left pane so they win the conflict.
4. Untick any older DD VR contraption patch that also ships `zadcFurnitureScript`.
5. Get out of any contraption, then fully restart the game.

## Uninstall
Get out of any contraption first (or run `cgf "x812dd.Release"`), save, quit, then untick or remove
this mod and your merged `zadcFurnitureScript` mod in MO2. There is no plugin, so the load order is
not affected. If the camera or VRIK is ever left in a bad state, run `cgf "x812dd.Panic"` or
`cgf "VRFreeCam.PanicReset"` before removing the mod.

## Console
```
cgf "x812dd.Release"            release (DD's unlock + full restore); mod API: x812dd.Release(reason)
cgf "x812dd.NextView"           camera to the next side of the device
cgf "x812dd.SetStruggle" 0      no DD struggle animations on your body (1 = on, default)
cgf "x812dd.SetKeepAlive" 6.0   seconds between pose keep-alive re-sends (default 6)
cgf "x812dd.UseCore" 0          ignore ZaZ VR Lock even if installed (1 = use it, default)
cgf "x812dd.Panic"              emergency reset of camera / VRIK / controls
cgf "VRFreeCam.PanicReset"      drop every pin / lock / override and give your character back
```
Mod API: `x812dd.Release(reason)`, `x812dd.IsLocked()`, `x812dd.GetDevice()`.

## Known limits
- VR only. Not for Skyrim SE/AE flat.
- Player only.
- The camera is held on fixed viewpoints around the device; you can't walk it around.
- Does nothing without the merged `zadcFurnitureScript` (see above).
- Tied to DD NG 0.4.2's script; other NG versions need the reference merged into their own source.
- This release's `x812dd.pex` was recompiled with one change from the author's own build: ZaZ VR Lock
  is now detected through `x812zl.Core()` instead of by plugin file name. That build has not yet been
  tested in a headset. Without ZaZ VR Lock installed, Papyrus logs a harmless "script x812zl not
  found" style error when this check runs.
- The `VRFreeCam.psc` header mentions a `VRFreeCamDD` script; in this patch that role is played by `x812dd`.
- Used on the author's own setup; not broadly tested.

## Reporting problems
Turn on Papyrus logging (`SkyrimVR.ini`, `[Papyrus]` `bEnableLogging=1`, `bEnableTrace=1`).
Our log lines start with `DDVR:` (and `x812zl:` when ZaZ VR Lock is used).

## Credits
- Free-camera method follows SexLab VR's third-person mode and OStim VR's VRIK pinning.
- Devious Devices NG / SE by their authors (Kimy, zarantha and the NG team). All credit for DD goes to them;
  respect their permissions for your merged copy of their script.
- VRIK by prog; HIGGS by FlyingParticle; powerofthree's Papyrus Extender by powerofthree; PapyrusUtil by its authors;
  SKSEVR by the SKSE team.
- Patch scripts: Jezebel Graves (with AI assistants).

## License
Our patch scripts and reference code are under the [MIT License](LICENSE) (Copyright (c) 2026 Jezebel Graves).
This does not cover Devious Devices or any other mod: your merged copy of DD NG's `zadcFurnitureScript`
stays under the DD NG team's own terms.
