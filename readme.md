# JJBA+ Mods (Monorepo)

Monorepo con mods separados para *The Binding of Isaac: Repentance*, familia **JJBA+**.

| Launcher | Carpeta | Descripción |
|----------|---------|-------------|
| **JJBA+ Framework** | `jjbaplus-framework/` | API, combate, meter, discos, save/load |

Los personajes son mods separados generados con el scaffold (no hay mod “Stand User” jugable en el repo).

Documentación: [docs/PROJECT.md](docs/PROJECT.md) · Registro de IDs: [docs/variant_ids.json](docs/variant_ids.json)

## Instalación

```powershell
.\install-mods.cmd
```

O desde consola: `.\scripts\install-mods.ps1`

Activa **JJBA+ Framework** y los personajes que hayas generado.

## Crear un personaje

```powershell
.\create-character.cmd
```

O: `.\scripts\new-character-mod.ps1 -CharacterName Jotaro -StandName "Star Platinum"`

Ids derivados automáticamente: `jotaro`, `star_platinum`. Overrides opcionales: `-Id`, `-StandId`.

Genera `jjbaplus-jotaro/` con nomenclatura, IDs, XML, Lua y assets placeholder en `content/`. Después:

1. `.\install-mods.cmd`
2. Reemplazá arte en `content/gfx/<id>/` (sprites, anm2, etc.)
3. Ajustá `stand_stats.lua` / hooks si hace falta

Plantillas: `templates/character-mod/` · Assets placeholder: `templates/placeholder-assets/`

## Nomenclatura JJBA+

| Capa | Ejemplo |
|------|---------|
| Nombre en launcher | `JJBA+ Jotaro` |
| Carpeta en disco | `jjbaplus-jotaro` (framework: `jjbaplus-framework`) |
| `RegisterMod` | `Maxo13:JJBAPlus_Jotaro` |
| Stand id (Lua) | `star_platinum` |
| Gfx namespace / carpeta de arte | `content/gfx/jotaro/` |

El `+` solo aparece en el nombre visible del launcher; carpetas usan `jjbaplus-` e ids Lua `Maxo13:JJBAPlus_*`.

Variant IDs: [docs/variant_ids.json](docs/variant_ids.json) (primer personaje: `13000` / `13001`).

## API v1 (`_G.JoJoStandFramework`)

```lua
local JSF = _G.JoJoStandFramework
JSF:RegisterStand(require("stand_definition"))
```

Referencia de definición: `templates/character-mod/stand_definition.lua`

## Scripts

### Launchers (doble clic)

| Archivo | Qué hace |
|---------|----------|
| `install-mods.cmd` | Crea junctions en la carpeta `mods/` de Isaac para cada mod listado en `docs/variant_ids.json`. |
| `create-character.cmd` | Pide nombre de personaje y stand; ejecuta el scaffold y registra el mod nuevo. |

### PowerShell (`scripts/`)

| Script | Qué hace |
|--------|----------|
| `install-mods.ps1` | Mismo que `install-mods.cmd`. Auto-generado por `update-install-mods.ps1`. |
| `new-character-mod.ps1` | Crea un mod de personaje desde plantillas: carpeta `jjbaplus-{slug}`, Lua/XML, variant IDs, assets placeholder en `content/` y entrada en `variant_ids.json`. |
| `update-install-mods.ps1` | Regenera `scripts/install-mods.ps1` a partir de `docs/variant_ids.json`. Lo llama `new-character-mod.ps1` al crear un personaje. |
| `jjba-config.ps1` | Constantes y helpers compartidos (prefijo JJBA+, slugs, variant IDs). No se ejecuta solo; lo importan los otros scripts. |

## Créditos

Ver [credit.txt](credit.txt).
