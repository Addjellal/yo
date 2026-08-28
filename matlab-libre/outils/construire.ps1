# construire.ps1 — compile MatLibre sur Windows.
#
#   .\outils\construire.ps1                    compile en Release
#   .\outils\construire.ps1 -Debogage          compile avec les assertions
#   .\outils\construire.ps1 -Tests             compile puis teste
#   .\outils\construire.ps1 -Propre            repart d'un dossier vide
#   .\outils\construire.ps1 -Installer C:\MatLibre
#   .\outils\construire.ps1 -Paquet            fabrique l'archive ZIP
#   .\outils\construire.ps1 -Generateur "MinGW Makefiles"
#
# Visual Studio 2019 ou plus récent, ou MinGW, et CMake. Aucune autre
# dépendance n'est requise.
#
# Ce fichier est enregistré en UTF-8 avec BOM : sans lui, Windows
# PowerShell 5.1 le lit dans la page de codes ANSI, et les accents des
# commentaires deviennent illisibles.
param(
    [switch]$Debogage,
    [switch]$Tests,
    [switch]$Paquet,
    [switch]$Propre,
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

# Le cache de CMake garde le type de construction et le générateur du
# premier appel. Un cache qui ne correspond plus à ce qu'on demande donne
# des erreurs qui n'ont aucun rapport avec la cause — le générateur Ninja,
# par exemple, s'arrête sur « expected newline, got lexing error » quand le
# type de construction contient un « $ ». On le relit et on efface le
# dossier plutôt que de compiler sur une configuration périmée.
$cache = Join-Path $Dossier "CMakeCache.txt"
$aEffacer = $Propre.IsPresent
if ((-not $aEffacer) -and (Test-Path $cache)) {
    $lignes = Get-Content $cache
    $typeCache = ($lignes | Where-Object { $_ -like "CMAKE_BUILD_TYPE:*=*" } |
                  ForEach-Object { $_.Substring($_.IndexOf("=") + 1) } | Select-Object -First 1)
    $generateurCache = ($lignes | Where-Object { $_ -like "CMAKE_GENERATOR:*=*" } |
                        ForEach-Object { $_.Substring($_.IndexOf("=") + 1) } | Select-Object -First 1)
    if ($null -ne $typeCache -and $typeCache -ne $type) {
        Write-Host "MatLibre : le cache est en « $typeCache », on demande « $type » : dossier efface"
        $aEffacer = $true
    }
    if ($Generateur -ne "" -and $null -ne $generateurCache -and $generateurCache -ne $Generateur) {
        Write-Host "MatLibre : le cache est en « $generateurCache », on demande « $Generateur » : dossier efface"
        $aEffacer = $true
    }
}
if ($aEffacer -and (Test-Path $Dossier)) {
    Remove-Item -Recurse -Force $Dossier
}

# Les arguments sont construits ici, dans des chaînes entre guillemets
# doubles : le remplacement des variables y est fait par l'analyseur, sans
# passer par le mode « argument » de PowerShell, dont les règles de
# découpage varient d'une version à l'autre. Une version de ce script
# passait « -DCMAKE_BUILD_TYPE=$type » tel quel à CMake, qui l'inscrivait
# dans son cache, et ninja refusait ensuite de lire ses propres règles.
$argumentsConfiguration = @("-S", "$racine", "-B", "$Dossier", "-DCMAKE_BUILD_TYPE=$type")
if ($Generateur -ne "") {
    $argumentsConfiguration += @("-G", "$Generateur")
}

Write-Host "MatLibre : configuration ($type) dans $Dossier"
& cmake @argumentsConfiguration
Verifier "la configuration"

Write-Host "MatLibre : compilation"
& cmake --build "$Dossier" --config "$type" -j
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
    & cmake --install "$Dossier" --prefix "$Installer" --config "$type"
    Verifier "l'installation"
}

if ($Paquet) {
    Write-Host "MatLibre : fabrication de l'archive"
    Push-Location $Dossier
    try {
        & cpack -C "$type"
        Verifier "la fabrication de l'archive"
    } finally {
        Pop-Location
    }
}

Write-Host "MatLibre : fini. L'executable est $exe"
