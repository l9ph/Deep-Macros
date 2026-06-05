#Requires AutoHotkey v2.0

#Include Core\Utils.ahk
#Include Core\BindCapture.ahk
#Include Core\Theme.ahk
#Include Core\Bootstrap.ahk
#Include Core\MacroRuntime.ahk
#Include UI\Anim.ahk
#Include UI\Components.ahk
#Include UI\DM_WebApp.ahk
#Include UI\Rayfield.ahk
#Include UI\Dialogs.ahk
#Include UI\AppWindow.ahk

global DM_ActiveApp := 0
global F := DM_UI
global App := 0
global Rayfield := RF_Library()

DM_Version() => DM_FrameworkVersion()
DM_Root() => DM_GetFrameworkRoot()

DM_Alert(title, msg) => DM_Dialog.Alert(title, msg)
DM_Confirm(title, msg, &ok) => DM_Dialog.Confirm(title, msg, &ok)
DM_Toast(msg, ms := 2200) => DM_Dialog.Toast(msg, ms)

DM_HideConfigApp(*) {
    global DM_ActiveApp
    if (!IsObject(DM_ActiveApp))
        return
    try {
        hwnd := DM_ActiveApp.gui.Hwnd
        if (hwnd && WinExist("ahk_id " hwnd)) {
            WinHide(hwnd)
            try
                TrayTip("Macros", "Running in background. Open from the tray icon.", 1)
            catch {
            }
        }
    }
}

DM_ConfigApp(scriptDir, title, configPath := "", onSave := "", buildUI := "") {
    global DM_ActiveApp, App
    if (IsObject(DM_ActiveApp)) {
        try
            DM_ActiveApp.gui.Destroy()
        catch {
        }
    }
    DM_ActiveApp := 0
    App := 0
    if (configPath = "")
        configPath := scriptDir "\Config"
    opts := Map(
        "title", title,
        "subtitle", "Macros · v" DM_Version(),
        "onSave", onSave,
        "onSaveConfigPath", configPath
    )
    if (Type(buildUI) = "Func")
        opts["onReady"] := buildUI
    else if (buildUI != "")
        opts["onReady"] := %buildUI%
    app := DM_App(opts)
    DM_ActiveApp := app
    App := app
    return app
}

DM_ConfigApp_Save(app, configPath) {
    if (app.opts.Has("onSave") && app.opts["onSave"] != "")
        app.opts["onSave"].Call(app, configPath)
    DM_Toast("Settings saved")
    try {
        if (IsObject(app) && app.HasProp("wv") && app.wv)
            app.wv.ExecuteScriptAsync("showToast('success','Settings saved')")
    } catch {
    }
}

DM_TrayRegister(tip, openSettings) {
    if (Type(openSettings) != "Func")
        throw TypeError("DM_TrayRegister: second argument must be a Func.", -1)
    Persistent(true)
    DM_Utils_TraySetAppIcon(tip)
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Open Macros", openSettings)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.ClickCount := 1
    A_TrayMenu.Default := "Open Macros"
}
