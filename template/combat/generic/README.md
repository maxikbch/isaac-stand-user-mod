# Combate genérico (referencia)

Los behaviors de punch flurry (`idle → rush → attack → return`) viven en el framework:

`jjbaplus-framework/src/core/combat/behaviors/generic/`

Los mods de personaje usan:

```lua
behaviorModule = _G.JoJoStandFramework.Combat.behaviors.generic,
```

Los archivos en `behaviors/` de esta carpeta son solo referencia histórica; el scaffold ya no los copia a mods nuevos.
