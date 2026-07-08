#Requires -Version 5.1
param(
    [string]$RegistryPath
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\jjba-config.ps1"

if (-not $RegistryPath) {
    $RegistryPath = Join-Path $JJBA_RepoRoot "docs\variant_ids.json"
}

if (-not (Test-Path $RegistryPath)) {
    throw "Registry not found: $RegistryPath"
}

$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$modTag = [int]$registry.modTag
$maxVariant = $modTag * 100 + 99
$errors = @()

function Add-ValidationError {
    param([string]$Message)
    $script:errors += $Message
}

function Get-StandDefinitionPath {
    param([string]$ModFolder)

    $modPath = Join-Path $JJBA_RepoRoot $ModFolder
    if (-not (Test-Path $modPath)) {
        return $null
    }

    $matches = Get-ChildItem -Path $modPath -Recurse -Filter "stand_definition.lua" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\template\\' }

    if ($matches.Count -eq 0) {
        return $null
    }

    if ($matches.Count -gt 1) {
        Add-ValidationError "$ModFolder has multiple stand_definition.lua files"
    }

    return $matches[0].FullName
}

function Get-LuaTableBlock {
    param(
        [string]$Content,
        [string]$Key
    )

    if ($Content -match "(?ms)$Key\s*=\s*\{") {
        return $true
    }
    return $false
}

function Test-StandDefinitionFile {
    param(
        [string]$ModFolder,
        [string]$FilePath,
        [object]$ModEntry
    )

    $content = Get-Content $FilePath -Raw

    $requiredPatterns = @(
        'id\s*=',
        'discItem\s*=',
        'standIndex\s*=',
        'entities\s*=',
        'behaviorModule\s*='
    )

    foreach ($pattern in $requiredPatterns) {
        if ($content -notmatch $pattern) {
            Add-ValidationError "$ModFolder stand_definition missing field matching /$pattern/"
        }
    }

    if ($content -match 'behaviorModule\s*=\s*nil') {
        Add-ValidationError "$ModFolder stand_definition has behaviorModule = nil (required)"
    }

    if ($ModEntry.standIndex -ne $null) {
        $expectedIndex = [int]$ModEntry.standIndex
        if ($content -match 'standIndex\s*=\s*(-?\d+)') {
            $actualIndex = [int]$Matches[1]
            if ($actualIndex -ne $expectedIndex) {
                Add-ValidationError "$ModFolder standIndex=$actualIndex does not match variant_ids.json ($expectedIndex)"
            }
        }
    }

    if ($ModEntry.entities) {
        foreach ($entityKey in @('stand', 'particle')) {
            $entity = $ModEntry.entities.$entityKey
            if (-not $entity) { continue }

            $variant = $modTag * 100 + [int]$entity.modVariant
            if ($variant -gt 4095) {
                Add-ValidationError "$ModFolder entity $entityKey variant $variant exceeds Isaac max 4095"
            }
            if ($variant -gt $maxVariant) {
                Add-ValidationError "$ModFolder entity $entityKey variant $variant outside modTag block $modTag"
            }
        }
    }

    $skillIds = @()
    if ($content -match '(?ms)skills\s*=\s*\{(.*)\n\s*\},') {
        $skillsBlock = $Matches[1]
        $skillIds = [regex]::Matches($skillsBlock, '(?m)^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=') |
            ForEach-Object { $_.Groups[1].Value }
    }

    $poolIds = @()
    if ($content -match '(?ms)chargePools\s*=\s*\{(.*)\n\s*\},') {
        $poolsBlock = $Matches[1]
        $poolIds = [regex]::Matches($poolsBlock, '(?m)^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=') |
            ForEach-Object { $_.Groups[1].Value }
    }

    foreach ($skillId in $skillIds) {
        if ($content -match "(?ms)$skillId\s*=\s*\{[^\}]*chargePool\s*=\s*""([^""]+)""") {
            $poolRef = $Matches[1]
            if ($poolIds.Count -gt 0 -and $poolRef -notin $poolIds) {
                Add-ValidationError "$ModFolder skill '$skillId' references unknown chargePool '$poolRef'"
            }
        }
    }

    if ($content -match '(?ms)slots\s*=\s*\{(.*)\n\s*\},') {
        $slotsBlock = $Matches[1]
        $slotSkillRefs = [regex]::Matches($slotsBlock, 'skill\s*=\s*"([^"]+)"') |
            ForEach-Object { $_.Groups[1].Value }

        foreach ($slotSkill in $slotSkillRefs) {
            if ($skillIds.Count -gt 0 -and $slotSkill -notin $skillIds) {
                Add-ValidationError "$ModFolder slot references unknown skill '$slotSkill'"
            }
        }
    }
}

Write-Host "Validating stand definitions (modTag=$modTag)..."

foreach ($mod in $registry.mods) {
    if ($mod.type -ne "character") {
        continue
    }

    $standPath = Get-StandDefinitionPath -ModFolder $mod.folder
    if (-not $standPath) {
        Add-ValidationError "$($mod.folder) missing stand_definition.lua"
        continue
    }

    Write-Host "  OK path: $($mod.folder) -> $standPath"
    Test-StandDefinitionFile -ModFolder $mod.folder -FilePath $standPath -ModEntry $mod
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Validation FAILED ($($errors.Count) error(s)):" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "Validation passed." -ForegroundColor Green
exit 0
