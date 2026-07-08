# Checklist de prueba manual — JJBA+

Ejecutar con **JJBA+ Framework** + el mod de personaje bajo prueba. Isaac Repentance, mod local via junctions (`install-mods.cmd`).

## Framework solo

- [ ] Activar solo `jjbaplus-framework` — no crashea al iniciar run
- [ ] Consola sin errores Lua al cargar

## Por personaje (Jotaro / Kakyoin / UI Debug)

### Spawn y disco

- [ ] Personaje inicia con disco vinculado (`linkedCharacters`)
- [ ] Stand visible al tener disco
- [ ] HUD meter (barra + skill1 si aplica) visible

### Combate

- [ ] **Jotaro / UI Debug:** punch flurry generic (`idle → rush → attack → return`)
- [ ] **Kakyoin:** combate custom (splash en lugar de attack genérico)
- [ ] Carga de punch (mantener shoot) y release funciona
- [ ] Lock-on a enemigos en dirección de aim

### Skills

- [ ] **Jotaro:** Time Stop (skill1) consume carga, activa freeze + shader ZaWarudo, cooldown al terminar
- [ ] **Kakyoin:** Emerald Splash (skill1) consume carga, rush → radio, cooldown al completar super
- [ ] **UI Debug:** presets de meter / skills de prueba responden

### Persistencia y salas

- [ ] Cambio de sala: fade del stand, meter/carga persisten (save por seed)
- [ ] Nueva run: estado JSF resetea correctamente

### Coop

- [ ] 2 jugadores locales: cada uno con stand/HUD independiente
- [ ] Input skills solo en jugador local controlado

### Cross-mod (si aplica)

- [ ] Swap de disco entre dos personajes JJBA+ registrados
- [ ] Disco anterior va a pedestal o suelo

## Validación automatizada

```powershell
.\scripts\validate-stands.ps1
```

Debe terminar sin errores antes de merge/release.
