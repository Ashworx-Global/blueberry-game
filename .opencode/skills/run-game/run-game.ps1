<#
.SYNOPSIS
  Blue Berry — run the game via Godot (Windows PowerShell).
.EXAMPLE
  .\run-game.ps1 play
  .\run-game.ps1 editor
  .\run-game.ps1 import
  .\run-game.ps1 check
  .\run-game.ps1 smoke
#>
param(
  [string]$Mode = "play"
)

$ErrorActionPreference = "Stop"

# Repo root = three levels above this script (.opencode/skills/run-game/).
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
if (-not (Test-Path (Join-Path $Root "project.godot"))) {
  throw "run-game: could not locate project.godot under $Root"
}

if (-not $env:GODOT_BIN) {
  $Candidates = @(
    "C:\Dev\Gadot\Godot_v4.7.2-stable_win64_console.exe",
    "C:\Dev\Gadot\Godot_v4.7.2-stable_win64.exe"
  )
  foreach ($c in $Candidates) {
    if (Test-Path $c) { $env:GODOT_BIN = $c; break }
  }
  if (-not $env:GODOT_BIN) {
    $onPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($onPath) { $env:GODOT_BIN = "godot" }
  }
}
if (-not $env:GODOT_BIN) {
  throw "run-game: no Godot executable found. Set `$env:GODOT_BIN to your Godot exe."
}

$Godot = $env:GODOT_BIN
switch ($Mode) {
  "play"   { & $Godot --path $Root }
  "editor" { & $Godot --path $Root -e }
  "import" { & $Godot --headless --path $Root --import }
  # NOTE: bare --check-only never terminates on Godot 4.7.2; --quit makes it exit.
  "check"  { & $Godot --headless --path $Root --check-only --quit }
  "smoke"  { & $Godot --headless --path $Root --quit --verbose }
  default  { throw "run-game: unknown mode '$Mode' (expected play|editor|import|check|smoke)" }
}
