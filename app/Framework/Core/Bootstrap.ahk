global DM_FrameworkRoot := ""
global DM_InstallRoot := ""

DM_Bootstrap_VersionIni() {
    root := DM_Bootstrap_InstallRoot()
    p := root "\app\version.ini"
    if FileExist(p)
        return p
    return DM_Utils_PathParent(DM_Utils_PathParent(A_LineFile)) "\version.ini"
}

DM_Bootstrap_Ini(section, key, default := "") {
    return DM_Utils_Ini(DM_Bootstrap_VersionIni(), section, key, default)
}

DM_Bootstrap_CacheDir() {
    base := EnvGet("LocalAppData")
    if (base = "")
        base := A_AppData
    return DM_Utils_EnsureDir(base "\DMacros")
}

DM_Bootstrap_InstallRoot() {
    global DM_InstallRoot
    if (IsSet(DM_InstallRoot) && DM_InstallRoot != "" && FileExist(DM_InstallRoot "\DMacros.ahk"))
        return DM_InstallRoot
    if FileExist(A_ScriptDir "\DMacros.ahk")
        return A_ScriptDir
    if (IsSet(DM_AppRoot) && DM_AppRoot != "") {
        SplitPath DM_AppRoot, , &parent
        if (parent != "" && FileExist(parent "\DMacros.ahk"))
            return parent
    }
    return DM_Bootstrap_CacheDir()
}

DM_Bootstrap_AppVersion() {
    ini := DM_Bootstrap_InstallRoot() "\app\version.ini"
    if FileExist(ini)
        return DM_Utils_Ini(ini, "App", "Version", "0.0.0")
    return "0.0.0"
}

