#Requires AutoHotkey v2.0
; Deep-Macros Framework — include local:  #Include Framework\DeepMacros.ahk

#Include Core\Utils.ahk
#Include Core\Theme.ahk
#Include Core\Bootstrap.ahk
#Include UI\Components.ahk
#Include UI\Dialogs.ahk
#Include UI\AppWindow.ahk

DM_Version() => DM_FrameworkVersion()
DM_Root() => DM_GetFrameworkRoot()

DM_Alert(title, msg) => DM_Dialog.Alert(title, msg)
DM_Confirm(title, msg, &ok) => DM_Dialog.Confirm(title, msg, &ok)
DM_Toast(msg, ms := 2200) => DM_Dialog.Toast(msg, ms)

DM_ConfigApp(scriptDir, title, buildContent, configPath := "", onSave := "") {
    if (configPath = "")
        configPath := scriptDir "\Config"
    app := DM_App(Map(
        "title", title,
        "subtitle", "Deep-Macros · v" DM_Version(),
        "exitOnClose", true,
        "onReady", (self) => buildContent.Call(self, configPath),
        "onSave", onSave
    ))
    app.SetFooter("Guardar", "Cerrar",
        (*) => DM_ConfigApp_Save(app, configPath),
        (*) => app.gui.Destroy()
    )
    return app
}

DM_ConfigApp_Save(app, configPath) {
    if (app.opts.Has("onSave") && app.opts["onSave"] != "")
        app.opts["onSave"].Call(app, configPath)
    DM_Toast("Configuración guardada")
}
