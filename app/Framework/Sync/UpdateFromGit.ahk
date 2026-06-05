#Requires AutoHotkey v2.0
; Actualización manual (misma lógica que al iniciar DMacros).
#SingleInstance Force

global DM_InstallRoot := (A_Args.Length >= 1 && Trim(A_Args[1]) != "")
    ? Trim(A_Args[1])
    : (A_ScriptDir "\..\..\..")
global DM_AppRoot := DM_InstallRoot "\app"
global DM_ConfigPath := DM_AppRoot "\Config"

#Include ..\Core\Utils.ahk
#Include ..\Core\Bootstrap.ahk
#Include ..\Core\Http.ahk

try {
    r := DM_Bootstrap_CheckNow(true)
    if (r["error"] != "") {
        MsgBox("No se pudo actualizar.`n`n" r["error"], "DMacros", "Icon!")
        ExitApp 1
    }
    if r["updated"] {
        MsgBox("Actualizado.`n`nReinicia DMacros por favor.", "DMacros", "Iconi")
        ExitApp
    }
    MsgBox("Ya tienes la última versión.", "DMacros", "Iconi")
    ExitApp 0
} catch as e {
    MsgBox(e.Message, "DMacros", "Icon!")
    ExitApp 1
}
