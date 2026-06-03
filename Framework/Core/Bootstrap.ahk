; Resuelve la ruta del Framework (repo local, env, AppData)
global DM_FrameworkRoot := ""
global DM_RAW_BASE := "https://raw.githubusercontent.com/l9ph/Deep-Macros/main/Framework"
global DM_REPO := "l9ph/Deep-Macros"

DM_GetFrameworkRoot() {
    global DM_FrameworkRoot
    if (DM_FrameworkRoot != "" && DirExist(DM_FrameworkRoot))
        return DM_FrameworkRoot

    env := EnvGet("DEEP_MACROS_FRAMEWORK")
    if (env != "" && FileExist(env "\DeepMacros.ahk"))
        return DM_FrameworkRoot := env

    dir := A_ScriptDir
    loop 8 {
        candidate := dir "\Framework"
        if FileExist(candidate "\DeepMacros.ahk")
            return DM_FrameworkRoot := candidate
        parent := DM_Utils_PathParent(dir)
        if (parent = "" || parent = dir)
            break
        dir := parent
    }

    remoteCache := DM_Utils_PathParent(DM_Utils_PathParent(A_LineFile)) "\.remote"
    if FileExist(remoteCache "\DeepMacros.ahk")
        return DM_FrameworkRoot := remoteCache

    installed := A_LocalAppData "\Deep-Macros\Framework"
    if FileExist(installed "\DeepMacros.ahk")
        return DM_FrameworkRoot := installed

    throw Error(
        "Deep-Macros Framework no encontrado.`n"
        "Usa #Include ..\Framework\HttpBoot.ahk (descarga HTTPS + Reload)`n"
        "O define DEEP_MACROS_FRAMEWORK=ruta\al\Framework",
        -1
    )
}

DM_FrameworkVersion() {
    root := DM_GetFrameworkRoot()
    return DM_Utils_Ini(root "\version.ini", "Framework", "Version", "0.0.0")
}

DM_IncludeFramework(relativePath := "") {
    root := DM_GetFrameworkRoot()
    if (relativePath = "")
        return root
    target := root "\" relativePath
    if !FileExist(target)
        throw Error("No existe: " target, -1)
    return target
}
