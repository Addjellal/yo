# Systeme, chemin et aide

Fonctions natives du groupe `systeme`.

## `addpath`

```
addpath  Ajoute au chemin de recherche.
```

## `atelier`

```
atelier  Synonyme de ide.
```

## `beep`

```
beep  Emet un bip.
```

## `cd`

```
cd  Change de dossier.
```

## `clc`

```
clc  Efface l'ecran.
```

## `clear`

```
clear  Efface des variables.
```

## `computer`

```
computer  Plateforme d'execution.
```

## `copyfile`

```
copyfile  Copie un fichier.
```

## `delete`

```
delete  Supprime des fichiers.
```

## `diary`

```
diary  Journalise la session.
```

## `dir`

```
dir  Liste un dossier.
```

## `doc`

```
doc  Aide d'une fonction.
```

## `dos`

```
dos  Execute une commande du systeme.
```

## `exit`

```
exit  Quitte l'interpreteur.
```

## `fileparts`

```
fileparts  Decompose un chemin.
```

## `filesep`

```
filesep  Separateur de chemin.
```

## `fullfile`

```
fullfile  Assemble un chemin.
```

## `getenv`

```
getenv  Variable d'environnement.
```

## `getpid`

```
getpid  Identifiant du processus.
```

## `graphics_toolkit`

```
graphics_toolkit  Moteur graphique utilise.
```

## `help`

```
HELP  Aide d'une fonction.
    HELP NOM affiche l'aide de la fonction NOM : sa syntaxe, ce qu'elle
    fait, des exemples et les fonctions voisines.
    T = HELP(NOM) rend ce texte au lieu de l'afficher.
    HELP seul rappelle les commandes d'orientation.

    Syntaxe
       help nom
       help('nom')
       t = help('nom')

    Exemples
       help fft
       help gca
       t = help('sort');

    Voir aussi DOC, LOOKFOR, WHICH, VER, IDE.
```

## `ide`

```
IDE  Ouvre l'atelier dans le navigateur.
    IDE ouvre l'atelier : éditeur de scripts avec coloration et points
    d'arrêt, console, table des variables, figures, profileur, concepteur
    d'applications et éditeur de schémas-blocs.
    IDE(PORT) choisit le port ; 8421 par défaut.

    L'atelier tourne dans un second processus et a son propre espace de
    travail, séparé de celui de la console.

    Pour un bureau natif — une fenêtre, pas un navigateur — lancer
    « matlibre-bureau ».

    Syntaxe
       ide
       ide(port)

    Exemples
       ide
       ide(9000)

    Voir aussi HELP, VER.
```

## `isfile`

```
isfile  Vrai pour un fichier ordinaire.
```

## `isfolder`

```
isfolder  Vrai pour un dossier.
```

## `ismac`

```
ismac  Systeme macOS ?
```

## `ispc`

```
ispc  Systeme Windows ?
```

## `isunix`

```
isunix  Systeme de type UNIX ?
```

## `lookfor`

```
lookfor  Cherche dans les aides.
```

## `ls`

```
ls  Liste un dossier.
```

## `matlibre_fonctions`

```
matlibre_fonctions  Liste des fonctions natives et de leur groupe.
```

## `matlibre_racine`

```
matlibre_racine  Dossier racine des toolboxes.
```

## `maxNumCompThreads`

```
maxNumCompThreads  Nombre de fils de calcul.
```

## `memory`

```
memory  Memoire disponible.
```

## `mexext`

```
mexext  Extension des fichiers MEX de cette plateforme.
```

## `mfilename`

```
mfilename  Nom du fichier en cours d'execution.
```

## `mkdir`

```
mkdir  Cree un dossier.
```

## `more`

```
more  Pagination (sans effet).
```

## `movefile`

```
movefile  Deplace un fichier.
```

## `path`

```
path  Chemin de recherche.
```

## `pathsep`

```
pathsep  Separateur de liste de chemins.
```

## `pwd`

```
pwd  Dossier courant.
```

## `quit`

```
quit  Quitte l'interpreteur.
```

## `rehash`

```
rehash  Reconstruit l'index du chemin.
```

## `rmdir`

```
rmdir  Supprime un dossier.
```

## `rmpath`

```
rmpath  Retire du chemin de recherche.
```

## `setenv`

```
setenv  Pose une variable d'environnement.
```

## `system`

```
system  Execute une commande du systeme.
```

## `tempdir`

```
tempdir  Dossier temporaire.
```

## `tempname`

```
tempname  Nom de fichier temporaire.
```

## `type`

```
type  Affiche le source d'un fichier.
```

## `unix`

```
unix  Execute une commande du systeme.
```

## `ver`

```
ver  Version detaillee.
```

## `version`

```
version  Version de l'interpreteur.
```

## `which`

```
WHICH  Où se trouve une fonction.
    WHICH NOM affiche le chemin du fichier qui définit NOM, ou signale
    une fonction native.
    S = WHICH(NOM) rend ce chemin.
    WHICH NOM -all liste toutes les définitions visibles : c'est ainsi
    qu'on trouve un masquage.

    Syntaxe
       which nom
       s = which('nom')
       which nom -all

    Exemples
       which fft
       which butter

    Voir aussi EXIST, PATH, HELP, TYPE.
```

## `who`

```
who  Liste les variables.
```

## `whos`

```
whos  Liste detaillee des variables.
```

