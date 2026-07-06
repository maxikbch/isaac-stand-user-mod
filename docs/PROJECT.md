# JJBA+ Mods — Documento del proyecto

Documento vivo con la visión, infraestructura y convenciones del monorepo **JJBA+**.  
Para instalación rápida ver [README.md](../README.md).

---

## Idea del proyecto

Mod de *The Binding of Isaac: Repentance* inspirado en **JoJo's Bizarre Adventure**.

### Origen

- Base original: mod monolítico de stand/combate (melon / NotYourSagittarius).
- Extensiones previas del autor: variantes con otros personajes y stands.
- El código original era monolítico y difícil de extender; este repo es la reescritura hacia un **estándar compartido**.

### Visión: “comunión” entre mods JoJo

La meta no es un solo mod gigante, sino un **ecosistema de mods compatibles**:

| Concepto | Descripción |
|----------|-------------|
| **Framework compartido** | Combate, meter, discos, save/load, API común |
| **Un mod por stand/personaje** | Assets + definición + lógica propia cuando haga falta |
| **Interacción cross-mod** | Mecánicas que afecten a todos los stands registrados |

### Mecánicas futuras (roadmap)

- [ ] **Stand Arrow** — otorgar o evolucionar stands en personajes que no lo tengan
- [ ] **Discos de Stand** (estilo Whitesnake) — intercambio de stand activo entre personajes
- [ ] **Sala especial** — tipo observatorio de Repentance; discos, flechas, eventos JoJo
- [ ] **Más personajes** — vía scaffold
- [ ] **Sinergias entre stands** — hooks/eventos cuando conviven varios mods

---

## Estado actual

| Mod | Launcher | Carpeta | Estado |
|-----|----------|---------|--------|
| Framework | **JJBA+ Framework** | `jjbaplus-framework/` | Implementado (API v1) |
| Personajes | **JJBA+ {Nombre}** | `jjbaplus-{slug}/` | Generados con scaffold |

No hay mod jugable “Stand User” en el repo: solo la plantilla en `template/`.

Comportamiento de combate por defecto: **punch flurry de Crazy Diamond** (`idle → rush → attack → return`).

**Dependencias:** solo API vanilla de Repentance.

Registro de mods e IDs: [`docs/variant_ids.json`](variant_ids.json).

---

## Infraestructura del repo

### Monorepo

```
isaac-stand-user-mod/              ← repo contenedor (NO es un mod de Isaac)
├── docs/
│   ├── PROJECT.md                 ← este archivo
│   └── variant_ids.json           ← mods registrados + variant IDs
├── template/                      ← plantilla única para scaffold (Lua, XML, gfx)
├── jjbaplus-framework/            ← mod framework (instalable)
├── jjbaplus-{slug}/               ← mods de personaje (ej. jjbaplus-jotaro)
├── scripts/
│   ├── jjba-config.ps1            ← constantes y helpers
│   ├── jjba.local.ps1             ← opcional: ruta a mods/ de Isaac (gitignored)
│   ├── jjba.local.ps1.example     ← plantilla de config local
│   ├── new-character-mod.ps1      ← scaffold de personajes
│   ├── install-mods.ps1           ← junctions (auto-generado)
│   └── update-install-mods.ps1    ← regenera install-mods.ps1
├── install-mods.cmd               ← launcher: junctions
├── create-character.cmd           ← launcher: scaffold interactivo
├── README.md
└── credit.txt
```

Isaac solo carga carpetas **directas** dentro de `mods/`. Cada mod jugable se expone con junction hacia el repo (que puede vivir fuera de `mods/`):

```powershell
.\install-mods.cmd
# o: .\scripts\install-mods.ps1
```

Si el repo no es hijo directo de `mods/`, copiar `scripts/jjba.local.ps1.example` → `scripts/jjba.local.ps1` y definir `JJBA_IsaacModsPath`.

Ejemplo de junctions:

```
<Isaac>/mods/jjbaplus-framework  →  <repo>/jjbaplus-framework
<Isaac>/mods/jjbaplus-jotaro     →  <repo>/jjbaplus-jotaro
```

### Orden de carga

1. **`jjbaplus-framework`** debe cargar primero (el prefijo alfabético ayuda).
2. Cada **`jjbaplus-{slug}/`** llama a `JSF:RegisterStand(...)` al iniciar.

