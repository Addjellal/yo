# construire.ps1 — compile MatLibre sur Windows.
#
#   .\outils\construire.ps1                    compile en Release
#   .\outils\construire.ps1 -Debogage          compile avec les assertions
#   .\outils\construire.ps1 -Tests             compile puis teste
#   .\outils\construire.ps1 -Installer C:\MatLibre
#   .\outils\construire.ps1 -Paquet            fabrique l'archive ZIP
#
# Visual Studio 2019 ou plus récent, ou MinGW, et CMake. Aucune autre
# dépendance n'est requise.
param(
    [switch]$Debogage,
    [switch]$Tests,
    [switch]$Paquet,
    [string]$Installer = "",
    [string]$Dossier = ""
)

$ErrorActionPreference = "Stop"
$racine = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ($Debogage) { $type = "Debug" } else { $type = "Release" }
if ($Dossier -eq "") {
    if ($Debogage) { $Dossier = Join-Path $racine "build-debug" }
    else { $Dossier = Join-Path $racine "build" }
}

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Error "cmake est introuvable. Installez-le, puis relancez."
}

Write-Host "MatLibre : configuration ($type) dans $Dossier"
cmake -S $racine -B $Dossier -DCMAKE_BUILD_TYPE=$type
Write-Host "MatLibre : compilation"
cmake --build $Dossier --config $type -j

# Visual Studio range l'exécutable dans un sous-dossier par configuration.
$exe = Join-Path $Dossier "matlibre.exe"
if (-not (Test-Path $exe)) { $exe = Join-Path $Dossier "$type\matlibre.exe" }
$exeTests = Join-Path $Dossier "matlibre_tests.exe"
if (-not (Test-Path $exeTests)) { $exeTests = Join-Path $Dossier "$type\matlibre_tests.exe" }

if ($Tests) {
    Write-Host "MatLibre : tests"
    & $exeTests
    if ($LASTEXITCODE -ne 0) { Write-Error "les verifications C++ echouent" }
    $env:MATLIBRE_TOOLBOX = Join-Path $racine "toolbox"
    & $exe (Join-Path $racine "outils\verifierDoublons.m")
    Get-ChildItem (Join-Path $racine "tests\scripts\test_*.m") | ForEach-Object {
        Write-Host "--> $($_.Name)"
        & $exe --path (Join-Path $racine "tests\scripts") $_.FullName
        if ($LASTEXITCODE -ne 0) { Write-Error "echec : $($_.Name)" }
    }
    Write-Host "tous les tests passent"
}

if ($Installer -ne "") {
    Write-Host "MatLibre : installation dans $Installer"
    cmake --install $Dossier --prefix $Installer --config $type
}

if ($Paquet) {
    Write-Host "MatLibre : fabrication de l'archive"
    Push-Location $Dossier
    cpack -C $type
    Pop-Location
}

Write-Host "MatLibre : fini. L'executable est $exe"
