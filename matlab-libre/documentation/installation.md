# Installer MatLibre

Un compilateur C++17 et CMake suffisent. Aucune bibliothèque n'est
obligatoire : LAPACK, BLAS, FFTW, SuiteSparse et OpenCV sont utilisés
s'ils sont présents, uniquement pour aller plus vite ou lire plus de
formats d'image.

## Compiler

### Linux et macOS

```bash
./outils/construire.sh                    # compile dans build/
./outils/construire.sh --tests            # compile puis exécute les tests
./outils/construire.sh --debug            # avec les assertions
./outils/construire.sh --installer /usr/local
./outils/construire.sh --paquet           # archives dans build/
```

Ou directement :

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

### Windows

```powershell
.\outils\construire.ps1                   # Visual Studio ou MinGW
.\outils\construire.ps1 -Tests
.\outils\construire.ps1 -Installer C:\MatLibre
.\outils\construire.ps1 -Paquet
```

### Presets CMake

`CMakePresets.json` définit `linux`, `linux-debug`, `macos` et
`windows` :

```bash
cmake --preset linux && cmake --build build
```

## Ce que produit l'installation

```
<préfixe>/bin/matlibre                  l'interpréteur
<préfixe>/bin/matlibre-bureau           le bureau natif, si Qt6 est présent
<préfixe>/share/matlibre/               les toolboxes et les fiches d'aide
<préfixe>/share/doc/MatLibre/           la documentation
```

L'exécutable trouve les toolboxes tout seul : il regarde
`../share/matlibre`, puis `../toolbox`, puis `./toolbox`, et enfin la
variable d'environnement `MATLIBRE_TOOLBOX`. Les fiches d'aide de `doc` et
`help` vivent dans `toolbox/aide/`, et suivent donc le même chemin.

## Paquets

`cpack` fabrique une archive par système :

| Système | Formats |
| --- | --- |
| Linux | `.tar.gz` et `.deb` |
| macOS | `.tar.gz` |
| Windows | `.zip` |

```bash
cd build && cpack
```

## Dépendances optionnelles

| Bibliothèque | Ce qu'elle apporte | Option CMake |
| --- | --- | --- |
| LAPACK / BLAS | algèbre linéaire dense plus rapide | `MATLIBRE_AVEC_LAPACK` |
| FFTW | transformées de Fourier plus rapides | `MATLIBRE_AVEC_FFTW` |
| SuiteSparse | grands systèmes creux | `MATLIBRE_AVEC_SUITESPARSE` |
| OpenCV | lecture et écriture d'images élargies | `MATLIBRE_AVEC_OPENCV` |

Chacune est cherchée automatiquement ; la configuration dit ce qu'elle a
trouvé. Pour s'en passer explicitement :

```bash
cmake -S . -B build -DMATLIBRE_AVEC_LAPACK=OFF -DMATLIBRE_AVEC_FFTW=OFF
```

Les algorithmes internes donnent les mêmes résultats — les tests passent
dans les deux cas.

## Gérer les toolboxes

Depuis le langage, comme dans MATLAB :

```matlab
t = matlab.addons.installedAddons;              % la liste, en table
matlab.addons.toolbox.installToolbox('/tmp/maToolbox');
matlab.addons.toolbox.uninstallToolbox('maToolbox');
matlab.addons.toolbox.packageToolbox('maToolbox', 'maToolbox.zip');
```

Une toolbox est un dossier qui contient un `Contents.m` et des fichiers
`.m`. L'installer, c'est le copier sous `matlabroot` et l'ajouter au
chemin de recherche.

## Intégration continue

`.github/workflows/construire.yml` compile et teste sur Ubuntu, macOS et
Windows, et fabrique les archives.
