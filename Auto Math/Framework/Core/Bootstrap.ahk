; Resuelve la ruta del Framework (carpeta Framework junto a la macro)
global DM_FrameworkRoot := ""

DM_GetFrameworkRoot() {
    global DM_FrameworkRoot
    if (DM_FrameworkRoot != "" && DirExist(DM_FrameworkRoot))
        return DM_FrameworkRoot

    env := EnvGet("DEEP_MACROS_FRAMEWORK")
    if (env != "" && FileExist(env "\DeepMacros.ahk"))
        return DM_FrameworkRoot := env

    dir := A_ScriptDir
    loop 6 {
        candidate := dir "\Framework"
        if FileExist(candidate "\DeepMacros.ahk")
            return DM_FrameworkRoot := candidate
        parent := DM_Utils_PathParent(dir)
        if (parent = "" || parent = dir)
            break
        dir := parent
    }

    throw Error(
        "Framework no encontrado. Copia la carpeta Framework junto a la macro.`n"
        "Include: #Include Framework\DeepMacros.ahk",
        -1
    )
}

DM_FrameworkVersion() {
    root := DM_GetFrameworkRoot()
    return DM_Utils_Ini(root "\version.ini", "Framework", "Version", "0.0.0")
}
