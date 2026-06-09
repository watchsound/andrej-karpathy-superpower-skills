# sync-skills.ps1 — idempotent skill-junction sync for Windows.
#
# Creates a directory junction in ~/.claude/skills/ for every skill in this
# repo that does not already have one. Existing junctions are left alone.
# Safe to re-run after every `git pull` to pick up new skills.
#
# Usage (from the repo root):
#   pwsh ./sync-skills.ps1
#   # or, if pwsh is not on PATH:
#   powershell -ExecutionPolicy Bypass -File .\sync-skills.ps1

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$src       = Join-Path $scriptDir 'skills'
$dst       = Join-Path $env:USERPROFILE '.claude\skills'

if (-not (Test-Path $src -PathType Container)) {
  throw "Skills source dir not found: $src. Run this script from inside the repo."
}

New-Item -ItemType Directory -Path $dst -Force | Out-Null

$created = 0
Get-ChildItem $src -Directory |
  Where-Object { -not (Test-Path (Join-Path $dst $_.Name)) } |
  ForEach-Object {
    New-Item -ItemType Junction -Path (Join-Path $dst $_.Name) -Target $_.FullName | Out-Null
    Write-Host "Created junction: $($_.Name)"
    $created++
  }

if ($created -eq 0) {
  Write-Host "All skills already junctioned. Nothing to do."
} else {
  Write-Host "$created junction(s) created in $dst"
}
