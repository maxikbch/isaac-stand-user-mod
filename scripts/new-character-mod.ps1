# Creates a new JJBA+ character mod from templates/character-mod.
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

$variants = Get-JJBANextVariantPair -Registry $registry
$gfxNamespace = $Id
$soundPrefix = ConvertTo-PascalCase -Value $CharacterName
$standNamePascal = ConvertTo-PascalCase -Value $StandName
$displayName = Get-JJBADisplayName -Name $CharacterName
$registerMod = Get-JJBARegisterModId -CharacterName $CharacterName
$metadataDirectory = ($modFolder -replace '-', '_')

$tokens = @{
    "{{DISPLAY_NAME}}" = $displayName
    "{{REGISTER_MOD}}" = $registerMod
    "{{CHARACTER_NAME}}" = $CharacterName
    "{{STAND_ID}}" = $StandId
    "{{STAND_NAME}}" = $StandName
    "{{DISC_NAME}}" = $DiscName
    "{{DISC_DESCRIPTION}}" = $DiscDescription
    "{{FAMILIAR_VARIANT}}" = [string]$variants.Familiar
    "{{PARTICLE_VARIANT}}" = [string]$variants.Particle
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

function Copy-JJBAAssetTree {
    param(
        [string]$Source,
        [string]$Destination
    )
    if (-not (Test-Path $Source)) {
        return
    }
    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
        $target = Join-Path $Destination $relative
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        }
        Copy-Item -Path $_.FullName -Destination $target -Force
    }
}

Write-Host "Creating $displayName at $modPath"

New-Item -ItemType Directory -Force -Path $modPath | Out-Null

Get-ChildItem -Path $JJBA_TemplatePath -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($JJBA_TemplatePath.Length).TrimStart('\', '/')
    $target = Join-Path $modPath $relative
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }

    $raw = Get-Content -Path $_.FullName -Raw -Encoding UTF8
    Set-Content -Path $target -Value (Expand-JJBATemplate -Text $raw) -Encoding UTF8 -NoNewline
}

$sourceGfx = Join-Path $JJBA_PlaceholderAssetsPath "character-gfx"
$targetContentGfx = Join-Path $modPath "content\gfx\$gfxNamespace"
Copy-JJBAAssetTree -Source $sourceGfx -Destination $targetContentGfx

$sourceContentMenuGfx = Join-Path $JJBA_PlaceholderAssetsPath "menu-gfx"
$targetContentMenuGfx = Join-Path $modPath "content\gfx"
if (-not (Test-Path $targetContentMenuGfx)) {
    New-Item -ItemType Directory -Force -Path $targetContentMenuGfx | Out-Null
}
Get-ChildItem -Path $sourceContentMenuGfx -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $targetContentMenuGfx $_.Name) -Force
}

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
    familiarVariant = $variants.Familiar
    particleVariant = $variants.Particle
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
Write-Host "  Variants:     $($variants.Familiar) / $($variants.Particle)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run .\install-mods.cmd (or .\scripts\install-mods.ps1)"
Write-Host "  2. Enable JJBA+ Framework + $displayName in Isaac"
Write-Host "  3. Replace art in content/gfx/$gfxNamespace/ (and content/gfx/ menu files if needed)"
Write-Host "  4. Tune stand_stats.lua and stand_definition.lua hooks if needed"
