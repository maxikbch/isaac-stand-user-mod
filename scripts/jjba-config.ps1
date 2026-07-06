$script:JJBA_FamilyPrefix = "JJBA+"
$script:JJBA_AuthorNamespace = "Maxo13:JJBAPlus"
$script:JJBA_ModTag = 13
$script:JJBA_MaxModVariant = 99
$script:JJBA_RepoRoot = Split-Path -Parent $PSScriptRoot
$script:JJBA_VariantIdsPath = Join-Path $JJBA_RepoRoot "docs\variant_ids.json"
$script:JJBA_TemplatePath = Join-Path $JJBA_RepoRoot "template"
$script:JJBA_TemplateCharacterGfxPath = Join-Path $JJBA_TemplatePath "resources\gfx\character"
$script:JJBA_TemplateMenuGfxPath = Join-Path $JJBA_TemplatePath "content\gfx"
$script:JJBA_TemplateFrameworkGfxPath = Join-Path $JJBA_TemplatePath "resources\gfx\framework"
$script:JJBA_TemplateCharacterSoundsPath = Join-Path $JJBA_TemplatePath "resources\sounds\character"

function Get-JJBAVariantRegistry {
    if (-not (Test-Path $JJBA_VariantIdsPath)) {
        throw "Missing variant registry: $JJBA_VariantIdsPath"
    }
    return Get-Content $JJBA_VariantIdsPath -Raw | ConvertFrom-Json
}

function Save-JJBAVariantRegistry {
    param([Parameter(Mandatory = $true)] $Registry)
    $json = $Registry | ConvertTo-Json -Depth 6
    Set-Content -Path $JJBA_VariantIdsPath -Value $json -Encoding UTF8
}

function Resolve-JJBAVariant {
    param(
        [int]$ModTag,
        [int]$ModVariant
    )
    if ($ModVariant -lt 0 -or $ModVariant -gt $JJBA_MaxModVariant) {
        throw "modVariant out of range (0..$JJBA_MaxModVariant): $ModVariant"
    }
    return $ModTag * 100 + $ModVariant
}

function Get-JJBANextStandIndex {
    param($Registry)
    $maxIndex = -1
    foreach ($mod in $Registry.mods) {
        if ($null -eq $mod.standIndex) {
            continue
        }
        $index = [int]$mod.standIndex
        if ($index -lt 0) {
            continue
        }
        if ($index -gt $maxIndex) {
            $maxIndex = $index
        }
    }
    return $maxIndex + 1
}

function Get-JJBAStandEntityDefaults {
    param([int]$ModTag = $JJBA_ModTag)
    return @{
        StandVariant = Resolve-JJBAVariant -ModTag $ModTag -ModVariant 0
        ParticleVariant = Resolve-JJBAVariant -ModTag $ModTag -ModVariant 1
    }
}

function ConvertTo-PascalCase {
    param([string]$Value)
    $parts = $Value -split '\s+'
    return ($parts | ForEach-Object {
        if ($_.Length -eq 0) { return "" }
        $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
    }) -join ''
}

function ConvertTo-Slug {
    param([string]$Value)
    $slug = $Value.Trim().ToLower()
    $slug = $slug -replace '\s+', '_'
    $slug = $slug -replace '[^a-z0-9_]', ''
    return $slug
}

function Get-JJBARegisterModId {
    param([string]$CharacterName)
    $safe = ($CharacterName -replace '\s+', '')
    return "$JJBA_AuthorNamespace`_$safe"
}

function Get-JJBAFrameworkFolderName {
    return "jjbaplus-framework"
}

function Get-JJBAModFolderName {
    param([string]$Slug)
    return "jjbaplus-$Slug"
}

function Get-JJBADisplayName {
    param([string]$Name)
    return "$JJBA_FamilyPrefix $Name"
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
