#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Framework\DeepMacros.ahk

scriptDir := A_ScriptDir
configPath := scriptDir "\Config"
imgsDir := scriptDir "\imgs"

enabled := IniRead(configPath, "General", "Enabled", "1")
if (enabled != "1")
    ExitApp()

F10:: ShowAutoMathSettings()

ShowAutoMathSettings() {
    static app := ""
    if IsObject(app) {
        try {
            if app.gui.Hwnd
                return app.gui.Show()
        }
    }
    app := DM_ConfigApp(scriptDir, "Auto Math", AutoMath_BuildUI, configPath, AutoMath_Save)
}

AutoMath_BuildUI(app, configPath) {
    DM_Components.Title(app, "Auto Math")
    DM_Components.Muted(app, "v" DM_Version(), "y88")
    app._enabled := DM_Components.Checkbox(app, "Macro activa",
        DM_Utils_Ini(configPath, "General", "Enabled", "1") = "1", "y120")
}

AutoMath_Save(app, configPath) {
    IniWrite app._enabled.Value ? "1" : "0", configPath, "General", "Enabled"
}

; TODO: lógica de Auto Math
