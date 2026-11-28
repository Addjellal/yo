# Installer MatLibre

Un compilateur C++17 et CMake suffisent. Aucune bibliothèque n'est
obligatoire : Qt6 (Widgets), s'il est présent, ajoute l'application de
bureau ; LAPACK et BLAS, s'ils sont présents, accélèrent l'algèbre
linéaire dense ; tout le reste — l'algèbre linéaire elle-même, la FFT,
les matrices creuses — est écrit dans le dépôt.

## Compiler

### Linux et macOS

```bash
./outils/construire.sh                    # compile dans build/
./outils/construire.sh --tests            # compile puis exécute les tests
./outils/construire.sh --debug            # avec les assertions
./outils/construire.sh --incrementale     # garde l'arbre au lieu de l'effacer
./outils/construire.sh --installer /usr/local
./outils/construire.sh --paquet           # archives dans build/
```

Chaque compilation part d'un arbre neuf : `build/` est effacé avant d'être
reconfiguré. Un arbre garde ce qu'on croit avoir enlevé — le `.o` d'un
fichier supprimé, une option de cache qui n'existe plus, une bibliothèque
trouvée la fois d'avant et disparue depuis —, et les pannes qui en
découlent n'arrivent que chez celui qui n'a pas effacé. Pour itérer sans
tout refaire : `--incrementale`, ou `make incrementale`.

Les binaires sortent dans `build/bin`, les bibliothèques dans `build/lib`.

Ou directement, sans passer par le script :

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

### Windows

```powershell
.\outils\construire.ps1                   # Visual Studio ou MinGW
.\outils\construire.ps1 -Tests
.\outils\construire.ps1 -Incrementale     # garde l'arbre au lieu de l'effacer
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
| Qt6 Widgets | l'application de bureau `matlibre-bureau` | `MATLIBRE_BUREAU` |
| LAPACK et BLAS (OpenBLAS, la référence, Accelerate) | le produit matriciel, `A\b` carré, `svd` et `eig` par les routines dont MATLAB se sert | `MATLIBRE_LAPACK` |

`MATLIBRE_LAPACK` vaut `AUTO` par défaut : LAPACK est employé s'il est
trouvé (`apt install libopenblas-dev`, ou `liblapack-dev` ; Accelerate
sous macOS), et le message de configuration le dit ; `OFF` s'en passe,
`ON` l'exige. Sans lui, l'algèbre linéaire écrite dans le dépôt fait le
même calcul. Sur une matrice 300 × 300, avec OpenBLAS sur un seul fil :

| calcul | sans LAPACK | avec | rapport |
| --- | ---: | ---: | ---: |
| `eig` d'une matrice symétrique | 0,31 s | 0,006 s | 55 |
| `eig` d'une matrice quelconque | 0,33 s | 0,045 s | 7 |
| `svd` | 0,31 s | 0,02 s | 15 |
| `A\b`, 500 × 500 | 0,048 s | 0,004 s | 13 |
| `A*B`, 500 × 500 | 0,050 s | 0,005 s | 10 |

Les résultats sont ceux de MATLAB, qui appelle les mêmes routines, au
dernier chiffre près ; un vecteur propre ou singulier peut changer de
signe d'un chemin à l'autre, ce qui ne change pas la décomposition. Le
paquet `.deb` d'une construction liée à LAPACK (ou au bureau) déclare ses
dépendances, que `dpkg-shlibdeps` lit dans le binaire. Les anciennes
options `MATLIBRE_AVEC_LAPACK`, `_FFTW`, `_SUITESPARSE` et `_OPENCV`,
qui liaient ces bibliothèques sans s'en servir, ont été retirées le
21 novembre 2026 ; FFTW, SuiteSparse et OpenCV ne sont pas employés.

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

Deux workflows GitHub Actions, à la racine du dépôt (GitHub ne lit que
le `.github/workflows` de la racine ; celui qu'on avait rangé dans
`matlab-libre/.github/` n'a jamais tourné, et il est retiré) :

| workflow | quand | ce qu'il fait | durée |
| --- | --- | --- | --- |
| `matlab-libre-rapide.yml` | chaque poussée et chaque demande de fusion qui touchent `matlab-libre/` | construction Release sous Ubuntu, bureau Qt compris, qui échoue au premier avertissement du compilateur ; puis `ctest -LE lent` : les vérifications C++, la ligne de commande, le bureau hors écran, les valeurs des fiches d'aide, les doublons de noms et les scripts de moins d'une minute | une dizaine de minutes |
| `matlab-libre-nuit.yml` | chaque nuit à 1 h 23 UTC, à la main, et à chaque poussée qui le modifie | la batterie complète ; la construction sans Qt, l'installation lancée d'ailleurs et les archives `.tar.gz` et `.deb` ; la batterie sous ASan et UBSan, puis `test_parallele` sous TSan ; la couverture du code C++ par la batterie, en tableau dans le résumé de la tâche ; macOS (Apple clang, Qt de Homebrew) et Windows (MinGW de MSYS2, Qt), tests rapides | deux à cinq heures, les tâches en parallèle |

GitHub ne lance un workflow planifié que depuis la branche par défaut :
la nuit ne tourne d'elle-même qu'une fois le fichier sur `main`.

Les tests qui passent la minute portent l'étiquette CTest `lent` (la
liste est dans `CMakeLists.txt`). Pendant le travail, la même passe que
l'intégration continue :

```bash
cd build && ctest -LE lent -j4     # quelques minutes
cd build && ctest -L lent -j4      # les longs seuls
```

La couverture se mesure de même chez soi :

```bash
cmake -S . -B build-couverture -DCMAKE_BUILD_TYPE=Debug -DMATLIBRE_COUVERTURE=ON
cmake --build build-couverture -j4
(cd build-couverture && ctest -LE lent -j4)
outils/couverture.sh build-couverture     # tableau Markdown, total en dernier
```
