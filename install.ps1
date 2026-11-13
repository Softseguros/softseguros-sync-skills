# Instala la skill «softseguros-sync» en Windows (PowerShell 5.1 o posterior).
#
#   .\install.ps1                     instala en los agentes detectados
#   .\install.ps1 -Agent claude       solo en Claude Code
#   .\install.ps1 -Agent all          en los cuatro
#   .\install.ps1 -Project            en el proyecto actual
#   .\install.ps1 -Uninstall          la quita
#   .\install.ps1 -DryRun             muestra qué haría
#
# Agentes: claude, codex, opencode, hermes. Para ChatGPT y claude.ai se sube
# dist\softseguros-sync.zip (ver README.md).

[CmdletBinding()]
param(
    [string[]]$Agent = @('auto'),
    [switch]$Project,
    [string]$Dir,
    [switch]$Uninstall,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$SkillName = 'softseguros-sync'
$Known = @('claude', 'codex', 'opencode', 'hermes')
$UserHome = $env:USERPROFILE
if (-not $UserHome) { $UserHome = $HOME }

$Labels = @{ claude = 'Claude Code'; codex = 'Codex CLI'; opencode = 'opencode'; hermes = 'Hermes Agent' }

function Get-AgentHome([string]$Name) {
    switch ($Name) {
        'claude'   { if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $UserHome '.claude' } }
        'codex'    { if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $UserHome '.codex' } }
        'opencode' { Join-Path (Join-Path $UserHome '.config') 'opencode' }
        'hermes'   { if ($env:HERMES_HOME) { $env:HERMES_HOME } else { Join-Path $UserHome '.hermes' } }
    }
}

function Get-SkillsRoot([string]$Name) {
    if ($Project) {
        switch ($Name) {
            'claude'   { return Join-Path (Get-Location) '.claude\skills' }
            'codex'    { return Join-Path (Get-Location) '.agents\skills' }
            'opencode' { return Join-Path (Get-Location) '.opencode\skills' }
            'hermes'   { return $null }
        }
    }
    switch ($Name) {
        'codex' {
            if ($env:CODEX_SKILLS_DIR) { return $env:CODEX_SKILLS_DIR }
            return Join-Path $UserHome '.agents\skills'
        }
        default { return Join-Path (Get-AgentHome $Name) 'skills' }
    }
}

function Test-Detected([string]$Name) {
    (Test-Path (Get-AgentHome $Name)) -or [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-OurSkill([string]$Path) {
    $file = Join-Path $Path 'SKILL.md'
    (Test-Path $file) -and [bool](Select-String -Path $file -Pattern "^name: $SkillName$" -Quiet)
}

$Source = Join-Path $PSScriptRoot "skills\$SkillName"
if (-not $Uninstall -and -not (Test-Path (Join-Path $Source 'SKILL.md'))) {
    throw "No encuentro skills\$SkillName junto a este script. Descarga el proyecto completo."
}

$Selected = New-Object System.Collections.Generic.List[string]
foreach ($item in ($Agent -join ',').Split(',') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }) {
    switch ($item) {
        'auto'         { $Known | Where-Object { Test-Detected $_ } | ForEach-Object { $Selected.Add($_) } }
        'all'          { $Known | ForEach-Object { $Selected.Add($_) } }
        'claude-code'  { $Selected.Add('claude') }
        'hermes-agent' { $Selected.Add('hermes') }
        { $Known -contains $_ } { $Selected.Add($item) }
        { @('chatgpt', 'claude-web', 'claude-ai', 'claude-desktop') -contains $_ } {
            Write-Host "  · $item no lee carpetas del equipo: sube dist\$SkillName.zip (ver README.md)."
        }
        default { throw "Agente desconocido: $item (claude, codex, opencode, hermes, all, auto)" }
    }
}
$Selected = $Selected | Select-Object -Unique

$Targets = @()
foreach ($name in $Selected) {
    $root = Get-SkillsRoot $name
    if (-not $root) {
        Write-Host "  · $($Labels[$name]) no tiene carpeta de skills por proyecto: usa la instalación global"
        continue
    }
    $Targets += [pscustomobject]@{ Label = $Labels[$name]; Root = $root }
}
if ($Dir) { $Targets += [pscustomobject]@{ Label = 'carpeta indicada'; Root = $Dir } }

if (-not $Targets) {
    Write-Host 'No detecté Claude Code, Codex, opencode ni Hermes en este equipo.'
    Write-Host 'Elige uno con -Agent (claude, codex, opencode, hermes, all) o una carpeta con -Dir.'
    exit 1
}

$verb = 'Instalando'
if ($Uninstall) { $verb = 'Quitando' }
Write-Host "$verb «$SkillName»:"
$failed = $false
foreach ($target in $Targets) {
    $dest = Join-Path $target.Root $SkillName
    if ((Test-Path $dest) -and -not (Test-OurSkill $dest)) {
        Write-Warning "$dest existe y no es esta skill: no la toco ($($target.Label))"
        $failed = $true
        continue
    }
    if ($DryRun) {
        Write-Host "  [simulación] $($target.Label) → $dest"
        continue
    }
    if (Test-Path $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    if ($Uninstall) {
        Write-Host "  ✓ $($target.Label): quitada de $dest"
        continue
    }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    # Todo menos las pruebas (evals), que no hacen falta para usar la skill.
    Get-ChildItem -LiteralPath $Source -Force | Where-Object { $_.Name -ne 'evals' } |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force }
    Write-Host "  ✓ $($target.Label) → $dest"
}

if (-not $Uninstall -and -not $DryRun -and -not $failed) {
    Write-Host ''
    Write-Host 'Listo. Reinicia el agente para que cargue la skill.'
    Write-Host 'Si aún no tienes conectado el MCP del Sincronizador, sigue docs\conectar-mcp.md.'
}
if ($failed) { exit 1 }