Si el framework no está presente, el content mod aborta con mensaje en consola.

### Assets: `content/` + `resources/`

Isaac carga **XML y menú** desde `content/`. Los sprites de juego (costumes, stand, retratos de boss/stage, meter HUD) y los **`.wav`** van en **`resources/`**.

| Mod | Dónde editar arte |
|-----|-------------------|
| Framework (meter HUD) | `jjbaplus-framework/resources/gfx/stand_framework/` |
| Personaje (stand, costumes, disco, UI boss/stage) | `jjbaplus-{slug}/resources/gfx/{slug}/` |
| Menú de personaje | `jjbaplus-{slug}/content/gfx/` (charactermenu, portraits, etc.) |
| Sonidos | `jjbaplus-{slug}/resources/sounds/{slug}/` (`.wav` referenciados en `content/sounds.xml`) |

El scaffold copia desde `template/` a `resources/gfx/{slug}/`, `content/gfx/` (menú) y sincroniza el HUD del framework. Los `.anm2` de menú deben usar una animación con el **mismo nombre** que `<player name="...">` en `players.xml` (ej. `"Jotaro"` para el personaje Jotaro).

---

## Scripts

| Archivo | Qué hace |
|---------|----------|
| `install-mods.cmd` | Crea junctions en `mods/` según `variant_ids.json`. |
| `create-character.cmd` | Pide personaje y stand; ejecuta el scaffold. |
| `scripts/new-character-mod.ps1` | Genera `jjbaplus-{slug}/`, registra variants e IDs. |
| `scripts/install-mods.ps1` | Igual que `install-mods.cmd` (auto-generado). |
| `scripts/update-install-mods.ps1` | Regenera `install-mods.ps1` desde `variant_ids.json`. |
| `scripts/setup-framework-assets.ps1` | Sincroniza HUD del framework desde `template/resources/gfx/framework/`. |
| `scripts/jjba-config.ps1` | Helpers compartidos (slugs, namespace, variants, ruta a `mods/`). |
| `scripts/jjba.local.ps1` | Config local: `JJBA_IsaacModsPath` (opcional si el repo está en `mods/`). |

---

## Arquitectura

```mermaid
flowchart TD
    subgraph framework [jjbaplus-framework]
        API["RegisterStand / GetActiveStand"]
        CB[callbacks MC_*]
        DEF[behaviors default CD]
        CORE[set update clear super]
        METER[HUD meter]
    end

    subgraph content [jjbaplus-jotaro u otros]
        SD[stand_definition.lua]
        CHAR[character_callbacks.lua]
        XML[content XML + gfx]
    end

    SD -->|RegisterStand| API
    CHAR -->|stats / costumes| content
    CB --> CORE
    CORE --> DEF
    API --> CORE
```

### Responsabilidades

| Capa | Framework | Content mod (personaje) |
|------|-----------|-------------------------|
| Callbacks del juego | Sí | Solo personaje (stats, costume) |
| FSM combate default | Sí | No (salvo `behaviorModule`) |
| Meter / HUD | Sí (`resources/gfx/stand_framework/`) | Sprites propios opcionales en `resources/gfx/` |
| Save/load (`playerData.JSF`) | Sí | No |
| Swap de discos | Sí | Define el ítem disco en `items.xml` |
| Personaje + XML | No | Sí (`content/`) |
| Sprites del stand | No | Sí (`resources/gfx/{slug}/`) |
| Super / hooks específicos | Infraestructura | Implementación en hooks |

### Datos del jugador

Namespace único para evitar colisiones entre mods:

```lua
playerData.JSF = {
    activeStandId = "star_platinum",
    activeDiscItem = CollectibleType.X,
    standEntity = Entity,
    standState = { SuperCharge = 0, ... },
}
```

---

## API v1 — `_G.JoJoStandFramework`

Expuesta al cargar el framework. Versión: `JSF.API_VERSION = 1`.

