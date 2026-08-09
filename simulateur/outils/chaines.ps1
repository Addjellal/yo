# Installe les compilateurs À CÔTÉ de l'exécutable, pour que le paquet
# portable n'exige plus rien de la machine qui le reçoit.
#
#   .\outils\chaines.ps1              installe AVR et ARM (le plus utile)
#   .\outils\chaines.ps1 -Tout        ajoute Xtensa (ESP32)
#   .\outils\chaines.ps1 -Avr         une seule famille
#
# Rien n'est stocké dans le dépôt : ces archives pèsent des centaines de
# mégaoctets et n'ont pas leur place dans un historique de code. Elles se
# rangent dans « chaines/<famille> », que le paquet emporte et où
# l'application les cherche en premier.
#
# Encombrement, une fois décompressé :
#   AVR      ~120 Mo    Arduino, ATtiny, ATmega
#   ARM      ~250 Mo    Raspberry Pi Pico, STM32
#   Xtensa   ~400 Mo    ESP32
#
# La place est le seul prix : l'application démarre aussi vite, ces
# compilateurs ne sont lancés que lorsqu'on demande une compilation.
#
# Le script décompresse l'ARBRE ENTIER de chaque chaîne, et c'est nécessaire :
# GCC cherche ses fichiers de support (device-specs, lib, include) par un
# chemin relatif à son propre binaire. Un dossier bin/ copié seul échoue avec
# un message aussi obscur que « device-specs/specs-atmega328p: No such file ».

param(
    [switch]$Tout,
    [switch]$Avr,
    [switch]$Arm,
    [switch]$Xtensa,
    # Où poser les chaînes. Par défaut à côté de l'exécutable construit.
    [string]$Dossier = ""
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if ($Dossier -eq "") {
    foreach ($candidat in @("build-paquet", "build")) {
        if (Test-Path $candidat) { $Dossier = Join-Path $candidat "chaines"; break }
    }
}
if ($Dossier -eq "") { $Dossier = "chaines" }
New-Item -ItemType Directory -Force -Path $Dossier | Out-Null

# Aucune famille demandée : les deux qui servent le plus.
if (-not ($Avr -or $Arm -or $Xtensa -or $Tout)) { $Avr = $true; $Arm = $true }
if ($Tout) { $Avr = $true; $Arm = $true; $Xtensa = $true }

$sources = @{
    avr = @{
        url = "https://github.com/ZakKemble/avr-gcc-build/releases/download/v14.1.0-1/avr-gcc-14.1.0-x64-windows.zip"
        interne = "avr-gcc-14.1.0-x64-windows"
        taille = "120 Mo"
    }
    arm = @{
        url = "https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-mingw-w64-i686-arm-none-eabi.zip"
        interne = "arm-gnu-toolchain-13.2.rel1-mingw-w64-i686-arm-none-eabi"
        taille = "250 Mo"
    }
    xtensa = @{
        url = "https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/xtensa-esp-elf-13.2.0_20240530-x86_64-w64-mingw32.zip"
        interne = "xtensa-esp-elf"
        taille = "400 Mo"
    }
}

function Installer($famille) {
    $source = $sources[$famille]
    $cible = Join-Path $Dossier $famille
    if (Test-Path (Join-Path $cible "bin")) {
        Write-Host "$famille : déjà installée." -ForegroundColor Green
        return
    }
    Write-Host "== $famille ($($source.taille)) ==" -ForegroundColor Cyan
    $archive = Join-Path $env:TEMP "chaine-$famille.zip"
    if (-not (Test-Path $archive)) {
        Write-Host "  téléchargement…"
        Invoke-WebRequest -Uri $source.url -OutFile $archive
    }
    Write-Host "  décompression…"
    $temporaire = Join-Path $env:TEMP "chaine-$famille-tmp"
    if (Test-Path $temporaire) { Remove-Item -Recurse -Force $temporaire }
    Expand-Archive -Path $archive -DestinationPath $temporaire -Force

    # L'archive contient un dossier racine : on le remonte d'un cran, pour que
    # le chemin soit toujours « chaines/<famille>/bin ».
    $racine = Get-ChildItem $temporaire | Where-Object { $_.PSIsContainer } |
              Select-Object -First 1
    if ($racine) { Move-Item $racine.FullName $cible }
    else { Move-Item $temporaire $cible }
    Remove-Item -Recurse -Force $temporaire -ErrorAction SilentlyContinue
    Write-Host "  installée dans $cible" -ForegroundColor Green
}

if ($Avr) { Installer "avr" }
if ($Arm) { Installer "arm" }
if ($Xtensa) { Installer "xtensa" }

Write-Host ""
Write-Host "Terminé. L'application cherche ces compilateurs à côté d'elle" -ForegroundColor Green
Write-Host "avant de regarder dans le PATH : le paquet est autosuffisant." -ForegroundColor Green
