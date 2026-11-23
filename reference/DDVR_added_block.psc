; DDVR reference block for Devious Devices NG zadcFurnitureScript (Skyrim VR, player only).
; NOT a complete script and NOT a drop-in file. This is only the code we added at the END of
; zadcFurnitureScript; the small call sites inside DD's own functions are listed in reference/HOOKS.md.
; Merge both into YOUR OWN copy of DD NG 0.4.2's zadcFurnitureScript.psc and compile it yourself.
; No Devious Devices code is included here.

; ==================================================================================================================
; DDVR - Skyrim VR free camera for the player (DD VR Lock). Player only; NPCs never reach any of this.
; With "ZaZ VR Lock" installed (x812zl.ApiVersion() >= 2) its core owns the player: snapshot, VRIK pin, arms/hands
; block, held camera with next view, keep-alive, ordered + verified release, release hook x812zl.Release and the
; "release me" gesture. Without it: plain VRFreeCam (shipped) with a small built-in keep-alive.
; ==================================================================================================================
Bool VRSceneStruggle = False	; DDVR fix1
Bool VRHeld = False				; the player's body is held by us right now
Bool VRBegun = False
Int VRMode = 0					; 0 none, 1 ZaZ VR Lock core, 2 plain VRFreeCam fallback
Float VRNextDD = 0.0
Float VRX
Float VRY
Float VRZ
Float VRA
String VRLoopEv = ""
Float VRKeepAt = 0.0
Float VRStruggleUntil = 0.0
Float VRLastActivateAt = 0.0

Function VRBegin()
	If VRBegun
		Return
	EndIf
	VRMode = 0
	If x812dd.CoreAvailable()
		If x812zl.ExtBegin(self, "dd")
			VRMode = 1
			RegisterForModEvent("x812zl_ExtRelease", "OnVRCoreRelease")
		Else
			Debug.Trace("DDVR: ZaZ VR Lock core busy/refused -> plain VRFreeCam")
		EndIf
	EndIf
	If VRMode == 0
		VRMode = 2
	EndIf
	VRBegun = True
	StorageUtil.SetFormValue(None, "x812dd.Device", self)
EndFunction

Function VRLock()
	Actor p = libs.PlayerRef
	If !VRBegun
		VRBegin()
	EndIf
	Utility.Wait(0.5)
	If user != p || UnlockMutex
		Return
	EndIf
	VRLoopEv = x812dd.IdleEvent(CurrentPose)
	VRX = self.GetPositionX()
	VRY = self.GetPositionY()
	VRZ = self.GetPositionZ()
	VRA = self.GetAngleZ()
	Debug.Trace("DDVR: lock on " + self + " (" + DeviceName + ") pose " + CurrentPose + " idle '" + VRLoopEv + "' mode " + VRMode)
	If VRMode == 1
		If x812zl.ExtLock(VRX, VRY, VRZ, VRA, VRLoopEv, "", x812dd.KeepAlive())
			VRHeld = True
		Else
			Debug.Trace("DDVR: core lock failed -> plain VRFreeCam")
			x812zl.ExtRelease("dd-lock-failed")
			VRMode = 2
		EndIf
	EndIf
	If VRMode == 2
		VRFallbackLock()
		VRHeld = True
		VRNextDD = Utility.GetCurrentRealTime() + 30.0
		RegisterForSingleUpdate(1.0)
	EndIf
	VRBegun = False
	; DD's control rules on top of the free cam: Activate ON (the escape menu), menu / journal OFF
	Game.EnablePlayerControls(abMovement = false, abFighting = false, abCamSwitch = false, abLooking = false, abSneaking = false, abMenu = false, abActivate = true, abJournalTabs = false)
	Game.DisablePlayerControls(abMovement = false, abFighting = false, abCamSwitch = false, abLooking = false, abSneaking = false, abMenu = true, abActivate = false, abJournalTabs = true)
EndFunction

