# Deep-Macros Framework — carga por HTTPS

Las macros **no llevan el framework completo**: al arrancar hacen **peticiones HTTPS** a GitHub, guardan una copia en caché y la cargan. Sensación de app sin `.exe`.

**Origen remoto:** `https://raw.githubusercontent.com/l9ph/Deep-Macros/main/Framework/`

---

## En cada macro (solo esto)

```ahk
#Include ..\Framework\HttpBoot.ahk
```

### Qué pasa al ejecutar

1. `HttpBoot.ahk` (local, pequeño) intenta cargar `Framework\.remote\`
2. Si no existe o la versión remota cambió → **GET HTTPS** de cada archivo del manifiesto
3. Guarda en `Framework\.remote\` (gitignored)
4. `Reload` → carga `DeepMacros.ahk` desde la caché
5. Siguientes ejecuciones: usa caché si `version.ini` remoto coincide (sin red, más rápido)

**Ctrl+Shift+F** (en Assasination Dash): fuerza re-descarga y `Reload`.

---

## Por qué no es `#Include` directo a una URL

AutoHotkey v2 **no puede** incluir scripts desde internet en tiempo de compilación. El flujo correcto es:

```
HTTPS GET → disco (.remote) → #Include → tu macro
```

Eso es lo que hace `DM_Http` con WinHTTP (mismo motor que usa el sistema).

---

## API HTTP

| Función | Uso |
|---------|-----|
| `DM_Http.Ensure()` | Descarga si hace falta |
| `DM_Http.Ensure(true)` | Fuerza actualización |
| `DM_Http.Get(url)` | GET texto |
| `DM_Http.Download(url, dest)` | GET archivo |
| `DM_Http.PostJson(url, map)` | POST JSON (config a tu API) |
| `DM_Http.PushMacroConfig(id, configPath, endpoint)` | Envía Config al servidor |

Ejemplo enviar config a tu backend:

```ahk
DM_Http.PushMacroConfig("assasination-dash", configPath, "https://tu-api.com/macro-config")
```

---

## Sin internet / repo aún no en GitHub

Si falla HTTPS pero tienes el repo local, `SeedFromLocal()` copia `Framework/` → `.remote/` automáticamente.

---

## Estructura

```
Framework/
├── HttpBoot.ahk       ← único include en macros
├── Http.ahk           ← cliente HTTPS
├── DeepMacros.ahk     ← entrada del framework (en .remote tras sync)
├── .remote/           ← caché descargada (no subir a git)
└── Demo/DemoApp.ahk
```

---

## Demo

```powershell
& "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey.exe" "Framework\Demo\DemoApp.ahk"
```

Primera ejecución: parpadeo por `Reload` (normal).
