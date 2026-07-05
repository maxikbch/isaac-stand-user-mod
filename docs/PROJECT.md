# JoJo Stand Mods — Documento del proyecto

Documento vivo con la visión, infraestructura y convenciones del monorepo.  
Para instalación rápida ver [README.md](../README.md).

---

## Idea del proyecto

Mod de *The Binding of Isaac: Repentance* inspirado en **JoJo's Bizarre Adventure**.

### Origen

- Base original: mod de **Josuke + Crazy Diamond** (melon / NotYourSagittarius).
- Extensiones previas del autor: variantes con **Jotaro / Star Platinum** y **Kakyoin / Hierophant Green**.
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
- [ ] **Discos de Stand** (estilo Whitesnake) — ítems que intercambian el stand activo
- [ ] **Sala especial** — tipo observatorio de Repentance; discos, flechas, eventos JoJo
- [ ] **Mods de personaje** — Josuke, Jotaro, Kakyoin como content mods separados
- [ ] **Sinergias entre stands** — hooks/eventos cuando conviven varios mods

---

## Estado actual

| Mod | Launcher | Carpeta | Estado |
|-----|----------|---------|--------|
| Framework | **JJBA+ Framework** | `jjbaplus-framework/` | Implementado (API v1) |
| Personajes | **JJBA+ {Nombre}** | `jjbaplus-{slug}/` | Generados con scaffold |

No hay mod jugable “Stand User” en el repo: solo plantillas en `templates/`.

Comportamiento de combate por defecto: **punch flurry de Crazy Diamond** (`idle → rush → attack → return`).

**Dependencias:** solo API vanilla de Repentance. No requiere Repentogon ni otros extenders.

---

## Infraestructura del repo

### Monorepo

```
isaac-stand-user-mod/          ← repo (contenedor, NO es un mod de Isaac)
├── docs/
│   ├── PROJECT.md
│   └── variant_ids.json
├── templates/
│   ├── character-mod/         ← plantilla Lua + XML
│   └── placeholder-assets/    ← sprites/anm2 placeholder
├── jjbaplus-framework/      ← mod instalable (framework)
├── jjbaplus-{personaje}/         ← mods generados (ej. jjbaplus-jotaro)
├── scripts/
│   └── install-mods.ps1
├── install-mods.cmd           ← doble clic
├── create-character.cmd
├── README.md
└── credit.txt
```

Isaac solo carga carpetas **directas** dentro de `mods/`. Cada mod jugable se expone con junction:

```powershell
.\install-mods.cmd
# o: .\scripts\install-mods.ps1
# mods/jjbaplus-framework  →  repo/jjbaplus-framework
# mods/jjbaplus-jotaro           →  repo/jjbaplus-jotaro  (tras scaffold)
```

### Orden de carga

Cada content mod **depende** del framework:

1. `jjbaplus-framework` debe cargar primero (el prefijo alfabético ayuda).
2. Cada `jjbaplus-{personaje}/` llama a `JSF:RegisterStand(...)` al iniciar.

Si el framework no está presente, el content mod aborta con mensaje en consola.

### Entorno de prueba aislado (idea)

Isaac no tiene perfiles de mods. Opciones:

1. Activar framework + al menos un personaje generado.
2. Carpeta `mods-test/` con solo esos mods y script de swap (pendiente).
3. Seed fija para pruebas repetibles.

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
|------|-----------|------------------------------|
| Callbacks del juego | Sí | Solo personaje (stats, costume) |
| FSM combate default | Sí | No (salvo `behaviorModule`) |
| Meter / HUD | Sí | Sprites propios opcionales |
| Save/load (`playerData.JSF`) | Sí | No |
| Swap de discos | Sí | Define el ítem disco |
| Personaje + XML | No | Sí |
| Sprites del stand | No | Sí |
| Super / hooks específicos | Infraestructura | Implementación en hooks |

### Datos del jugador

Namespace único para evitar colisiones entre mods:

