#Requires AutoHotkey v2.0
#SingleInstance Force

scriptDir := A_ScriptDir
configPath := scriptDir "\Config"
imgsDir := scriptDir "\imgs"

enabled := IniRead(configPath, "General", "Enabled", "1")
if (enabled != "1")
    ExitApp()

; TODO: lógica de Mouse Buttons
