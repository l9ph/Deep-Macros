; Cliente HTTPS — sincroniza DMacros completo desde GitHub (árbol del repo + raw/API).
class DM_Http {
    static _cfg := 0

    static _Config() {
        if !IsObject(DM_Http._cfg) {
            DM_Http._cfg := Map(
                "Repo", DM_Bootstrap_Ini("App", "Repo", "l9ph/Deep-Macros"),
                "Branch", DM_Bootstrap_Ini("App", "Branch", "main"),
                "RawBase", DM_Bootstrap_Ini("App", "RawBase",
                    "https://raw.githubusercontent.com/l9ph/Deep-Macros/main")
            )
        }
        return DM_Http._cfg
    }

    static Repo() => DM_Http._Config()["Repo"]
    static Branch() => DM_Http._Config()["Branch"]
    static RawBase() => RTrim(DM_Http._Config()["RawBase"], "/")

    static StateFile() => DM_Bootstrap_CacheDir() "\.sync-state.ini"

    static Token() {
        for name in ["DM_GH_TOKEN", "DEEP_MACROS_GH_TOKEN", "GITHUB_TOKEN"] {
            t := EnvGet(name)
            if (t != "")
                return t
        }
        return ""
    }

    static HasAuth() => DM_Http.Token() != ""

    static ApiHeaders(json := true) {
        hdrs := "User-Agent: DMacros-AHK/1.0"
        if (json)
            hdrs .= "`nAccept: application/vnd.github+json"
        if DM_Http.HasAuth()
            hdrs .= "`nAuthorization: Bearer " DM_Http.Token()
        return hdrs
    }

