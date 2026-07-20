# Plantilla de personaje JJBA+

Usada por `scripts/new-character-mod.ps1` para generar `jjbaplus-{slug}/`.

## Estructura

```
template/
├── *.lua, metadata.xml          → raíz del mod generado (tokens expandidos)
├── content/
│   ├── *.xml                    → content/ del mod (tokens expandidos)
│   └── gfx/                     → menú (content/gfx/); .anm2 con Kakyoin
└── resources/
    ├── gfx/
    │   ├── character/           → resources/gfx/{slug}/ (gameplay)
    │   └── framework/           → jjbaplus-framework/resources/gfx/stand_framework/ (HUD)
    └── sfx/
        └── character/           → resources/sfx/{slug}/ (.wav placeholder)
```

Isaac carga gameplay y sonidos desde `resources/` y menú/XML desde `content/`.

Los `.anm2` de menú deben usar una animación llamada igual que `<player name="...">` en `players.xml`.

## Tokens

| Token | Ejemplo |
|-------|---------|
| `JJBA+ Kakyoin` | JJBA+ Jotaro |
| `Maxo13:JJBAPlus_Kakyoin` | Maxo13:JJBAPlus_Jotaro |
| `Kakyoin` | Jotaro |
| `hierophant_green` | star_platinum |
| `Hierophant Green` | Star Platinum |
| `Hierophant Green Disc` | Star Platinum Disc |
| `1` | 0 |
| `13` | 13 |
| `1300` | 1300 |
| `1301` | 1301 |
| `kakyoin` | jotaro |
| `Kakyoin` | Jotaro |
| `HierophantGreen` | StarPlatinum |
| `jjbaplus_kakyoin` | jjbaplus_jotaro |

Los sonidos placeholder se copian desde `template/resources/sfx/character/` al generar el mod.
