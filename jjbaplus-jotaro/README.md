# Plantilla de personaje JJBA+

Usada por `scripts/new-character-mod.ps1` para generar `jjbaplus-{slug}/`.

## Estructura

```
template/
├── *.lua, metadata.xml          → raíz del mod generado (tokens expandidos)
├── content/
│   ├── *.xml                    → content/ del mod (tokens expandidos)
│   └── gfx/                     → menú (content/gfx/); .anm2 con {{CHARACTER_NAME}}
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
| `{{DISPLAY_NAME}}` | JJBA+ Jotaro |
| `{{REGISTER_MOD}}` | Maxo13:JJBAPlus_Jotaro |
| `{{CHARACTER_NAME}}` | Jotaro |
| `{{STAND_ID}}` | star_platinum |
| `{{STAND_NAME}}` | Star Platinum |
| `{{DISC_NAME}}` | Star Platinum Disc |
| `{{STAND_INDEX}}` | 0 |
| `{{MOD_TAG}}` | 13 |
| `{{STAND_VARIANT}}` | 1300 |
| `{{PARTICLE_VARIANT}}` | 1301 |
| `{{GFX_NAMESPACE}}` | jotaro |
| `{{SOUND_PREFIX}}` | Jotaro |
| `{{STAND_NAME_PASCAL}}` | StarPlatinum |
| `{{METADATA_DIRECTORY}}` | jjbaplus_jotaro |

Los sonidos placeholder se copian desde `template/resources/sfx/character/` al generar el mod.
