# construire.ps1 — compile MatLibre sur Windows.
#
#   .\outils\construire.ps1                    compile en Release
#   .\outils\construire.ps1 -Debogage          compile avec les assertions
#   .\outils\construire.ps1 -Tests             compile puis teste
#   .\outils\construire.ps1 -Incrementale      garde l'arbre au lieu de l'effacer
#   .\outils\construire.ps1 -Installer C:\MatLibre
#   .\outils\construire.ps1 -Paquet            fabrique l'archive ZIP
#   .\outils\construire.ps1 -Generateur "MinGW Makefiles"
#   .\outils\construire.ps1 -Qt C:\Qt\6.11.1\mingw_64
#
# Chaque compilation part d'un arbre neuf : l'ancien est effacé avant de
# reconfigurer. C'est ce qui évite les objets orphelins et les caches
# périmés. « -Incrementale » garde l'arbre, pour itérer.
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
    [switch]$Incrementale,
    [string]$Installer = "",
    [string]$Dossier = "",
    [string]$Generateur = "",
    [string]$Qt = ""
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

# On part d'un arbre neuf. Un arbre garde ce qu'on croit avoir enlevé : le
# .obj d'un fichier supprimé, une option de cache qui n'existe plus, une
# bibliothèque trouvée la fois d'avant et disparue depuis. Le cache garde
# aussi le type de construction et le générateur du premier appel, et un
# cache qui ne correspond plus donne des erreurs sans rapport avec la
# cause — le générateur Ninja, par exemple, s'arrête sur « expected
# newline, got lexing error » quand le type contient un « $ ».
#
# « -Incrementale » garde l'arbre ; on l'efface alors quand même si le
# type ou le générateur ont changé.
$cache = Join-Path $Dossier "CMakeCache.txt"
$aEffacer = -not $Incrementale.IsPresent
if ($Propre.IsPresent) { $aEffacer = $true }
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
    Write-Host "MatLibre : l'arbre precedent est efface ($Dossier)"
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
# Qt est cherche tout seul dans C:\Qt ; -Qt sert quand il est ailleurs, ou
# quand plusieurs versions cohabitent et qu'on veut choisir.
if ($Qt -ne "") {
    $cheminQt = $Qt.Replace("\", "/")
    if (-not (Test-Path (Join-Path $Qt "lib\cmake\Qt6\Qt6Config.cmake"))) {
        Write-Error ("MatLibre : « $Qt » ne ressemble pas a une installation Qt6. " +
                     "Le dossier attendu est celui du compilateur, par exemple " +
                     "C:\Qt\6.11.1\mingw_64.")
    }
    $argumentsConfiguration += "-DCMAKE_PREFIX_PATH=$cheminQt"
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
    # Les binaires sortent dans <dossier>\bin ; les anciens emplacements
    # restent essayes, pour un arbre de construction deja en place.
    foreach ($essai in @((Join-Path $Dossier "bin\$nom.exe"),
                         (Join-Path $Dossier "bin\$nom"),
                         (Join-Path $Dossier "$nom.exe"),
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
$bureau = Trouver "matlibre-bureau"
if ($bureau -ne "") {
    Write-Host "  $bureau"
    Write-Host "      le bureau : une fenetre, l'editeur, les figures, l'espace de travail"
}
Write-Host "  $exe-bureau  ouvre le bureau (si Qt6 est present)"
Write-Host "  $exe         session interactive"
if ($bureau -eq "") {
    Write-Host ""
    Write-Host "Le bureau natif n'a pas ete construit : Qt6 est introuvable."
    Write-Host "S'il est installe, indiquez-le :"
    Write-Host "  .\outils\construire.ps1 -Propre -Qt C:\Qt\6.11.1\mingw_64"
}
