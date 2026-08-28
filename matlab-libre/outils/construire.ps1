# construire.ps1 — compile MatLibre sur Windows.
#
#   .\outils\construire.ps1                    compile en Release
#   .\outils\construire.ps1 -Debogage          compile avec les assertions
#   .\outils\construire.ps1 -Tests             compile puis teste
#   .\outils\construire.ps1 -Installer C:\MatLibre
#   .\outils\construire.ps1 -Paquet            fabrique l'archive ZIP
#   .\outils\construire.ps1 -Generateur "MinGW Makefiles"
#
# Visual Studio 2019 ou plus récent, ou MinGW, et CMake. Aucune autre
# dépendance n'est requise.
param(
    [switch]$Debogage,
    [switch]$Tests,
    [switch]$Paquet,
    [string]$Installer = "",
    [string]$Dossier = "",
    [string]$Generateur = ""
)

$ErrorActionPreference = "Stop"
$racine = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ($Debogage) { $type = "Debug" } else { $type = "Release" }
if ($Dossier -eq "") {
    if ($Debogage) { $Dossier = Join-Path $racine "build-debug" }
    else { $Dossier = Join-Path $racine "build" }
}

# PowerShell n'arrête pas le script quand un programme externe rend un code
# d'erreur : sans ce contrôle, une compilation ratée se poursuivait
# jusqu'au message « fini » et une installation vouée à l'échec.
function Verifier($etape) {
    if ($LASTEXITCODE -ne 0) {
        Write-Error "MatLibre : $etape a echoue (code $LASTEXITCODE)."
    }
}

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Error "cmake est introuvable. Installez-le, puis relancez."
}

Write-Host "MatLibre : configuration ($type) dans $Dossier"
if ($Generateur -ne "") {
    cmake -S $racine -B $Dossier -G $Generateur -DCMAKE_BUILD_TYPE=$type
} else {
    cmake -S $racine -B $Dossier -DCMAKE_BUILD_TYPE=$type
}
Verifier "la configuration"

Write-Host "MatLibre : compilation"
cmake --build $Dossier --config $type -j
Verifier "la compilation"

# Visual Studio range l'exécutable dans un sous-dossier par configuration,
# Ninja et les Makefiles à la racine du dossier de construction.
function Trouver($nom) {
    foreach ($essai in @((Join-Path $Dossier "$nom.exe"),
                         (Join-Path $Dossier "$type\$nom.exe"),
                         (Join-Path $Dossier "$nom"))) {
        if (Test-Path $essai) { return $essai }
    }
    return ""
}
$exe = Trouver "matlibre"
if ($exe -eq "") {
    Write-Error "MatLibre : l'executable n'a pas ete produit dans $Dossier."
}

if ($Tests) {
    Write-Host "MatLibre : tests"
    $exeTests = Trouver "matlibre_tests"
    if ($exeTests -eq "") {
        Write-Error "MatLibre : matlibre_tests n'a pas ete produit. Configurez avec -DMATLIBRE_TESTS=ON."
    }
    & $exeTests
    Verifier "les verifications C++"
    $env:MATLIBRE_TOOLBOX = Join-Path $racine "toolbox"
    & $exe (Join-Path $racine "outils\verifierDoublons.m")
    Verifier "la recherche de doublons"
    Get-ChildItem (Join-Path $racine "tests\scripts\test_*.m") | ForEach-Object {
        Write-Host "--> $($_.Name)"
        & $exe --path (Join-Path $racine "tests\scripts") $_.FullName
        Verifier "le test $($_.Name)"
    }
    Write-Host "tous les tests passent"
}

if ($Installer -ne "") {
    Write-Host "MatLibre : installation dans $Installer"
    cmake --install $Dossier --prefix $Installer --config $type
    Verifier "l'installation"
}

if ($Paquet) {
    Write-Host "MatLibre : fabrication de l'archive"
    Push-Location $Dossier
    try {
        cpack -C $type
        Verifier "la fabrication de l'archive"
    } finally {
        Pop-Location
    }
}

Write-Host "MatLibre : fini. L'executable est $exe"
