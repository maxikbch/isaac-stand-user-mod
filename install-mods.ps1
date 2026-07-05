# Run from repo root. Uses directory junctions (no admin required on most Windows setups).
$mods = "D:\SteamLibrary\steamapps\common\The Binding of Isaac Rebirth\mods"
$repo = "D:\SteamLibrary\steamapps\common\The Binding of Isaac Rebirth\mods\isaac-stand-user-mod"

cmd /c mklink /J "$mods\jojo-stand-framework" "$repo\jojo-stand-framework"
cmd /c mklink /J "$mods\jojo-stand-user" "$repo\jojo-stand-user"

Write-Host "Symlinks created. Enable both mods in Isaac."
