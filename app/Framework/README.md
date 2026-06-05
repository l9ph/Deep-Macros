# Framework

UI compartida para **Deep-Macros** (una sola copia en la raíz del repo).

```
DM/
├── DeepMacros.ahk
├── Framework/     ← aquí
├── Macros/
└── Config
```

## Uso

```ahk
#Include Framework\DeepMacros.ahk
```

## API

- `Rayfield.CreateWindow` — UI WebView2 (Rayfield)
- `DM_ConfigApp` — UI nativa clásica
- `DM_Toast`, `DM_Alert`, `DM_TrayRegister`