| Método | Uso |
|--------|-----|
| `RegisterStand(def)` | Registra un stand (content mods) |
| `GetStand(id)` | Definición por id |
| `GetActiveStand(player)` | Stand activo según disco en inventario |
| `GetActiveStandId(player)` | Id del stand activo |
| `IsRegisteredDisc(collectibleId)` | ¿Es un disco registrado? |
| `GetPlayerData(player)` | Tabla `playerData.JSF` |
| `SetActiveStand(player, standId)` | Asignar stand |
| `SwapStandDisc(player, discItemId)` | Cambiar disco (`MC_PRE_PICKUP_COLLISION`) |
| `EnsureLinkedStandDisc(player)` | Auto-disco si el personaje está en `linkedCharacters` |
| `GetAllStandDefs()` | Lista de stands registrados |

### Schema de `stand_definition.lua`

Ver ejemplo en [`template/mod/stand_definition.lua`](../template/mod/stand_definition.lua).

```lua
{
    id = "star_platinum",
    discItem = Isaac.GetItemIdByName("Star Platinum Disc"),
    standIndex = 0,
    entities = {
        stand = {
            name = "Star Platinum",
            type = 3,
            modVariant = 0,
        },
        particle = {
            name = "Star Platinum Particle",
            type = 1000,
            modVariant = 1,
        },
    },
    floatOffset = Vector(0, -36),
    animations = { spIdle = {...}, spMad = {...}, ... },
    stats = { ChargeLength = 7, Punches = 5, ... },
    sounds = { punchlight = ..., ... },
    behaviorModule = nil,
    hooks = {
        getMaxPunches = function(player, standDef) ... end,
        getFinisherDamageMult = function(player, standDef) ... end,
    },
    linkedCharacters = { Isaac.GetPlayerTypeByName("Jotaro") },
}
```

---

## Convenciones

### Nomenclatura JJBA+

El **`+`** solo aparece en el nombre visible del launcher. Carpetas e ids Lua evitan símbolos especiales.

| Capa | Convención | Ejemplo |
|------|------------|---------|
| Nombre en launcher | `JJBA+ {Nombre}` | `JJBA+ Jotaro` |
| Carpeta del mod | `jjbaplus-{slug}` | `jjbaplus-jotaro` |
| `metadata.xml` `<directory>` | guiones → `_` | `jjbaplus_jotaro` |
| `RegisterMod` | `Maxo13:JJBAPlus_{Nombre}` | `Maxo13:JJBAPlus_Jotaro` |
| Personaje (`players.xml`) | PascalCase | `Jotaro` |
| Stand id | snake_case (auto desde nombre) | `star_platinum` |
| Mod slug | lowercase (auto desde personaje) | `jotaro` |
| Disco (`items.xml`) | nombre único | `Star Platinum Disc` |
| Gfx en disco | `resources/gfx/{slug}/` | `resources/gfx/jotaro/stand.anm2` |
| Sonidos combate | `{Personaje}_PunchLight` | `Jotaro_PunchLight` |
| Sonidos cry | `{StandPascal}_Cry_Start` | `StarPlatinum_Cry_Start` |

### Entity IDs (stands y VFX)

Fuente de verdad: `variant_ids.json`. El framework resuelve IDs al registrar el stand.

| Campo | Rol | Ejemplo |
|-------|-----|---------|
| `modTag` | Bloque del pack (global) | `13` → rango `1300–1399` |
| `modVariant` | Slot de entidad dentro del pack | `0` stand, `1` partícula |
| `standIndex` | Stand/personaje → `SubType` en Isaac | `0` Jotaro, `-1` UI Debug (`255`) |
| `type` | Clase de entidad (`entities2.xml`) | `3` familiar, `1000` effect |

**Fórmulas:**

- `variant = modTag * 100 + modVariant` (máx. Isaac: `4095`)
- `subtype = standIndex` para personajes (`0..254`); `standIndex = -1` → `subtype 255` (slot debug)

**Spawn runtime:** `(type, variant, subtype)`  
**Match/clear en framework:** `(variant, subtype)`

| Personaje | standIndex | Stand (type, variant, subtype) | Partícula |
|-----------|------------|--------------------------------|-----------|
| Jotaro | `0` | `(3, 1300, 0)` | `(1000, 1301, 0)` |
| UI Debug | `-1` | `(3, 1300, 255)` | `(1000, 1301, 255)` |
| n.º | `0..254` | `(3, 1300, n)` | `(1000, 1301, n)` |

`modVariant` `2+` queda reservado para entidades extra del stand. `entities2.xml` debe usar **`version="5"`** (Repentance+).

### Behaviors

