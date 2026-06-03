; Cliente HTTPS — descarga el Framework desde GitHub (raw + API)
class DM_Http {
    static Repo := "l9ph/Deep-Macros"
    static Branch := "main"
    static RawBase := "https://raw.githubusercontent.com/l9ph/Deep-Macros/main/Framework"
    static ApiBase := "https://api.github.com/repos/l9ph/Deep-Macros/contents/Framework"

    static ManifestRemote := [
        "DeepMacros.ahk",
        "version.ini",
        "Core\Utils.ahk",
        "Core\Theme.ahk",
        "Core\Bootstrap.ahk",
        "Core\Http.ahk",
        "UI\AppWindow.ahk",
        "UI\Components.ahk",
        "UI\Dialogs.ahk"
    ]

    static FrameworkRoot() => DM_Utils_PathParent(DM_Utils_PathParent(A_LineFile))
    static CacheDir() => DM_Http.FrameworkRoot() "\.remote"
    static StateFile() => DM_Http.CacheDir() "\.http-state.ini"

    static Ensure(force := false) {
        global DM_FW_LOADED
        if (DM_FW_LOADED && !force)
            return true

        cache := DM_Http.CacheDir()
        DM_Utils_EnsureDir(cache)
        DM_Utils_EnsureDir(cache "\Core")
        DM_Utils_EnsureDir(cache "\UI")
        entry := cache "\DeepMacros.ahk"

        remoteVer := DM_Http.FetchRemoteVersion()
        localVer := DM_Utils_Ini(DM_Http.StateFile(), "Sync", "Version", "")

        if (!force && FileExist(entry) && localVer != "" && localVer = remoteVer)
            return DM_Http._MarkLoaded(cache)

        ok := DM_Http.SyncAll(cache, remoteVer)
        if (!ok && !DM_Http.SeedFromLocal(cache))
            throw Error("No se pudo descargar el Framework por HTTPS ni copiar local.", -1)
        return DM_Http._MarkLoaded(cache)
    }

    static SeedFromLocal(cache) {
        localRoot := DM_Http.FrameworkRoot()
        if !FileExist(localRoot "\DeepMacros.ahk")
            return false
        for rel in DM_Http.ManifestRemote {
            src := localRoot "\" rel
            if !FileExist(src)
                continue
            dest := cache "\" rel
            DM_Utils_EnsureDir(DM_Utils_PathParent(dest))
            try FileCopy(src, dest, true)
        }
        return FileExist(cache "\DeepMacros.ahk")
    }

    static _MarkLoaded(cache) {
        global DM_FW_LOADED, DM_FrameworkRoot
        DM_FW_LOADED := true
        DM_FrameworkRoot := cache
        return true
    }

    static FetchRemoteVersion() {
        try {
            body := DM_Http.Get(DM_Http.RawBase "/version.ini")
            if RegExMatch(body, "Version=([^\r\n]+)", &m)
                return Trim(m[1])
        } catch {
        }
        return "0.0.0"
    }

    static SyncAll(cache, remoteVer) {
        ok := 0
        fail := 0
        for rel in DM_Http.ManifestRemote {
            url := DM_Http.RawBase "/" StrReplace(rel, "\", "/")
            dest := cache "\" rel
            DM_Utils_EnsureDir(DM_Utils_PathParent(dest))
            try {
                DM_Http.Download(url, dest)
                ok++
            } catch {
                fail++
            }
        }
        DM_Utils_IniWrite(DM_Http.StateFile(), "Sync", "Version", remoteVer)
        DM_Utils_IniWrite(DM_Http.StateFile(), "Sync", "LastSync", FormatTime(, "yyyy-MM-dd HH:mm:ss"))
        DM_Utils_IniWrite(DM_Http.StateFile(), "Sync", "Ok", ok)
        DM_Utils_IniWrite(DM_Http.StateFile(), "Sync", "Fail", fail)
        return fail = 0 && FileExist(cache "\DeepMacros.ahk")
    }

    static Get(url, headers := "") {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        try req.SetTimeouts(4000, 4000, 8000, 8000)
        req.Open("GET", url, false)
        req.SetRequestHeader("User-Agent", "Deep-Macros-AHK/1.0")
        if (headers != "")
            DM_Http._ApplyHeaders(req, headers)
        req.Send()
        if (req.Status != 200)
            throw Error("HTTP " req.Status " — " url, -1)
        return req.ResponseText
    }

    static PostJson(url, obj, extraHeaders := "") {
        body := DM_Http._ToJson(obj)
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("POST", url, false)
        req.SetRequestHeader("Content-Type", "application/json")
        req.SetRequestHeader("User-Agent", "Deep-Macros-AHK/1.0")
        if (extraHeaders != "")
            DM_Http._ApplyHeaders(req, extraHeaders)
        req.Send(body)
        if (req.Status < 200 || req.Status >= 300)
            throw Error("HTTP POST " req.Status " — " url, -1)
        return req.ResponseText
    }

    static Download(url, dest) {
        body := DM_Http.Get(url)
        f := FileOpen(dest, "w", "UTF-8")
        f.Write(body)
        f.Close()
    }

    static FetchManifestFromApi() {
        json := DM_Http.Get(DM_Http.ApiBase "?ref=" DM_Http.Branch,
            "Accept: application/vnd.github+json")
        files := []
        if RegExMatch(json, '"name":\s*"([^"]+\.ahk)"', &m) {
            ; API devuelve árbol plano solo en raíz; usamos lista fija + versión
        }
        return files
    }

    static PushMacroConfig(macroId, configPath, endpoint := "") {
        if (endpoint = "")
            return false
        data := Map(
            "macroId", macroId,
            "version", DM_FrameworkVersion(),
            "config", FileRead(configPath),
            "sentAt", FormatTime(, "yyyy-MM-dd HH:mm:ss")
        )
        DM_Http.PostJson(endpoint, data)
        return true
    }

    static _ApplyHeaders(req, headers) {
        for line in StrSplit(headers, "`n", "`r") {
            line := Trim(line)
            if (line = "" || !InStr(line, ":"))
                continue
            parts := StrSplit(line, ":", , 2)
            req.SetRequestHeader(Trim(parts[1]), Trim(parts[2]))
        }
    }

    static _ToJson(obj) {
        if (Type(obj) = "Map") {
            pairs := []
            for k, v in obj
                pairs.Push('"' DM_Http._EscapeStr(k) '":' DM_Http._ValJson(v))
            return "{" StrJoin(pairs, ",") "}"
        }
        return '""'
    }

    static _ValJson(v) {
        if (Type(v) = "String")
            return '"' DM_Http._EscapeStr(v) '"'
        if (Type(v) = "Float" || Type(v) = "Integer")
            return v
        if (Type(v) = "Map")
            return DM_Http._ToJson(v)
        return '""'
    }

    static _EscapeStr(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        return s
    }
}
