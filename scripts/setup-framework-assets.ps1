# Copies template HUD sprites into jjbaplus-framework/resources/gfx/stand_framework/.
# Called from new-character-mod.ps1 at scaffold time.
. "$PSScriptRoot\jjba-config.ps1"

$targetGfx = Join-Path $JJBA_RepoRoot "jjbaplus-framework\resources\gfx\stand_framework"
Copy-JJBAAssetTree -Source $JJBA_TemplateFrameworkGfxPath -Destination $targetGfx

Write-Host "Framework HUD sprites synced to resources/gfx/stand_framework/"