```lua
playerData.JSF = {
    activeStandId = "star_platinum",
    activeDiscItem = CollectibleType.X,
    standEntity = Entity,      -- familiar spawneado
    standState = {             -- SuperCharge, SuperDuration, ...
    },
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
| `SwapStandDisc(player, discItemId)` | Cambiar disco (deja el anterior en pedestal). Disparado vía `MC_PRE_PICKUP_COLLISION` al tocar un pickup de disco |
| `EnsureLinkedStandDisc(player)` | Auto-disco si el personaje está en `linkedCharacters` |
| `GetAllStandDefs()` | Lista de stands registrados |

### Schema de `stand_definition.lua`

Ver ejemplo en [`templates/character-mod/stand_definition.lua`](../templates/character-mod/stand_definition.lua).

Campos principales:

```lua
{
    id = "star_platinum",
    discItem = Isaac.GetItemIdByName("Stand"),
    familiarVariant = 13000,
    particleVariant = 13001,
    floatOffset = Vector(0, -36),
    animations = { spIdle = {...}, spMad = {...}, ... },
    stats = { ChargeLength = 7, Punches = 5, ... },
    sounds = { punchlight = ..., ... },
    behaviorModule = nil,       -- nil = default CD del framework
    hooks = {
        getMaxPunches = function(player, standDef) ... end,
        getFinisherDamageMult = function(player, standDef) ... end,
        onSuperStart = function(player, standEntity, standDef) ... end,
        onSuperFinish = function(player, standEntity, standDef) ... end,
    },
    linkedCharacters = { Isaac.GetPlayerTypeByName("StandUser") },
}
```

---

## Convenciones

### Nomenclatura JJBA+

Prefijo de marca visible en el launcher: **`JJBA+`**.

| Capa | Convención | Ejemplo |
|------|------------|---------|
| Nombre en launcher (`metadata.xml`) | `JJBA+ {Nombre}` | `JJBA+ Jotaro` |
| Carpeta del mod | `jjbaplus-{slug}` | `jjbaplus-jotaro` |
| `RegisterMod` (ID Lua estable) | `Maxo13:JJBAPlus_{Nombre}` | `Maxo13:JJBAPlus_Jotaro` |
| Personaje (`players.xml`) | PascalCase, sin espacios | `Jotaro` |
| Stand id (`stand_definition`) | snake_case | `star_platinum` |
| Disco (`items.xml`) | nombre único | `Star Platinum Disc` |
| Gfx namespace | slug del mod | `gfx/jotaro/` |
| Sonidos combate | `{Personaje}_PunchLight` | `Jotaro_PunchLight` |
| Sonidos cry | `{StandPascal}_Cry_Start` | `StarPlatinum_Cry_Start` |

Registro central de variant IDs y mods: [`docs/variant_ids.json`](../variant_ids.json).

### Variant IDs de entidades

Reservar pares consecutivos por stand (asignados automáticamente por el scaffold):

| Stand | Familiar | Partícula |
|-------|----------|-----------|
| *(primer personaje)* | 13000 | 13001 |
| *(segundo)* | 13002 | 13003 |
| *(próximo)* | 13004 | 13005 |

Fórmula: `13000 + 2*n` (familiar) y `+ 1` (partícula).

### Behaviors

**No hay presets** (`melee`, `ranged`, etc.).

- El framework incluye **un solo default**: punch flurry CD.
- Stands futuros con combate distinto:
  - `behaviorModule` propio, **o**
  - copiar/adaptar los behaviors del framework dentro de su mod.

### Nombres de ítems

Usar nombres únicos por stand: `"Star Platinum Disc"`, no `"Stand"` genérico (salvo el stand base de prueba).

### Mod IDs (`RegisterMod`)

| Mod | Launcher | RegisterMod |
|-----|----------|-------------|
| Framework | JJBA+ Framework | `Maxo13:JJBAPlus_Framework` |
| Personajes | JJBA+ {Nombre} | `Maxo13:JJBAPlus_{Nombre}` |

---

## Crear un mod de personaje nuevo

### Script scaffold (recomendado)

```powershell
.\scripts\new-character-mod.ps1 `
  -CharacterName Jotaro `
  -StandName "Star Platinum"
```

Deriva slugs: `jotaro` → carpeta `jjbaplus-jotaro`, `star_platinum` → stand id. Opcional: `-Id`, `-StandId` para override.

Genera `jjbaplus-jotaro/` desde `templates/character-mod/` con:

- `metadata.xml`, `main.lua`, definiciones Lua
- `content/*.xml` (players, items, entities2, costumes, sounds)
- Assets placeholder copiados de `templates/placeholder-assets/` en `content/gfx/{slug}/`
- Variants y registro en `docs/variant_ids.json`
- Junction en `scripts/install-mods.ps1` (vía `scripts/update-install-mods.ps1`; launcher: `install-mods.cmd`)

Editá sprites directamente en `content/gfx/{slug}/` — Isaac no usa carpeta `resources/`.

1. Usar `templates/character-mod/` (vía script scaffold).
2. Registrar el mod en `docs/variant_ids.json`.
3. Ejecutar `.\scripts\update-install-mods.ps1`.

---

## Checklist de prueba manual

- [ ] Solo framework activo → no crashea (sin stands registrados no hay gameplay visible)
- [ ] Framework + personaje generado → disco y familiar visibles
- [ ] Combate: carga → rush → punch flurry
- [ ] Super: meter carga y activa con tecla configurada (`C` / L3)
- [ ] Cambio de sala: fade del stand + persistencia de meter
- [ ] Coop 2 jugadores
- [ ] Swap de disco (cuando haya más de un stand registrado)

---

## Deuda técnica / notas

- Puede quedar código legacy en la raíz del repo (`src/`, `content/` del mod viejo). No debe cargarse como mod; conviene limpiarlo.
- Tainted StandUser comentado en `players.xml`; hooks ya preparados en `stand_definition.lua`.
- Sonidos referenciados en `sounds.xml`; verificar que los `.wav` estén en `content/sounds/{slug}/`.
- Swap de discos usa `MC_PRE_PICKUP_COLLISION` (vanilla). El disco anterior se suelta en el pedestal vacío más cercano o en el suelo.

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
| 2026-07-05 | Split framework + stand-user; API v1; este documento inicial |
| 2026-07-05 | Eliminado mod jugable stand-user; assets en `templates/placeholder-assets/` |
