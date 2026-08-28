# Guide du développeur

## Compiler

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

Rien n'est obligatoire hors un compilateur C++17. Si LAPACK, BLAS ou FFTW
sont présents, ils sont détectés et liés ; sinon les algorithmes internes
prennent le relais, sans que rien ne manque.

Le `Makefile` de la racine enveloppe ces deux commandes :

```bash
make          # compile
make test     # compile et exécute toute la suite
make doc      # régénère documentation/reference/
make windows  # vérifie que la compilation pour Windows passe
make install  # installe dans /usr/local (variable PREFIX)
```

## Compiler pour Windows

Sur Windows, `outils\construire.ps1` fait tout : configuration,
compilation, tests, installation, archive. Il s'arrête au premier échec
et dit lequel — PowerShell, lui, ne s'arrête pas sur le code de retour
d'un programme externe.

```powershell
.\outils\construire.ps1                    # Release
.\outils\construire.ps1 -Tests             # compile puis teste
.\outils\construire.ps1 -Generateur "MinGW Makefiles"
```

Depuis Linux, `make windows` compile en croisé avec MinGW-w64
(`apt install g++-mingw-w64-x86-64`). Ce n'est pas la version qu'on
livre : c'est le moyen de voir tout de suite ce que la bibliothèque
standard de GNU/Linux masque — un en-tête tiré par transitivité, une
fonction POSIX employée sans garde, une bibliothèque système oubliée à
l'édition de liens.

## Arborescence

```
include/matlibre/   en-têtes publics du cœur
src/coeur/          lexeur, analyseur, interpréteur, indexation, algèbre
src/bibliotheque/   les 612 fonctions natives, par domaine
src/graphique/      rendu SVG
src/console/        l'exécutable
toolbox/            53 toolboxes écrites en langage MATLAB
tests/coeur/        tests unitaires C++
tests/scripts/      suites écrites en langage MATLAB
outils/             générateur de la référence
documentation/      ce dossier
exemples/           scripts de démonstration
```

## Ajouter une fonction native

Dans le fichier du domaine — disons `src/bibliotheque/Math.cpp` :

```cpp
FONCTION(fnHypotenuse) {
    INUTILISE
    exigerArguments(args, 2, 2, "hypotenuse");
    return {diffuser(args[0], args[1],
                     [](double a, double b) { return std::hypot(a, b); },
                     Classe::Double)};
}
```

puis, dans la fonction d'enregistrement du même fichier :

```cpp
it.enregistrer("hypotenuse", fnHypotenuse, "math",
               "hypotenuse  Longueur de l'hypotenuse.");
```

Le texte d'aide est ce que `help` affichera et ce que la référence
reprendra : il fait partie du travail, pas de la décoration.

Outils à disposition : `exigerArguments`, `argScalaire`, `argTexte`,
`dimsDepuisArguments`, `dimensionParDefaut`, `diffuser` (expansion
implicite), `appliquerReel`, `reduire` (réduction le long d'une
dimension), `parcourirTranches`.

## Ajouter une fonction de toolbox

Un fichier `.m` dans le dossier de la toolbox, portant le nom de la
fonction, avec son bloc d'aide juste après la ligne `function`. Rien à
recompiler. Ajoutez la ligne correspondante au `Contents.m`.

## Ajouter une toolbox

Un dossier sous `toolbox/`, un `Contents.m` qui nomme la toolbox
MathWorks correspondante, et les fichiers `.m`. Le dossier est ajouté au
chemin de recherche au démarrage, sans autre déclaration.

## Tests

```bash
./build/matlibre_tests                       # 57 vérifications C++
./build/matlibre tests/scripts/test_langage.m
ctest --test-dir build --output-on-failure   # tout
```

Une suite en langage MATLAB est un fichier `test_*.m` qui appelle
`assert`. La règle est de comparer à une valeur exacte connue, pas de
vérifier qu'un appel « ne plante pas » :

```matlab
[call, put] = blsprice(100, 100, 0.05, 1, 0.2);
assert(abs(call - 10.4506) < 1e-3);
```

`assert` accepte les deux formes : `assert(condition, message)` comme
MATLAB, et `assert(observé, attendu, tolérance)` comme Octave.

## Régénérer la référence

```bash
./build/matlibre outils/genererReference.m
```

Le générateur est écrit dans le langage qu'il documente : s'il tourne, une
bonne partie de l'interpréteur tourne aussi.

## Conventions

- Le code source parle français : noms de fichiers, de fonctions internes,
  de variables, et commentaires. Les noms exposés à l'utilisateur sont
  ceux de MATLAB — c'est le contrat.
- Un commentaire dit pourquoi, pas quoi. Les commentaires qui paraphrasent
  la ligne suivante sont retirés en revue.
- Les messages d'erreur reprennent l'identifiant et le texte de MATLAB :
  c'est ce qui permet à un `try/catch` existant de fonctionner.
- Quatre espaces d'indentation, lignes de 90 colonnes au plus.
