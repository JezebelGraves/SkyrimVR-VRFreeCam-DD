Scriptname x812dd Hidden
{DD VR Lock - helpers and console / mod API for the Devious Devices NG VR patch (player only).
Console:
  cgf "x812dd.Release"           release the player from the contraption (DD's own unlock + full VR restore)
  cgf "x812dd.NextView"          camera to the next side of the device
  cgf "x812dd.SetStruggle" 0     no DD struggle animations on your body (1 = on, default)
  cgf "x812dd.SetKeepAlive" 6.0  seconds between pose keep-alive re-sends (default 6)
  cgf "x812dd.UseCore" 0         ignore ZaZ VR Lock even if installed (1 = use it, default)
  cgf "x812dd.Panic"             emergency reset of camera / VRIK / controls
Mods: x812dd.Release(reason) / x812dd.IsLocked() / x812dd.GetDevice(); with ZaZ VR Lock installed x812zl.Release()
works too. Needs powerofthree's Papyrus Extender (reads the pose idle out of DD's pose package).}

Bool Function CoreAvailable() global
	If StorageUtil.GetIntValue(None, "x812dd.NoCore", 0) == 1
		Return False
	EndIf
	; ZaZ VR Lock (optional) finds its own core quest; None when it is not installed
	If x812zl.Core() == None
		Return False
	EndIf
	Return x812zl.ApiVersion() >= 2
EndFunction

Bool Function StruggleOn() global
	Return StorageUtil.GetIntValue(None, "x812dd.Struggle", 1) == 1
EndFunction

Float Function KeepAlive() global
	Return StorageUtil.GetFloatValue(None, "x812dd.KeepAlive", 6.0)
EndFunction

; the animation event of a DD pose / struggle package's first idle (DD poses are package idles)
String Function IdleEvent(Package pkg) global
	If pkg == None
		Return ""
	EndIf
	Idle[] idles = PO3_SKSEFunctions.GetPackageIdles(pkg)
	If !idles || idles.Length == 0
		Debug.Trace("DDVR: package " + pkg + " has no idles")
		Return ""
	EndIf
	Return PO3_SKSEFunctions.GetAnimationEventName(idles[0])
EndFunction

; random pose among the device's bound poses whose idle is not a struggling variant; None if there is none
Package Function PickCalmPose(Package[] poses) global
	If !poses
		Return None
	EndIf
	Package[] calm = new Package[64]
	Int n = 0
	Int i = 0
	While i < poses.Length && n < 64
		If poses[i]
			String ev = IdleEvent(poses[i])
			If ev != "" && StringUtil.Find(ev, "struggl") < 0
				calm[n] = poses[i]
				n += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	If n == 0
		Return None
	EndIf
	Return calm[Utility.RandomInt(0, n - 1)]
EndFunction

; ---- fallback body lock (plain VRFreeCam): arms, body IK, posture, head off + HIGGS hands off
Function BodyOff() global
	VRIK.VrikSetSetting("enablePosture", 0)
	VRIK.VrikSetSetting("enableBody", 0)
	VRIK.VrikSetSetting("enableLeftArm", 0)
	VRIK.VrikSetSetting("enableRightArm", 0)
	VRIK.VrikSetSetting("enableHead", 0)
	VRIK.VrikSetSetting("lockHmdToBody", 0)
	If !HiggsVR.IsDisabled(True)
		HiggsVR.DisableHand(True)
	EndIf
	If !HiggsVR.IsDisabled(False)
		HiggsVR.DisableHand(False)
	EndIf
EndFunction

Bool Function LockIntact(Float x, Float y, Float ang) global
	If VRIK.VrikGetSetting("lockPosition") != 2.0 || VRIK.VrikGetSetting("lockRotation") != 1.0
		Return False
	EndIf
	If Math.Abs(VRIK.VrikGetSetting("lockPositionX") - x) > 2.0 || Math.Abs(VRIK.VrikGetSetting("lockPositionY") - y) > 2.0
		Return False
	EndIf
	If VRIK.VrikGetSetting("enableLeftArm") != 0.0 || VRIK.VrikGetSetting("enableRightArm") != 0.0 || VRIK.VrikGetSetting("enableBody") != 0.0 || VRIK.VrikGetSetting("enablePosture") != 0.0
		Return False
	EndIf
	Return HiggsVR.IsDisabled(True) && HiggsVR.IsDisabled(False)
EndFunction

Bool Function HiggsOff(Bool left) global
	Return HiggsVR.IsDisabled(left)
EndFunction

Function HiggsOn(Bool left) global
	HiggsVR.EnableHand(left)
EndFunction

; ---- public API / console
ObjectReference Function GetDevice() global
	Return StorageUtil.GetFormValue(None, "x812dd.Device") as ObjectReference
EndFunction

Bool Function IsLocked() global
	Return GetDevice() != None
EndFunction

Function Release(String reason = "api") global
	zadcFurnitureScript d = GetDevice() as zadcFurnitureScript
	If d
		d.VRForceRelease(reason)
	Else
		Debug.Notification("DD VR Lock: not locked")
	EndIf
EndFunction

Function NextView() global
	If CoreAvailable() && x812zl.IsExtHeld(None)
		x812zl.NextView()
	Else
		StorageUtil.SetIntValue(None, "x812dd.View", (StorageUtil.GetIntValue(None, "x812dd.View", 0) + 1) % 4)
		StorageUtil.SetIntValue(None, "x812dd.ViewReq", 1)
	EndIf
EndFunction

Function SetStruggle(Int on) global
	StorageUtil.SetIntValue(None, "x812dd.Struggle", on)
EndFunction

Function SetKeepAlive(Float sec) global
	StorageUtil.SetFloatValue(None, "x812dd.KeepAlive", sec)
EndFunction

Function UseCore(Int on) global
	StorageUtil.SetIntValue(None, "x812dd.NoCore", (on == 0) as Int)
EndFunction

Function Panic() global
	If CoreAvailable() && x812zl.IsExtHeld(None)
		x812zl.Panic()
	Else
		VRFreeCam.PanicReset()
	EndIf
	StorageUtil.UnsetFormValue(None, "x812dd.Device")
EndFunction
