#Requires AutoHotkey v2.0
#SingleInstance Force

; Carga el framework por HTTPS desde GitHub (caché en Framework\.remote)
#Include ..\Framework\HttpBoot.ahk

scriptDir := A_ScriptDir
configPath := scriptDir "\Config"
imgsDir := scriptDir "\imgs"

enabled := IniRead(configPath, "General", "Enabled", "1")
if (enabled != "1")
    ExitApp()

; F10 = panel de configuración
F10:: ShowAssasinationSettings()

; Ctrl+Shift+F = forzar actualización del framework por HTTPS
^+F:: {
    DM_Http.Ensure(true)
    Reload
}

ShowAssasinationSettings() {
    static app := ""
    if IsObject(app) {
        try {
            if app.gui.Hwnd
                return app.gui.Show()
        }
    }
    app := DM_ConfigApp(scriptDir, "Assasination Dash", Assasination_BuildUI, configPath, Assasination_Save)
}

Assasination_BuildUI(app, configPath) {
    DM_Components.Title(app, "Assasination Dash")
    DM_Components.Muted(app, "Framework " DM_Version() " · HTTPS · " DM_Root(), "y88")
    app._enabled := DM_Components.Checkbox(app, "Macro activa",
        DM_Utils_Ini(configPath, "General", "Enabled", "1") = "1", "y120")
}

Assasination_Save(app, configPath) {
    IniWrite app._enabled.Value ? "1" : "0", configPath, "General", "Enabled"
}

; TODO: lógica del macro (hotkeys, ImageSearch en imgs\, etc.)
