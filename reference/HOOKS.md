# DDVR call sites inside zadcFurnitureScript

These are the lines we added inside Devious Devices NG 0.4.2's own `zadcFurnitureScript` functions. Only our lines are shown; DD's code is not reproduced. Apply them to your own copy of the DD NG 0.4.2 source, add `DDVR_added_block.psc` at the end of the script, and compile with the DD NG, PapyrusUtil, VRIK, HIGGS, PO3 Papyrus Extender and SKSEVR script sources on the import path.

"Replaces" means DD's original line(s) at that spot are removed and our lines go in their place.

## Function PickRandomPose: Add

```papyrus
	; DDVR: the player gets a calm pose (no "struggl" idle) and, while held, the body is switched to it at once
	; (the minigame calls this on key release, the sex-scene end too).
	If user && user == libs.PlayerRef
		Package calm = x812dd.PickCalmPose(BoundPose)
		If calm
			CurrentPose = calm
		EndIf
		If VRHeld
			VRSetLoop(x812dd.IdleEvent(CurrentPose))
		EndIf
	EndIf
```

## Function PickRandomStruggle: Replaces 1 DD line(s)

```papyrus
	Package p = StrugglePose[Utility.RandomInt(0, StrugglePose.Length - 1)]
	; DDVR: packages don't animate the player under the free cam -> play the struggle idle on the body directly
	; (the minigame calls this on key press; key release calls PickRandomPose, which switches back).
	If VRHeld && !VRSceneStruggle && user == libs.PlayerRef && x812dd.StruggleOn()
		VRPlay(x812dd.IdleEvent(p), 30.0)
	EndIf
	Return p
```

## Function LockActor: Add

```papyrus
		VRBegin()	; DDVR: snapshot before DD changes anything on the player
```

## Function LockActor: Add

```papyrus
			CurrentPose = Pose	; DDVR: remember it (the keep-alive needs the pose's idle)
```

## Function LockActor: Replaces 1 DD line(s)

```papyrus
	; DDVR: the pose's device AnimObject does not render on the VR player -> keep the real device visible for her
	If act != libs.PlayerRef
		self.disable()
	EndIf
```

## Function LockActor: Add

```papyrus
		; DDVR: VR controllers don't always raise the Activate control event -> also the mapped Activate keys
		VRRegisterActivateKeys()
```

## Function LockActor: Replaces 2 DD line(s)

```papyrus
		; DDVR: no ForceThirdPerson / SetCameraTarget in VR (the free cam below replaces them)
```

## Function LockActor: Add

```papyrus
	If act == libs.PlayerRef
		user.StopTranslation()	; DDVR fix1: AntiCL's endless TranslateTo drags the VR camera body back onto the device
	EndIf
```

## Function LockActor: Add

```papyrus
	If act == libs.PlayerRef
		VRLock()	; DDVR: last, so nothing after it re-freezes the player
	EndIf
```

## Function UnlockActor: Add

```papyrus
	Bool vrWasHeld = VRHeld && user == libs.PlayerRef	; DDVR
	VRHeld = False
```

## Function UnlockActor: Add

```papyrus
	UnregisterForAllKeys()	; DDVR
```

## Function UnlockActor: Add

```papyrus
	; DDVR: DD's own unlock is done -> camera, VRIK, hands and controls restored LAST (ordered + verified)
	If vrWasHeld
		VRUnlock("dd-unlock")
	EndIf
```

## Event OnControlDown: Replaces 1 DD line(s)

```papyrus
		VRActivatePressed()	; DDVR: counted once with the mapped-key path
```

## Event OnUpdate: Add

```papyrus
	; DDVR: fallback mode (no ZaZ VR Lock core) ticks every second for the pin / keep-alive; DD's own logic keeps its
	; 20-40 s rhythm through VRNextDD.
	If VRHeld && VRMode == 2 && user == libs.PlayerRef
		VRFallbackTick()
		If Utility.GetCurrentRealTime() < VRNextDD
			RegisterForSingleUpdate(1.0)
			Return
		EndIf
	EndIf
	If VRHeld && user == libs.PlayerRef
		VRWatch()
	EndIf
```

## Event OnUpdate: Replaces 1 DD line(s)

```papyrus
		If VRHeld && VRMode == 2	; DDVR
			VRNextDD = Utility.GetCurrentRealTime() + Utility.RandomInt(20,40)
			RegisterForSingleUpdate(1.0)
		Else
			RegisterForSingleUpdate(Utility.RandomInt(20,40))
		EndIf
```

## Event OnDDCSLEnd: Add

```papyrus
        VRBegin()	; DDVR: re-take the player after the scene
```

## Event OnDDCSLEnd: Remove 2 DD line(s)

Remove the `Game.ForceThirdPerson()` / `Game.SetCameraTarget(libs.PlayerRef)` pair here (the VR free camera replaces it).

## Event OnDDCSLEnd: Add

```papyrus
	If User == libs.PlayerRef && user	; DDVR
		user.StopTranslation()	; DDVR fix1: see LockActor
		VRLock()
	EndIf
```

## Function SexScene: Add

```papyrus
		; DDVR: SexLab (VR) runs the scene with its own camera -> give the player back first (re-taken in OnDDCSLEnd)
		If VRHeld && User == libs.PlayerRef
			VRHeld = False
			VRUnlock("sex-scene")
		EndIf
```

## Function StruggleScene: Add

```papyrus
	VRSceneStruggle = True	; DDVR fix1: this scene plays the struggle itself (11 s) -> no second start from PickRandomStruggle
```

## Function StruggleScene: Add

```papyrus
	VRSceneStruggle = False
```

## Function StruggleScene: Add

```papyrus
	If VRHeld && akActor == libs.PlayerRef && x812dd.StruggleOn()	; DDVR: the package doesn't animate the VR player
		VRPlay(x812dd.IdleEvent(CurrentStruggle), 11.0)
	EndIf
```

## Function StruggleScene: Add

```papyrus
		If VRHeld && akActor == libs.PlayerRef	; DDVR: back to the held pose
			VRSetLoop(x812dd.IdleEvent(CurrentPose))
		EndIf
```

