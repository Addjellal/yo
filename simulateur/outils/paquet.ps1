# Fabrique le paquet portable Windows.
#
#   .\outils\paquet.ps1
#   .\outils\paquet.ps1 -Qt "C:\Qt\6.11.1\mingw_64"
#
# Produit « build-paquet\simulateur-embarque-<version>-windows-x64.zip » :
# un dossier qui se décompresse n'importe où et se lance par un double-clic,
# sans rien installer.

param(
    # Dossier de Qt, si CMake ne le trouve pas tout seul.
    [string]$Qt = "",
    # Compilateur à employer. Sous Windows il DOIT être celui avec lequel Qt
    # a été construit, sinon l'édition de liens échoue sur Qt6EntryPoint.
    [string]$Compilateur = "",
    [string]$Dossier = "build-paquet"
)

$ErrorActionPreference = "Stop"
$racine = Split-Path -Parent $PSScriptRoot

$arguments = @(
    "-S", $racine,
    "-B", (Join-Path $racine $Dossier),
    "-DCMAKE_BUILD_TYPE=Release",
    # Le paquet ne doit dépendre que de Qt : les moteurs de simulation sont
    # dans l'exécutable, on ignore ngspice et simavr même s'ils traînent.
    "-DSIM_AUTONOME=ON"
)
if ($Qt -ne "") { $arguments += "-DCMAKE_PREFIX_PATH=$Qt" }
if ($Compilateur -ne "") { $arguments += "-DCMAKE_CXX_COMPILER=$Compilateur" }
if (Get-Command ninja -ErrorAction SilentlyContinue) { $arguments += @("-G", "Ninja") }

Write-Host "Configuration..." -ForegroundColor Cyan
& cmake @arguments
if ($LASTEXITCODE -ne 0) { throw "la configuration a échoué" }

Write-Host "Compilation et mise en paquet..." -ForegroundColor Cyan
& cmake --build (Join-Path $racine $Dossier) --target paquet
if ($LASTEXITCODE -ne 0) { throw "la fabrication du paquet a échoué" }

$archive = Get-ChildItem (Join-Path $racine $Dossier) -Filter "*.zip" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($archive) {
    Write-Host ""
    Write-Host "Paquet prêt : $($archive.FullName)" -ForegroundColor Green
    Write-Host ("Taille : {0:N1} Mo" -f ($archive.Length / 1MB))
    Write-Host "Il se décompresse où l'on veut et se lance par simulateur.exe."
} else {
    Write-Warning "Aucune archive .zip trouvée dans $Dossier"
}