- El framework incluye **un solo default**: punch flurry CD.
- Combate distinto: `behaviorModule` propio o behaviors copiados/adaptados en el mod del personaje.

### Nombres de ítems

Cada stand usa un disco con **nombre único** en `items.xml` (ej. `"Star Platinum Disc"`). No reutilizar el mismo nombre entre mods.

---

## Crear un mod de personaje nuevo

### Scaffold (recomendado)

Doble clic:

```powershell
.\create-character.cmd
```

O desde consola:

```powershell
.\scripts\new-character-mod.ps1 `
  -CharacterName Jotaro `
  -StandName "Star Platinum"
```

**Slugs automáticos:** `Jotaro` → `jotaro`, `"Star Platinum"` → `star_platinum`.  
Overrides opcionales: `-Id`, `-StandId`, `-DiscName`, `-DiscDescription`.

**Genera:**

- Carpeta `jjbaplus-jotaro/`
- Lua + XML + assets desde `template/`
- Placeholders en `resources/gfx/jotaro/` y menú en `content/gfx/`
- Entrada en `docs/variant_ids.json`
- Actualiza `scripts/install-mods.ps1`

**Después:**

1. `.\install-mods.cmd`
2. Activar **JJBA+ Framework** + personaje en Isaac
3. Reemplazar arte en `resources/gfx/{slug}/`
4. Ajustar `stand_stats.lua` y hooks si hace falta

### Manual (alternativa)

1. Copiar/adaptar `template/`.
2. Reservar variant IDs en `variant_ids.json`.
3. `.\scripts\update-install-mods.ps1` → `.\install-mods.cmd`.

---

## Estructura de un mod de personaje

```
jjbaplus-jotaro/
├── content/
│   ├── gfx/
│   │   ├── charactermenu.anm2   ← menú / portraits (raíz gfx/)
│   │   └── ...
│   ├── players.xml
│   ├── items.xml
│   ├── entities2.xml
│   ├── costumes2.xml
│   └── sounds.xml
├── resources/
│   ├── gfx/
│   │   └── jotaro/              ← stand, costumes, disco, UI boss/stage
│   └── sounds/
│       └── jotaro/              ← .wav referenciados en sounds.xml
├── main.lua
├── stand_definition.lua
├── stand_stats.lua
├── character_definition.lua
├── character_callbacks.lua
├── settings.lua
└── metadata.xml
```

---

## Checklist de prueba manual

- [ ] Solo framework activo → no crashea
- [ ] Framework + personaje → disco y familiar visibles
- [ ] Combate: carga → rush → punch flurry
- [ ] Super: meter carga y activa (`C` / L3)
- [ ] Cambio de sala: fade del stand + meter persistente
- [ ] Coop 2 jugadores
- [ ] Swap de disco (con más de un stand registrado)

---

## Deuda técnica / notas

- Puede quedar código legacy en la raíz del repo (`src/`, `content/`). **No activar** `isaac-stand-user-mod` como mod en Isaac.
- Sonidos en `content/sounds.xml` requieren `.wav` en `resources/sounds/{slug}/`. El scaffold copia placeholders desde `template/resources/sounds/character/`.
- Swap de discos: `MC_PRE_PICKUP_COLLISION` (vanilla); disco anterior va al pedestal vacío más cercano o al suelo.
- Debug del framework: `jjbaplus-framework/settings.lua` → `DebugStand = true` (overlay `[JSF]` en pantalla).

---

## Créditos

| Rol | Persona |
|-----|---------|
| Diseño / código original (CD) | melon |
| Arte original | NotYourSagittarius |
| API / refactor framework | Maxo13 |

Ver [credit.txt](../credit.txt).

---

## Changelog del documento

| Fecha | Notas |
|-------|-------|
| 2026-07-05 | Documento inicial; split framework + stand-user; API v1 |
| 2026-07-05 | Marca JJBA+; scaffold; `variant_ids.json`; sin mod Stand User jugable |
| 2026-07-05 | Carpetas `jjbaplus-*`; `RegisterMod` `Maxo13:JJBAPlus_*`; solo `content/` (sin sync) |
| 2026-07-05 | Slugs auto; scripts `.cmd`; fix spawn stand (`ForAllPlayers`, entities2 v5) |
| 2026-07-05 | Assets en `resources/`; plantilla unificada en `template/` |
