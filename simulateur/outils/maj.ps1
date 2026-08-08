# Mise à jour quotidienne, sous Windows : récupérer, recompiler, lancer.
#
#   .\outils\maj.ps1
#
# Il n'y a rien à reconfigurer : le dossier « build » garde en mémoire le
# compilateur et les chemins donnés à CMake la première fois. Ninja ne
# recompile que ce qui a changé, et relance CMake tout seul si la recette de
# compilation a été modifiée.

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path "build")) {
    Write-Host "Le dossier « build » n'existe pas encore." -ForegroundColor Yellow
    Write-Host "Lancez d'abord la commande cmake complète du README." -ForegroundColor Yellow
    exit 1
}

Write-Host "== Récupération ==" -ForegroundColor Cyan
git pull

Write-Host "== Compilation ==" -ForegroundColor Cyan
cmake --build build
if ($LASTEXITCODE -ne 0) {
    Write-Host "La compilation a échoué : rien n'a été lancé." -ForegroundColor Red
    exit 1
}

Write-Host "== Lancement ==" -ForegroundColor Cyan
& ".\build\simulateur.exe"
