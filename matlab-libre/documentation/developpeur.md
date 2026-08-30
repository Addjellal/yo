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
make              # compile
make test         # compile et exécute toute la suite
make doc          # régénère documentation/reference/
make windows      # vérifie que la compilation pour Windows passe
make incrementale # recompile sans effacer l'arbre
make install      # installe dans /usr/local (variable PREFIX)
```

Chaque compilation part d'un arbre neuf : `build/` est effacé avant d'être
reconfiguré. Un arbre garde ce qu'on croit avoir enlevé — le `.o` d'un
fichier supprimé, une option de cache qui n'existe plus, une bibliothèque
trouvée la fois d'avant et disparue depuis. Effacer coûte quelques
minutes ; chercher pourquoi « ça ne compile que chez moi » en coûte
davantage. Pour itérer en boucle courte : `make incrementale`, ou
n'importe quelle cible avec `NEUF=0`.

Les binaires sortent dans `build/bin`, les bibliothèques dans `build/lib`.
Les scripts d'empaquetage — `outils/construire.sh` et
`outils/construire.ps1` — vident le reste en partant : objets, caches,
projets générés. Il ne reste que `bin/`, `lib/` et les archives. Là encore,
`--incrementale` (`-Incrementale`) garde tout, pour itérer.

Les toolboxes sont cherchées à côté de l'exécutable — c'est
`racineToolboxes` de [`include/matlibre/Installation.h`](../include/matlibre/Installation.h)
qui décide, et la console comme le bureau l'appellent. Sans elle, un
binaire lancé depuis l'arbre de construction n'aurait que ses fonctions
natives.

## Compiler pour Windows

Sur Windows, `outils\construire.ps1` fait tout : configuration,
compilation, tests, installation, archive. Il s'arrête au premier échec
et dit lequel — PowerShell, lui, ne s'arrête pas sur le code de retour
d'un programme externe.

```powershell
.\outils\construire.ps1                    # Release
.\outils\construire.ps1 -Tests             # compile puis teste
.\outils\construire.ps1 -Incrementale      # garde l'arbre
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
src/coeur/          lexeur, analyseur, interpréteur, indexation, algèbre,
                    format MAT et décompression DEFLATE
src/bibliotheque/   les 620 fonctions natives, par domaine
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
./build/bin/matlibre_tests                       # 57 vérifications C++
./build/bin/matlibre tests/scripts/test_langage.m
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

## Éprouver les fonctions natives

```bash
./outils/eprouverNatives.sh
```

Chaque fonction native est appelée avec des arguments qu'elle n'attend
pas — une cellule, une structure, une poignée, une taille absurde, une
dimension négative — chacun dans son propre processus. Une erreur MATLAB
est le bon comportement ; un plantage n'en est jamais un. C'est là que se
logent les défauts qu'aucun test ne trouve : une fonction qui parcourt
`re` d'une valeur qui n'en a pas lit hors de la mémoire, et le programme
tombe — parfois bien plus loin, à l'affichage. Trois gardes couvrent le
cas : `exigerNumerique`, `exigerSansObjet` et `argTaille`, dans
`src/bibliotheque/Communs.cpp`. Le passage prend une demi-heure.

## Régénérer la référence

```bash
./build/bin/matlibre outils/genererReference.m
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