DM_Bootstrap_NormalizeRepoPath(path) {
    return StrLower(StrReplace(path, "\", "/"))
}

DM_Bootstrap_ShouldSyncPath(repoPath) {
    p := DM_Bootstrap_NormalizeRepoPath(repoPath)
    if (p = "dmacros.ahk")
        return true
    if !RegExMatch(p, "^app/")
        return false
    if DM_Bootstrap_IsProtectedPath(p)
        return false
    if RegExMatch(p, "/\.remote/")
        return false
    return true
}

DM_Bootstrap_IsProtectedPath(repoPath) {
    p := DM_Bootstrap_NormalizeRepoPath(repoPath)
    if (p = "app/config")
        return true
    return false
}

DM_Bootstrap_IsProtectedDest(destPath, installRoot) {
    p := destPath
    if (installRoot != "" && InStr(p, installRoot) = 1)
        p := SubStr(p, StrLen(installRoot) + 1)
    p := LTrim(DM_Bootstrap_NormalizeRepoPath(p), "/")
    return p = "app/config"
}

DM_Bootstrap_EnsureConfigFromExample(installRoot) {
    cfg := installRoot "\app\Config"
    ex := installRoot "\app\Config.example"
    if FileExist(cfg) || !FileExist(ex)
        return false
    try {
        FileCopy(ex, cfg)
        return true
    } catch {
        return false
    }
}

DM_GetFrameworkRoot() {
    global DM_FrameworkRoot, DM_AppRoot, DM_InstallRoot
    if (DM_FrameworkRoot != "" && FileExist(DM_FrameworkRoot "\DeepMacros.ahk"))
        return DM_FrameworkRoot

    env := EnvGet("DEEP_MACROS_FRAMEWORK")
    if (env != "" && FileExist(env "\DeepMacros.ahk"))
        return DM_FrameworkRoot := env

    install := DM_Bootstrap_InstallRoot()
    candidate := install "\app\Framework"
    if FileExist(candidate "\DeepMacros.ahk")
        return DM_FrameworkRoot := candidate

    if (IsSet(DM_AppRoot) && DM_AppRoot != "" && FileExist(DM_AppRoot "\Framework\DeepMacros.ahk"))
        return DM_FrameworkRoot := DM_AppRoot "\Framework"

    dir := A_ScriptDir
    loop 6 {
        for rel in ["app\Framework", "Framework"] {
            candidate := dir "\" rel
            if FileExist(candidate "\DeepMacros.ahk")
                return DM_FrameworkRoot := candidate
        }
        parent := DM_Utils_PathParent(dir)
        if (parent = "" || parent = dir)
            break
        dir := parent
    }

    throw Error("Framework not found. Ejecuta DMacros.ahk.", -1)
}

DM_FrameworkVersion() {
    fwIni := DM_GetFrameworkRoot() "\version.ini"
    if FileExist(fwIni)
        return DM_Utils_Ini(fwIni, "Framework", "Version", DM_Bootstrap_AppVersion())
    return DM_Bootstrap_AppVersion()
}

DM_Bootstrap_LogoPath() {
    for p in [
        DM_Bootstrap_InstallRoot() "\app\Framework\UI\assets\logo.png",
        DM_Utils_PathParent(DM_Utils_PathParent(A_LineFile)) "\UI\assets\logo.png"
    ] {
        if FileExist(p)
            return p
    }
    return ""
}

DM_Bootstrap_ProgressCenterLogo(ui) {
    if !IsObject(ui) || !ui.Has("logo") || !IsObject(ui["logo"])
        return
    pic := ui["logo"]
    try {
        pic.GetPos(, , &lw, &lh)
        if (lw < 1)
            return
        pic.Move(ui["innerX"] + (ui["innerW"] - lw) // 2, ui["logoY"] + (ui["logoH"] - lh) // 2)
    }
}

DM_Bootstrap_MsgSearch() => "Buscando actualización"
DM_Bootstrap_MsgNone() => "Sin actualizaciones"
DM_Bootstrap_MsgUpdate() => "Actualizando"

DM_Bootstrap_ProgressSetBar(ui, pct) {
    if !IsObject(ui) || !ui.Has("fill")
        return
    pct := DM_Utils_Clamp(pct, 0, 100)
    fillW := pct > 0 ? Max(4, Round(ui["trackW"] * pct / 100)) : 0
    try ui["fill"].Move(ui["trackX"], ui["trackY"], fillW, ui["trackH"])
    catch {
    }
}

DM_Bootstrap_ProgressPump(ui) {
    if !IsObject(ui)
        return
    DM_Bootstrap_ProgressCenterLogo(ui)
    try ui["gui"].Show("NoActivate")
    catch {
    }
    Sleep(-1)
}

DM_Bootstrap_ProgressShow() {
    winW := 400
    winH := 100
    pad := 28
    innerW := winW - pad * 2
    innerX := pad
    logoH := 30
    logoY := 18
    labelY := logoY + logoH + 10
    trackY := labelY + 24
    trackH := 5

    g := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale", "DMacros")
    g.BackColor := "25262b"
    g.MarginX := 0
    g.MarginY := 0

    logoCtrl := 0
    logo := DM_Bootstrap_LogoPath()
    if (logo != "")
        logoCtrl := g.Add("Picture", "x" innerX " y" logoY " w-1 h" logoH " +BackgroundTrans", logo)
    else {
        g.SetFont("s16 bold cF2F3F5", "Segoe UI")
        g.Add("Text", "x" innerX " y" logoY " w" innerW " h" logoH " Center +0x200", "Macros")
    }

    g.SetFont("s9 c9DA0A8", "Segoe UI")
    g.Add("Text", "x" innerX " y" labelY " w" innerW " h16 Center +0x200 vLabel", DM_Bootstrap_MsgSearch())

    g.Add("Text", "x" innerX " y" trackY " w" innerW " h" trackH " Background3f4048", "track")
    fill := g.Add("Text", "x" innerX " y" trackY " w0 h" trackH " Background4A9EFF vFill", "")

    g.Show("w" winW " h" winH " Center")
    DM_Utils_RoundFrame(g.Hwnd, 10)

    ui := Map(
        "gui", g,
        "fill", fill,
        "label", g["Label"],
        "logo", logoCtrl,
        "innerX", innerX,
        "innerW", innerW,
        "logoY", logoY,
        "logoH", logoH,
        "trackX", innerX,
        "trackY", trackY,
        "trackW", innerW,
        "trackH", trackH,
        "shownAt", A_TickCount,
        "minMs", 2200
    )
    DM_Bootstrap_ProgressCenterLogo(ui)
    return ui
}

DM_Bootstrap_ProgressSet(ui, done, total, labelText := "") {
    if !IsObject(ui)
        return
    pct := total > 0 ? Round(100 * done / total) : 0
    DM_Bootstrap_ProgressSetBar(ui, pct)
    if (labelText != "")
        ui["label"].Text := labelText
    DM_Bootstrap_ProgressPump(ui)
}

DM_Bootstrap_ProgressAnimateCheck(ui) {
    if !IsObject(ui)
        return
    ui["label"].Text := DM_Bootstrap_MsgSearch()
    loop 16 {
        DM_Bootstrap_ProgressSetBar(ui, 5 + A_Index * 5)
        DM_Bootstrap_ProgressPump(ui)
        Sleep(70)
    }
}

DM_Bootstrap_ProgressFinish(ui, labelText, holdMs := 800) {
    if !IsObject(ui)
        return
    ui["label"].Text := labelText
    DM_Bootstrap_ProgressSetBar(ui, 100)
    DM_Bootstrap_ProgressPump(ui)
    Sleep(holdMs)
    DM_Bootstrap_ProgressHide(ui)
}

DM_Bootstrap_ProgressHide(ui) {
    if !IsObject(ui)
        return
    elapsed := A_TickCount - ui["shownAt"]
    minMs := ui.Has("minMs") ? ui["minMs"] : 2600
    if (elapsed < minMs)
        Sleep(minMs - elapsed)
    try ui["gui"].Destroy()
    catch {
    }
}

; Siempre al iniciar DMacros (salvo DM_SKIP_BOOTSTRAP=1 para desarrollo).
DM_Bootstrap_RunAtStartup() {
    global DM_InstallRoot, DM_AppRoot, DM_FrameworkRoot
    if (EnvGet("DM_SKIP_BOOTSTRAP") = "1")
        return

    install := DM_Bootstrap_InstallRoot()
    ui := DM_Bootstrap_ProgressShow()
    DM_Bootstrap_ProgressAnimateCheck(ui)

    localVer := DM_Bootstrap_AppVersion()
    remoteVer := ""
    try {
        remoteVer := DM_Http.FetchRemoteAppVersion()
    } catch {
        remoteVer := localVer
    }

    if (DM_Utils_VersionCompare(remoteVer, localVer) <= 0) {
        DM_Bootstrap_ProgressFinish(ui, DM_Bootstrap_MsgNone())
        return
    }

    try {
        DM_Bootstrap_ProgressSet(ui, 0, 100, DM_Bootstrap_MsgUpdate())
        result := DM_Http.SyncInstall(install, remoteVer, ui)
        if !result["success"]
            throw Error("La actualización no se completó.", -1)

        DM_InstallRoot := install
        DM_AppRoot := install "\app"
        DM_FrameworkRoot := install "\app\Framework"
        DM_Bootstrap_EnsureConfigFromExample(install)
        DM_Bootstrap_ProgressFinish(ui, DM_Bootstrap_MsgUpdate(), 1000)
        MsgBox("Actualizado.`n`nReinicia DMacros por favor.", "DMacros", "Iconi")
        ExitApp
    } catch as e {
        DM_Bootstrap_ProgressHide(ui)
        if !FileExist(install "\DMacros.ahk") {
            MsgBox("No se pudo descargar DMacros.`n`n" e.Message
                . "`n`nRepo privado: define DM_GH_TOKEN o GITHUB_TOKEN.", "DMacros", "Icon!")
            ExitApp 1
        }
    }
}

DM_Bootstrap_CheckNow(force := true) {
    global DM_InstallRoot, DM_AppRoot, DM_FrameworkRoot
    install := DM_Bootstrap_InstallRoot()
    ui := DM_Bootstrap_ProgressShow()
    DM_Bootstrap_ProgressAnimateCheck(ui)
    try {
        remoteVer := DM_Http.FetchRemoteAppVersion()
        localVer := DM_Bootstrap_AppVersion()
        if (!force && DM_Utils_VersionCompare(remoteVer, localVer) <= 0) {
            DM_Bootstrap_ProgressFinish(ui, DM_Bootstrap_MsgNone())
            return Map("updated", false, "local", localVer, "remote", remoteVer, "error", "")
        }
        DM_Bootstrap_ProgressSet(ui, 0, 100, DM_Bootstrap_MsgUpdate())
        result := DM_Http.SyncInstall(install, remoteVer, ui)
        DM_Bootstrap_ProgressFinish(ui, DM_Bootstrap_MsgUpdate(), 1000)
        if !result["success"]
            throw Error("La actualización no se completó.", -1)
        DM_InstallRoot := install
        DM_AppRoot := install "\app"
        DM_FrameworkRoot := install "\app\Framework"
        DM_Bootstrap_EnsureConfigFromExample(install)
        return Map("updated", true, "local", remoteVer, "remote", remoteVer, "error", "")
    } catch as e {
        DM_Bootstrap_ProgressHide(ui)
        return Map("updated", false, "local", DM_Bootstrap_AppVersion(), "remote", "",
            "error", e.Message)
    }
}
