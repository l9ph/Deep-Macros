#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\HttpBoot.ahk

log := A_Temp "\dm-http-test.log"
FileAppend "FW_LOADED=" DM_FW_LOADED "`n", log
FileAppend "Version=" DM_Version() "`n", log
FileAppend "Root=" DM_Root() "`n", log
FileAppend "CacheExists=" FileExist(DM_Root() "\DeepMacros.ahk") "`n", log
FileAppend "StateVersion=" DM_Utils_Ini(DM_Root() "\.http-state.ini", "Sync", "Version", "?") "`n", log
FileAppend "SyncOk=" DM_Utils_Ini(DM_Root() "\.http-state.ini", "Sync", "Ok", "?") "`n", log
ExitApp 0
