# Mise à jour quotidienne, sous Windows : récupérer, recompiler, lancer.
#
#   .\outils\maj.ps1              récupère, recompile, lance
#   .\outils\maj.ps1 -Paquet      idem, et refait l'archive portable
#
# Il n'y a rien à reconfigurer : le dossier de construction garde en mémoire
# le compilateur et les chemins donnés à CMake la première fois. Ninja ne
# recompile que ce qui a changé, et relance CMake tout seul si la recette de
# compilation a été modifiée. Les DLL de Qt sont redéposées à chaque
# compilation, l'exécutable produit démarre donc tel quel.

param(
    # Dossier de construction. Par défaut, celui qui existe déjà.
    [string]$Dossier = "",
    # Refaire aussi l'archive portable (.zip).
    [switch]$Paquet
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if ($Dossier -eq "") {
    foreach ($candidat in @("build-paquet", "build")) {
        if (Test-Path $candidat) { $Dossier = $candidat; break }
    }
}
if ($Dossier -eq "" -or -not (Test-Path $Dossier)) {
    Write-Host "Aucun dossier de construction trouvé." -ForegroundColor Yellow
    Write-Host "Lancez d'abord : .\outils\paquet.ps1 -Qt <dossier Qt> -Compilateur <g++.exe>" -ForegroundColor Yellow
    exit 1
}

Write-Host "== Récupération ==" -ForegroundColor Cyan
git pull

Write-Host "== Compilation ($Dossier) ==" -ForegroundColor Cyan
if ($Paquet) {
    cmake --build $Dossier --target paquet
} else {
    cmake --build $Dossier
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "La compilation a échoué : rien n'a été lancé." -ForegroundColor Red
    exit 1
}

if ($Paquet) {
    $archive = Get-ChildItem $Dossier -Filter "*.zip" |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($archive) {
        Write-Host "Archive refaite : $($archive.FullName)" -ForegroundColor Green
    }
}

Write-Host "== Lancement ==" -ForegroundColor Cyan
& (Join-Path $Dossier "simulateur.exe")