    static ApiContentsUrl(repoPath) {
        p := StrReplace(repoPath, "\", "/")
        return "https://api.github.com/repos/" DM_Http.Repo() "/contents/" p "?ref=" DM_Http.Branch()
    }

    static RawUrl(repoPath) => DM_Http.RawBase() "/" StrReplace(repoPath, "\", "/")

    static FetchRemoteAppVersion() {
        try {
            body := DM_Http.GetText(DM_Http.RawUrl("app/version.ini"))
            if RegExMatch(body, "Version=([^\r\n]+)", &m)
                return Trim(m[1])
        } catch {
            if !DM_Http.HasAuth()
                return "0.0.0"
            try {
                body := DM_Http.GetText(DM_Http.ApiContentsUrl("app/version.ini"),
                    "Accept: application/vnd.github.raw`nAuthorization: Bearer " DM_Http.Token())
                if RegExMatch(body, "Version=([^\r\n]+)", &m)
                    return Trim(m[1])
            }
        }
        return "0.0.0"
    }

    static FetchRemoteFileList() {
        try
            return DM_Http._FetchTreeFromApi()
        catch {
            return DM_Http._LoadFallbackManifest()
        }
    }

    static _FetchTreeFromApi() {
        url := "https://api.github.com/repos/" DM_Http.Repo() "/git/trees/"
            . DM_Http.Branch() "?recursive=1"
        json := DM_Http.GetText(url, DM_Http.ApiHeaders(true))
        files := []
        pos := 1
        while RegExMatch(json, '"path"\s*:\s*"([^"]+)"', &m, pos) {
            path := m[1]
            pos := m.Pos + m.Len
            snippet := SubStr(json, pos, 160)
            if !RegExMatch(snippet, '"type"\s*:\s*"blob"')
                continue
            if !DM_Bootstrap_ShouldSyncPath(path)
                continue
            files.Push(path)
        }
        if !files.Length
            throw Error("El árbol remoto no devolvió archivos sincronizables.", -1)
        return files
    }

    static _LoadFallbackManifest() {
        paths := []
        install := DM_Bootstrap_InstallRoot()
        for candidate in [
            install "\app\Sync\fallback-manifest.txt",
            install "\app\Framework\Sync\fallback-manifest.txt",
            install "\app\Framework\Sync\manifest.txt",
            A_ScriptDir "\..\..\..\app\Sync\fallback-manifest.txt",
            A_ScriptDir "\..\Sync\fallback-manifest.txt"
        ] {
            if !FileExist(candidate)
                continue
            for line in StrSplit(FileRead(candidate), "`n", "`r") {
                rel := Trim(StrReplace(line, "/", "\"))
                if (rel = "" || SubStr(rel, 1, 1) = ";")
                    continue
                if DM_Bootstrap_ShouldSyncPath(rel)
                    paths.Push(StrReplace(rel, "\", "/"))
            }
            if paths.Length
                return paths
        }
        throw Error("No se pudo obtener el listado remoto (API) ni leer fallback-manifest.", -1)
    }

    static SyncInstall(installRoot, remoteVer := "", progressUi := "") {
        if (remoteVer = "")
            remoteVer := DM_Http.FetchRemoteAppVersion()
        files := DM_Http.FetchRemoteFileList()
        work := []
        for repoPath in files {
            if !DM_Bootstrap_ShouldSyncPath(repoPath)
                continue
            dest := installRoot "\" StrReplace(repoPath, "/", "\")
            if DM_Bootstrap_IsProtectedDest(dest, installRoot)
                continue
            work.Push(repoPath)
        }
        total := work.Length
        ok := 0
        fail := 0
        skip := files.Length - total
        done := 0
        if IsObject(progressUi)
            DM_Bootstrap_ProgressSet(progressUi, 0, total, DM_Bootstrap_MsgUpdate())
        for repoPath in work {
            dest := installRoot "\" StrReplace(repoPath, "/", "\")
            DM_Utils_EnsureDir(DM_Utils_PathParent(dest))
            try {
                DM_Http.DownloadRepoFile(repoPath, dest)
                ok++
            } catch {
                fail++
            }
            done++
            if IsObject(progressUi)
                DM_Bootstrap_ProgressSet(progressUi, done, total, DM_Bootstrap_MsgUpdate())
        }
        state := DM_Http.StateFile()
        DM_Utils_EnsureDir(DM_Utils_PathParent(state))
        DM_Utils_IniWrite(state, "Sync", "Version", remoteVer)
        DM_Utils_IniWrite(state, "Sync", "LastSync", FormatTime(, "yyyy-MM-dd HH:mm:ss"))
        DM_Utils_IniWrite(state, "Sync", "Ok", ok)
        DM_Utils_IniWrite(state, "Sync", "Fail", fail)
        DM_Utils_IniWrite(state, "Sync", "Skip", skip)
        DM_Utils_IniWrite(state, "Sync", "Dest", installRoot)
        DM_Utils_IniWrite(state, "Sync", "Files", files.Length)
        return Map(
            "ok", ok,
            "fail", fail,
            "skip", skip,
            "version", remoteVer,
            "files", files.Length,
            "success", fail = 0
                && FileExist(installRoot "\DMacros.ahk")
                && FileExist(installRoot "\app\Framework\DeepMacros.ahk")
        )
    }

    static GetText(url, headers := "") {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        try req.SetTimeouts(8000, 8000, 30000, 30000)
        req.Open("GET", url, false)
        if (headers != "")
            DM_Http._ApplyHeaders(req, headers)
        else
            req.SetRequestHeader("User-Agent", "DMacros-AHK/1.0")
        req.Send()
        if (req.Status != 200)
            throw Error("HTTP " req.Status " — " url, -1)
        return req.ResponseText
    }

    static DownloadRepoFile(repoPath, dest) {
        url := DM_Http.RawUrl(repoPath)
        try {
            Download url, dest
            return
        } catch {
            if !DM_Http.HasAuth()
                throw
        }
        apiUrl := DM_Http.ApiContentsUrl(repoPath)
        hdrs := "Accept: application/vnd.github.raw`nAuthorization: Bearer " DM_Http.Token()
        if DM_Http._IsBinaryPath(dest)
            DM_Http._DownloadApiBinary(apiUrl, hdrs, dest)
        else
            DM_Http._DownloadApiText(apiUrl, hdrs, dest)
    }

    static _IsBinaryPath(path) {
        if !RegExMatch(path, "i)\.([a-z0-9]+)$", &m)
            return false
        ext := m[1]
        return ext = "dll" || ext = "png" || ext = "ico" || ext = "jpg"
    }

    static _DownloadApiText(url, headers, dest) {
        body := DM_Http.GetText(url, headers)
        f := FileOpen(dest, "w", "UTF-8")
        f.Write(body)
        f.Close()
    }

    static _DownloadApiBinary(url, headers, dest) {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        try req.SetTimeouts(8000, 8000, 45000, 45000)
        req.Open("GET", url, false)
        DM_Http._ApplyHeaders(req, headers)
        req.Send()
        if (req.Status != 200)
            throw Error("HTTP " req.Status " — " url, -1)
        stream := ComObject("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(req.ResponseBody)
        stream.SaveToFile(dest, 2)
        stream.Close()
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
}
