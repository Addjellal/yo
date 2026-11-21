# Installer MatLibre

Un compilateur C++17 et CMake suffisent. Aucune bibliothèque n'est
obligatoire : Qt6 (Widgets), s'il est présent, ajoute l'application de
bureau ; tout le reste — algèbre linéaire, FFT, matrices creuses — est
écrit dans le dépôt.

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

Aucune bibliothèque de calcul n'est cherchée. Les options
`MATLIBRE_AVEC_LAPACK`, `MATLIBRE_AVEC_FFTW`, `MATLIBRE_AVEC_SUITESPARSE`
et `MATLIBRE_AVEC_OPENCV` ont été retirées le 21 novembre 2026 : elles
liaient ces bibliothèques sans qu'aucune ligne du code ne s'en serve, et
le paquet `.deb` héritait de dépendances qu'il ne déclarait pas. Brancher
LAPACK pour de bon est une proposition de `audit-reprise.md`.

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

Il n'y en a pas qui tourne. `.github/workflows/construire.yml` est rangé
dans `matlab-libre/`, or GitHub ne lit que le `.github/workflows` de la
racine du dépôt : ce fichier n'a jamais été exécuté. Le remplacer par un
ensemble à la racine — construction et tests rapides à chaque poussée,
batterie complète chaque nuit — est une proposition de `audit-reprise.md`.
