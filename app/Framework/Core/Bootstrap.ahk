global DM_FrameworkRoot := ""

DM_GetFrameworkRoot() {
    global DM_FrameworkRoot, DM_AppRoot
    if (DM_FrameworkRoot != "" && DirExist(DM_FrameworkRoot))
        return DM_FrameworkRoot

    env := EnvGet("DEEP_MACROS_FRAMEWORK")
    if (env != "" && FileExist(env "\DeepMacros.ahk"))
        return DM_FrameworkRoot := env

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

    throw Error("Framework not found. Expected app\Framework under DMacros.ahk.", -1)
}

DM_FrameworkVersion() {
    root := DM_GetFrameworkRoot()
    return DM_Utils_Ini(root "\version.ini", "Framework", "Version", "0.0.0")
}
