; Utilidades compartidas del framework
DM_Utils_PathParent(dir) {
    SplitPath dir, , &parent
    return parent
}

DM_Utils_EnsureDir(path) {
    if !DirExist(path)
        DirCreate path
    return path
}

DM_Utils_Ini(path, section, key, default := "") {
    if !FileExist(path)
        return default
    try
        return IniRead(path, section, key, default)
    catch
        return default
}

DM_Utils_IniWrite(path, section, key, value) {
    DM_Utils_EnsureDir(DM_Utils_PathParent(path))
    IniWrite value, path, section, key
}

DM_Utils_Clamp(n, min, max) {
    if (n < min)
        return min
    if (n > max)
        return max
    return n
}

DM_Utils_ScaleForDpi(n) {
    dpi := A_ScreenDPI ? A_ScreenDPI : 96
    return Round(n * dpi / 96)
}
