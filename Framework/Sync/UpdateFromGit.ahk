#Requires AutoHotkey v2.0
; Descarga el Framework desde GitHub (raw) a %LocalAppData%\Deep-Macros\Framework
#SingleInstance Force

#Include ..\Core\Utils.ahk

root := A_LocalAppData "\Deep-Macros\Framework"
manifestPath := A_ScriptDir "\manifest.txt"
rawBase := "https://raw.githubusercontent.com/l9ph/Deep-Macros/main/Framework"

if !FileExist(manifestPath) {
    MsgBox "manifest.txt no encontrado", "Deep-Macros", "Icon!"
    ExitApp 1
}

DM_Utils_EnsureDir(root)
DM_Utils_EnsureDir(root "\Core")
DM_Utils_EnsureDir(root "\UI")
DM_Utils_EnsureDir(root "\Sync")

lines := StrSplit(Trim(FileRead(manifestPath)), "`n", "`r")
ok := 0
fail := 0

for line in lines {
    rel := Trim(line)
    if (rel = "" || SubStr(rel, 1, 1) = ";")
        continue
    url := rawBase "/" StrReplace(rel, "\", "/")
    dest := root "\" rel
    DM_Utils_EnsureDir(DM_Utils_PathParent(dest))
    try {
        Download url, dest
        ok++
    } catch as e {
        fail++
    }
}

; Copiar manifest y este script
try {
    Download rawBase "/version.ini", root "\version.ini"
    Download rawBase "/Sync/manifest.txt", root "\Sync\manifest.txt"
} catch {
}

msg := "Framework actualizado en:`n" root "`n`nOK: " ok "`nFallos: " fail
if (fail > 0)
    MsgBox msg, "Deep-Macros — revisar", "Icon!"
else
    MsgBox msg, "Deep-Macros", "Iconi"
ExitApp fail > 0 ? 1 : 0
