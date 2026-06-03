# Deep-Macros

Macros **AutoHotkey v2**. Cada macro lleva su propia copia de `Framework/`.

## Estructura

```
NombreCarpeta/
├── Framework/              UI compartida (local)
├── NombreSimplificado_Macro.ahk
├── Config
└── imgs/
```

| Carpeta | Macro |
|---------|-------|
| Assasination Dash | `AssasinationDash_Macro.ahk` |
| Auto Math | `AutoMath_Macro.ahk` |
| Mouse Buttons | `MouseButtons_Macro.ahk` |

```ahk
#Include Framework\DeepMacros.ahk
```

`Config` = INI. Imágenes en `imgs/`.
