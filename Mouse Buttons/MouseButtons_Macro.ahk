#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Framework\DeepMacros.ahk

scriptDir := A_ScriptDir
configPath := scriptDir "\Config"
imgsDir := scriptDir "\imgs"

enabled := IniRead(configPath, "General", "Enabled", "1")
if (enabled != "1")
    ExitApp()

F10:: ShowMouseButtonsSettings()

ShowMouseButtonsSettings() {
    static app := ""
    if IsObject(app) {
        try {
            if app.gui.Hwnd
                return app.gui.Show()
        }
    }
    app := DM_ConfigApp(scriptDir, "Mouse Buttons", MouseButtons_BuildUI, configPath, MouseButtons_Save)
}

MouseButtons_BuildUI(app, configPath) {
    DM_Components.Title(app, "Mouse Buttons")
    DM_Components.Muted(app, "v" DM_Version(), "y88")
    app._enabled := DM_Components.Checkbox(app, "Macro activa",
        DM_Utils_Ini(configPath, "General", "Enabled", "1") = "1", "y120")
}

MouseButtons_Save(app, configPath) {
    IniWrite app._enabled.Value ? "1" : "0", configPath, "General", "Enabled"
}

; TODO: lógica de Mouse Buttons
