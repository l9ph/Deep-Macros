; Bootstrap remoto — único include local obligatorio en cada macro
; 1) Peticiones HTTPS a GitHub  2) Caché en Framework\.remote  3) Carga el framework
#Requires AutoHotkey v2.0

global DM_FW_LOADED := false

#Include Core\Utils.ahk
#Include Core\Http.ahk

; Caché relativa al repo (funciona con #Include estático en v2)
#Include *i .remote\DeepMacros.ahk

if (!DM_FW_LOADED) {
    if (EnvGet("DM_HTTP_BOOT") = "1") {
        MsgBox "El Framework no cargó tras sincronizar HTTPS.", "Deep-Macros", "Icon!"
        ExitApp 1
    }
    EnvSet "1", "DM_HTTP_BOOT"
    try
        DM_Http.Ensure()
    catch as e {
        if !DM_Http.SeedFromLocal(DM_Http.CacheDir()) {
            EnvSet "", "DM_HTTP_BOOT"
            MsgBox "Error HTTPS:`n`n" e.Message, "Deep-Macros", "Icon!"
            ExitApp 1
        }
    }
    EnvSet "", "DM_HTTP_BOOT"
    Reload
}
