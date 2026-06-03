# Framework (local)

UI compartida para macros. Va **dentro de cada carpeta de macro**:

```
Assasination Dash/
├── Framework/          ← esta carpeta
├── AssasinationDash_Macro.ahk
├── Config
└── imgs/
```

## Uso

```ahk
#Include Framework\DeepMacros.ahk
```

## API

- `DM_ConfigApp(...)` — ventana de configuración
- `DM_App(...)`, `DM_Components.*`, `DM_Toast`, `DM_Alert`
