# DMacros

Unified AutoHotkey v2 macro suite.

## Layout

```
DM/
├── DMacros.ahk          ← run this
└── app/
    ├── Config
    ├── Framework/
    ├── imgs/
    └── Macros/
        └── Automatics/
            └── AutoFlowState.ahk
```

## Usage

1. Run `DMacros.ahk`.
2. Tray → **Open DMacros** to show settings.
3. **Hide** minimizes to tray (script keeps running).
4. **✕** exits AutoHotkey.
5. **Save** writes `app/Config`.

## Config (`app/Config`)

| Section | Keys |
|---------|------|
| `App` | `ShowUIOnStart` (las actualizaciones se comprueban siempre al iniciar) |
| `System` | `ScreenWidth`, `ScreenHeight`, `MouseDpi`, `WinMouseSpeed`, `RobloxSensitivity` |
| `AssassinationDash`, `AutoFlowState`, `MouseButtons` | `Enabled` |
