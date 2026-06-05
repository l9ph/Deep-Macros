#Requires AutoHotkey v2.0
#SingleInstance Force

global DM_AppRoot := A_ScriptDir "\app"
global DM_ConfigPath := DM_AppRoot "\Config"

#Include app\Framework\DeepMacros.ahk
#Include app\Macros\Assassination.ahk
#Include app\Macros\Automatics.ahk
#Include app\Macros\MouseButtons.ahk
#Include app\Macros\Extra.ahk

DM_AppVersion() => "0.1"

ShowDMacrosSettings() {
    global DM_ActiveApp, Rayfield, DM_ConfigPath, DM_AppRoot
    if (IsObject(DM_ActiveApp)) {
        try {
            hwnd := DM_ActiveApp.gui.Hwnd
            if (hwnd && WinExist("ahk_id " hwnd)) {
                WinShow(hwnd)
                WinActivate(hwnd)
                return
            }
        }
    }
    Rayfield.CreateWindow(
        Map("Name", "Macros"),
        DM_AppRoot, DM_ConfigPath, DMacros_Save, DMacros_BuildUI)
}

DMacros_BuildUI(Win) {
    MouseButtons_BuildUI(Win.CreateTab("Mouse Tweaks"), Win)
    Assassination_BuildUI(Win.CreateTab("Assassination"), Win)
    Automatics_BuildUI(Win.CreateTab("Automatics"), Win)
    Extra_BuildUI(Win.CreateTab("Extra"), Win)
}

DMacros_Save(app, configPath) {
    global DM_ActiveApp
    win := IsObject(DM_ActiveApp) && DM_ActiveApp.HasProp("_rfWindow") ? DM_ActiveApp._rfWindow : 0
    if !IsObject(win)
        return
    Assassination_Save(win, configPath)
    Automatics_Save(win, configPath)
    MouseButtons_Save(win, configPath)
    Extra_Save(win, configPath)
    DMacros_ReloadModules()
}

DMacros_ReloadModules() {
    Assassination_Run()
    Automatics_Run()
    MouseButtons_Run()
}

DM_TrayRegister("Macros", (*) => ShowDMacrosSettings())
Persistent(true)

Extra_AutoFillAtStart(DM_ConfigPath)
DMacros_ReloadModules()

if (DM_Utils_Ini(DM_ConfigPath, "App", "ShowUIOnStart", "1") = "1")
    ShowDMacrosSettings()
