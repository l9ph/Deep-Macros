# Framework DMacros

El **bootstrap** se ejecuta siempre al abrir `DMacros.ahk`:

1. Comprueba si hay versión nueva en GitHub (`app/version.ini`).
2. Si no hay cambios, abre el programa al instante.
3. Si hay actualización, muestra una pantalla de carga (logo, barra de progreso) y descarga todo. **No toca `app/Config`.**
4. Al terminar: *«Actualizado. Reinicia DMacros por favor.»* y cierra el script.

## Desarrollo

Para saltar la comprobación al probar:

```text
set DM_SKIP_BOOTSTRAP=1
```

## Repo privado

`DM_GH_TOKEN`, `DEEP_MACROS_GH_TOKEN` o `GITHUB_TOKEN`

## Actualización manual

```powershell
.\app\Framework\Sync\Install-Framework.ps1
```
