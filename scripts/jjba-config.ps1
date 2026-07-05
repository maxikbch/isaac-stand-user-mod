$script:JJBA_FamilyPrefix = "JJBA+"
$script:JJBA_AuthorNamespace = "Maxo13:JJBAPlus"
$script:JJBA_BaseVariant = 13000
$script:JJBA_RepoRoot = Split-Path -Parent $PSScriptRoot
$script:JJBA_VariantIdsPath = Join-Path $JJBA_RepoRoot "docs\variant_ids.json"
$script:JJBA_TemplatePath = Join-Path $JJBA_RepoRoot "templates\character-mod"
$script:JJBA_PlaceholderAssetsPath = Join-Path $JJBA_RepoRoot "templates\placeholder-assets"

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

function Get-JJBANextVariantPair {
    param($Registry)
    $maxVariant = $JJBA_BaseVariant - 2
    foreach ($mod in $Registry.mods) {
        if ($null -ne $mod.familiarVariant -and $mod.familiarVariant -gt $maxVariant) {
            $maxVariant = [int]$mod.familiarVariant
        }
    }
    return @{
        Familiar = $maxVariant + 2
        Particle = $maxVariant + 3
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
