# Plantilla de personaje JJBA+

Usada por `scripts/new-character-mod.ps1` para generar `jjbaplus-{slug}/`.

## Estructura

```
template/
├── *.lua, metadata.xml          → raíz del mod generado (tokens expandidos)
├── content/
│   ├── *.xml                    → content/ del mod (tokens expandidos)
│   └── gfx/                     → menú (content/gfx/); .anm2 con Jotaro
└── resources/
    ├── gfx/
    │   ├── character/           → resources/gfx/{slug}/ (gameplay)
    │   └── framework/           → jjbaplus-framework/resources/gfx/stand_framework/ (HUD)
    └── sounds/
        └── character/           → resources/sounds/{slug}/ (.wav placeholder)
```

Isaac carga gameplay y sonidos desde `resources/` y menú/XML desde `content/`.

Los `.anm2` de menú deben usar una animación llamada igual que `<player name="...">` en `players.xml`.

## Tokens

| Token | Ejemplo |
|-------|---------|
| `JJBA+ Jotaro` | JJBA+ Jotaro |
| `Maxo13:JJBAPlus_Jotaro` | Maxo13:JJBAPlus_Jotaro |
| `Jotaro` | Jotaro |
| `star_platinum` | star_platinum |
| `Star Platinum` | Star Platinum |
| `Star Platinum Disc` | Star Platinum Disc |
| `13000` | 13002 |
| `13001` | 13003 |
| `jotaro` | jotaro |
| `Jotaro` | Jotaro |
| `StarPlatinum` | StarPlatinum |
| `jjbaplus_jotaro` | jjbaplus_jotaro |

Los sonidos placeholder se copian desde `template/resources/sounds/character/` al generar el mod.