Function VRUnlock(String reason)
	Int m = VRMode
	VRHeld = False
	VRBegun = False
	VRMode = 0
	If m == 1
		x812zl.ExtRelease(reason)
	ElseIf m == 2
		VRFallbackUnlock()
	EndIf
	StorageUtil.UnsetFormValue(None, "x812dd.Device")
	Debug.Trace("DDVR: released (" + reason + ", mode " + m + ")")
EndFunction

Function VRSetLoop(String ev)
	If ev == "" || !VRHeld
		Return
	EndIf
	VRLoopEv = ev
	VRStruggleUntil = 0.0
	If VRMode == 1
		x812zl.ExtSetLoop(ev)
	Else
		Debug.SendAnimationEvent(libs.PlayerRef, ev)
		VRKeepAt = Utility.GetCurrentRealTime() + x812dd.KeepAlive()
	EndIf
EndFunction

Function VRPlay(String ev, Float sec)
	If ev == "" || !VRHeld
		Return
	EndIf
	If VRMode == 1
		x812zl.ExtPlay(ev, sec)
	Else
		Debug.SendAnimationEvent(libs.PlayerRef, ev)
		VRStruggleUntil = Utility.GetCurrentRealTime() + sec
		VRKeepAt = VRStruggleUntil
	EndIf
EndFunction

; the core is releasing the player (x812zl.Release hook, rescue, self-release gesture, panic): run DD's own unlock;
; its VRUnlock -> x812zl.ExtRelease is the ack, and the core restores camera + controls after it.
Event OnVRCoreRelease(String eventName, String strArg, Float numArg, Form sender)
	If sender != self
		Return
	EndIf
	If user == libs.PlayerRef && VRMode == 1 && !UnlockMutex
		Debug.Trace("DDVR: core release (" + strArg + ") -> DD unlock")
		UnlockActor()
	EndIf
	x812zl.ExtCleanupDone()
EndEvent

; every DD update while held: keep the event registration (it does not survive every load) and notice a core
; release that never reached us
Function VRWatch()
	If VRMode == 1
		RegisterForModEvent("x812zl_ExtRelease", "OnVRCoreRelease")
		If !x812zl.IsExtHeld(self) && !UnlockMutex
			Debug.Trace("DDVR: the core no longer holds the player -> DD unlock")
			VRHeld = False
			VRMode = 0
			UnlockActor()
		EndIf
	EndIf
EndFunction

; public hook (also console: cgf "x812dd.Release"): DD's own unlock + our restore, for NPCs, mods and self-release
Function VRForceRelease(String reason)
	If user == libs.PlayerRef
		Debug.Trace("DDVR: forced release (" + reason + ")")
		UnlockActor()
	EndIf
EndFunction

; ---------------------------------------------------------------------------------------- plain VRFreeCam fallback
Function VRFallbackLock()
	Actor p = libs.PlayerRef
	StorageUtil.SetIntValue(None, "x812dd.fb.higgsL", x812dd.HiggsOff(True) as Int)
	StorageUtil.SetIntValue(None, "x812dd.fb.higgsR", x812dd.HiggsOff(False) as Int)
	p.SetDontMove(True)
	p.SetPosition(VRX, VRY, VRZ)
	p.SetAngle(0.0, 0.0, VRA)
	Utility.Wait(0.3)
	If VRLoopEv != ""
		Debug.SendAnimationEvent(p, "IdleForceDefaultState")
		Utility.Wait(0.1)
		Debug.SendAnimationEvent(p, VRLoopEv)
	EndIf
	VRFreeCam.LockAt(p, VRX, VRY, VRZ, VRA)
	x812dd.BodyOff()
	VRFallbackPlaceCam()
	VRKeepAt = Utility.GetCurrentRealTime() + x812dd.KeepAlive()
EndFunction

