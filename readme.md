# JoJo Stand Mods (Monorepo)

Monorepo con mods separados para The Binding of Isaac: Repentance.

| Mod | Carpeta | Descripción |
|-----|---------|-------------|
| **JoJo Stand Framework** | `jojo-stand-framework/` | API, combate, meter, discos, save/load |
| **JoJo Stand User** | `jojo-stand-user/` | Personaje genérico + stand base (punch flurry CD) |

El content mod **requiere** el framework cargado primero. **No requiere Repentogon** — solo API vanilla de Repentance.

Documentación del proyecto (visión, arquitectura, roadmap): [docs/PROJECT.md](docs/PROJECT.md).

## Instalación

Isaac carga cada mod como carpeta directa dentro de `mods/`. Ejecutá desde la raíz del repo:

```powershell
.\install-mods.ps1
```

Eso crea junctions en `mods/jojo-stand-framework` y `mods/jojo-stand-user`. Activá ambos en el launcher.

## Variant IDs reservados

| Stand | Familiar | Partícula |
|-------|----------|-----------|
| generic_stand (Stand User) | 13000 | 13001 |

Convención para futuros stands: par `13000 + n` (par) y `+ 1` (partícula).

## API v1 (`_G.JoJoStandFramework`)

```lua
local JSF = _G.JoJoStandFramework

JSF:RegisterStand(require("stand_definition"))
JSF:GetStand("generic_stand")
JSF:GetActiveStand(player)
JSF:GetActiveStandId(player)
JSF:IsRegisteredDisc(collectibleId)
JSF:GetPlayerData(player)
JSF:SetActiveStand(player, id)
JSF:SwapStandDisc(player, discItemId)
JSF:EnsureLinkedStandDisc(player)
```

Ver `jojo-stand-user/stand_definition.lua` como ejemplo de definición de stand.

## Créditos

Ver [credit.txt](credit.txt).
