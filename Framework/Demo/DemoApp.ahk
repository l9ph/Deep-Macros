#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\HttpBoot.ahk

Demo_Build(app, configPath) {
    DM_Components.Title(app, "Panel de control")
    DM_Components.Muted(app, "v" DM_Version() " · " DM_Root() " · HTTPS", "y88")
    DM_Components.Spacer(app, 12)
    app._enabled := DM_Components.Checkbox(app, "Macro habilitada",
        DM_Utils_Ini(configPath, "General", "Enabled", "1") = "1", "y130")
    app._hotkey := DM_Components.Input(app,
        DM_Utils_Ini(configPath, "Macro", "Hotkey", "F8"), "y170")
}

Demo_Save(app, configPath) {
    IniWrite app._enabled.Value ? "1" : "0", configPath, "General", "Enabled"
    IniWrite app._hotkey.Value, configPath, "Macro", "Hotkey"
}

configPath := A_ScriptDir "\demo-config.ini"
if !FileExist(configPath)
    FileAppend("[General]`nEnabled=1`n[Macro]`nHotkey=F8`n", configPath)

DM_ConfigApp(A_ScriptDir, "Deep-Macros Demo", Demo_Build, configPath, Demo_Save)