; camera actor on a viewpoint looking at the body (0 front, 1 right, 2 back, 3 left), held there; the body stays pinned
Function VRFallbackPlaceCam()
	Actor p = libs.PlayerRef
	Int v = StorageUtil.GetIntValue(None, "x812dd.View", 0)
	Float d = 170.0
	Float lx = 0.0
	Float ly = d
	Float face = VRA + 180.0
	If v == 1
		lx = d
		ly = 0.0
		face = VRA + 270.0
	ElseIf v == 2
		ly = 0.0 - d
		face = VRA
	ElseIf v == 3
		lx = 0.0 - d
		ly = 0.0
		face = VRA + 90.0
	EndIf
	p.SetDontMove(True)
	p.SetPosition(VRFreeCam.LocalToWorldX(VRX, VRY, VRA, lx, ly), VRFreeCam.LocalToWorldY(VRX, VRY, VRA, lx, ly), VRZ)
	p.SetAngle(0.0, 0.0, face)
	VRFreeCam.Repin(VRX, VRY, VRZ, VRA)
	x812dd.BodyOff()
EndFunction

Function VRFallbackTick()
	Float now = Utility.GetCurrentRealTime()
	If StorageUtil.GetIntValue(None, "x812dd.ViewReq", 0) == 1
		StorageUtil.UnsetIntValue(None, "x812dd.ViewReq")
		VRFallbackPlaceCam()
	EndIf
	If !x812dd.LockIntact(VRX, VRY, VRA)
		VRFreeCam.Repin(VRX, VRY, VRZ, VRA)
		x812dd.BodyOff()
	EndIf
	If VRLoopEv != "" && now >= VRKeepAt && now >= VRStruggleUntil
		Debug.SendAnimationEvent(libs.PlayerRef, VRLoopEv)
		VRKeepAt = now + x812dd.KeepAlive()
	EndIf
EndFunction

Function VRFallbackUnlock()
	Actor p = libs.PlayerRef
	p.StopTranslation()
	p.SetDontMove(False)
	p.SetPosition(VRX, VRY, VRZ + 10.0)
	Debug.SendAnimationEvent(p, "IdleForceDefaultState")
	VRFreeCam.UnlockInPlace(p)
	If StorageUtil.GetIntValue(None, "x812dd.fb.higgsL", 0) == 0
		x812dd.HiggsOn(True)
	EndIf
	If StorageUtil.GetIntValue(None, "x812dd.fb.higgsR", 0) == 0
		x812dd.HiggsOn(False)
	EndIf
	Game.SetPlayerAIDriven(False)
EndFunction

; ---------------------------------------------------------------------------------------- Activate on VR controllers
Function VRRegisterActivateKeys()
	UnregisterForAllKeys()
	Int k = Input.GetMappedKey("Activate", 2)
	If k > 0
		RegisterForKey(k)
	EndIf
	k = Input.GetMappedKey("Activate", 5)
	If k > 0
		RegisterForKey(k)
	EndIf
	k = Input.GetMappedKey("Activate", 7)
	If k > 0
		RegisterForKey(k)
	EndIf
EndFunction

Event OnKeyDown(Int KeyCode)
	If Utility.IsInMenuMode() || UI.IsMenuOpen("Dialogue Menu") || UI.IsMenuOpen("Loading Menu")
		Return
	EndIf
	If user != libs.PlayerRef
		Return
	EndIf
	If KeyCode == Input.GetMappedKey("Activate", 2) || KeyCode == Input.GetMappedKey("Activate", 5) || KeyCode == Input.GetMappedKey("Activate", 7)
		VRActivatePressed()
	EndIf
EndEvent

; one press can arrive as both a control event and a key event -> count it once
Function VRActivatePressed()
	Float now = Utility.GetCurrentRealTime()
	If (now - VRLastActivateAt) < 0.5 && (now >= VRLastActivateAt)
		Return
	EndIf
	VRLastActivateAt = now
	self.Activate(libs.PlayerRef)
