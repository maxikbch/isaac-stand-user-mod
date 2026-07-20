# Creates a new JJBA+ character mod from template/.
param(
    [Parameter(Mandatory = $true)]
    [string]$CharacterName,

    [Parameter(Mandatory = $true)]
    [string]$StandName,

    [string]$Id,
    [string]$StandId,
    [string]$DiscName,
    [string]$DiscDescription = "Ore No Stando Da!"
)

. "$PSScriptRoot\jjba-config.ps1"

if (-not $Id) {
    $Id = ConvertTo-Slug -Value $CharacterName
}
if (-not $StandId) {
    $StandId = ConvertTo-Slug -Value $StandName
}

if (-not $Id) {
    throw "Could not derive mod slug from CharacterName: $CharacterName"
}
if (-not $StandId) {
    throw "Could not derive stand id from StandName: $StandName"
}

if ($Id -notmatch '^[a-z][a-z0-9_-]*$') {
    throw "Invalid mod slug '$Id' (use -Id to override)"
}

if ($StandId -notmatch '^[a-z][a-z0-9_]*$') {
    throw "Invalid stand id '$StandId' (use -StandId to override)"
}
$registry = Get-JJBAVariantRegistry
$modFolder = Get-JJBAModFolderName -Slug $Id
$modPath = Join-Path $JJBA_RepoRoot $modFolder

if (Test-Path $modPath) {
    throw "Mod folder already exists: $modPath"
}

foreach ($existing in $registry.mods) {
    if ($existing.standId -eq $StandId) {
        throw "StandId already registered: $StandId"
    }
    if ($existing.folder -eq $modFolder) {
        throw "Folder already registered: $modFolder"
    }
}

if (-not $DiscName) {
    $DiscName = "$StandName Disc"
}

$standIndex = Get-JJBANextStandIndex -Registry $registry
$modTag = if ($registry.modTag) { [int]$registry.modTag } else { $JJBA_ModTag }
$entityVariants = Get-JJBAStandEntityDefaults -ModTag $modTag
$gfxNamespace = $Id
$soundPrefix = ConvertTo-PascalCase -Value $CharacterName
$standNamePascal = ConvertTo-PascalCase -Value $StandName
$displayName = Get-JJBACharacterDisplayName -CharacterName $CharacterName -StandName $StandName
$registerMod = Get-JJBARegisterModId -CharacterName $CharacterName
$metadataDirectory = ($modFolder -replace '-', '_')

$tokens = @{
    "{{DISPLAY_NAME}}" = $displayName
    "{{REGISTER_MOD}}" = $registerMod
    "{{ID}}" = $Id
    "{{CHARACTER_NAME}}" = $CharacterName
    "{{STAND_ID}}" = $StandId
    "{{STAND_NAME}}" = $StandName
    "{{DISC_NAME}}" = $DiscName
    "{{DISC_DESCRIPTION}}" = $DiscDescription
    "{{STAND_INDEX}}" = [string]$standIndex
    "{{MOD_TAG}}" = [string]$modTag
    "{{STAND_VARIANT}}" = [string]$entityVariants.StandVariant
    "{{PARTICLE_VARIANT}}" = [string]$entityVariants.ParticleVariant
    "{{GFX_NAMESPACE}}" = $gfxNamespace
    "{{SOUND_PREFIX}}" = $soundPrefix
    "{{STAND_NAME_PASCAL}}" = $standNamePascal
    "{{METADATA_DIRECTORY}}" = $metadataDirectory
}

function Expand-JJBATemplate {
    param([string]$Text)
    $result = $Text
    foreach ($key in $tokens.Keys) {
        $result = $result.Replace($key, $tokens[$key])
    }
    return $result
}

function Write-JJBATemplateFile {
    param(
        [string]$Source,
        [string]$Destination
    )
    $targetDir = Split-Path -Parent $Destination
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    $raw = Get-Content -Path $Source -Raw -Encoding UTF8
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Destination, (Expand-JJBATemplate -Text $raw), $utf8NoBom)
}

Write-Host "Creating $displayName at $modPath"

New-Item -ItemType Directory -Force -Path $modPath | Out-Null

Get-ChildItem -Path $JJBA_TemplatePath -File | ForEach-Object {
    Write-JJBATemplateFile -Source $_.FullName -Destination (Join-Path $modPath $_.Name)
}

$modLuaPath = Join-Path $modPath $Id
New-Item -ItemType Directory -Force -Path $modLuaPath | Out-Null
Get-ChildItem -Path (Join-Path $JJBA_TemplatePath "mod") -File | ForEach-Object {
    Write-JJBATemplateFile -Source $_.FullName -Destination (Join-Path $modLuaPath $_.Name)
}

Get-ChildItem -Path (Join-Path $JJBA_TemplatePath "content") -File | ForEach-Object {
    Write-JJBATemplateFile -Source $_.FullName -Destination (Join-Path $modPath "content\$($_.Name)")
}

$targetResourcesGfx = Join-Path $modPath "resources\gfx\$gfxNamespace"
Copy-JJBAAssetTree -Source $JJBA_TemplateCharacterGfxPath -Destination $targetResourcesGfx

$targetContentMenuGfx = Join-Path $modPath "content\gfx"
if (-not (Test-Path $targetContentMenuGfx)) {
    New-Item -ItemType Directory -Force -Path $targetContentMenuGfx | Out-Null
}
Get-ChildItem -Path $JJBA_TemplateMenuGfxPath -File | ForEach-Object {
    $target = Join-Path $targetContentMenuGfx $_.Name
    if ($_.Extension -eq ".anm2") {
        Write-JJBATemplateFile -Source $_.FullName -Destination $target
    } else {
        Copy-Item -Path $_.FullName -Destination $target -Force
    }
}

& "$PSScriptRoot\setup-framework-assets.ps1"

$targetSounds = Join-Path $modPath "resources\sfx\$gfxNamespace"
Copy-JJBAAssetTree -Source $JJBA_TemplateCharacterSoundsPath -Destination $targetSounds

$newEntry = [ordered]@{
    folder = $modFolder
    type = "character"
    displayName = $CharacterName
    registerMod = $registerMod
    characterName = $CharacterName
    standId = $StandId
    standName = $StandName
    discName = $DiscName
    gfxNamespace = $gfxNamespace
    standIndex = $standIndex
    entities = [ordered]@{
        stand = [ordered]@{
            name = $StandName
            type = 3
            modVariant = 0
        }
        particle = [ordered]@{
            name = "$StandName Particle"
            type = 1000
            modVariant = 1
        }
    }
}

$registry.mods += [pscustomobject]$newEntry
Save-JJBAVariantRegistry -Registry $registry

& "$PSScriptRoot\update-install-mods.ps1"

Write-Host ""
Write-Host "Created $displayName"
Write-Host "  Character:    $CharacterName"
Write-Host "  Mod slug:     $Id (folder $modFolder)"
Write-Host "  Stand name:   $StandName"
Write-Host "  Stand id:     $StandId"
Write-Host "  RegisterMod:  $registerMod"
Write-Host "  Stand index:  $standIndex (subtype)"
Write-Host "  Variants:     $($entityVariants.StandVariant) / $($entityVariants.ParticleVariant) (modTag $modTag)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run .\install-mods.cmd (or .\scripts\install-mods.ps1)"
Write-Host "  2. Enable [JJBA+] Framework + $displayName in Isaac"
Write-Host "  3. Replace art in resources/gfx/$gfxNamespace/ (and content/gfx/ menu files if needed)"
Write-Host "  4. Tune stand_stats.lua and stand_definition.lua hooks if needed"
