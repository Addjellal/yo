# Systeme, chemin et aide

Fonctions natives du groupe `systeme`.

## `addpath`

```
ADDPATH  Ajoute un dossier au chemin de recherche.
    ADDPATH(D) ajoute D en tête du chemin : les fonctions qui s'y trouvent
    deviennent appelables.
    ADDPATH(D,'-end') l'ajoute à la fin.

    Syntaxe
       addpath(dossier)
       addpath(dossier,'-end')

    Exemples
       d = tempdir;
       addpath(d);
       rmpath(d);

    Voir aussi RMPATH, PATH, WHICH, REHASH.
```

## `beep`

```
BEEP  Émet un signal sonore.
    BEEP ON et BEEP OFF autorisent ou interdisent le signal.

    Syntaxe
       beep
       beep on
       beep off

    Exemples
       beep off
       beep

    Voir aussi DISP, WARNING, PAUSE.
```

## `cd`

```
CD  Change de dossier.
    CD(CHEMIN) va dans le dossier donné.
    CD .. remonte d'un cran.
    P = CD rend le dossier courant sans en changer.

    Syntaxe
       cd(chemin)
       cd ..
       p = cd

    Exemples
       avant = pwd;
       cd(tempdir);
       cd(avant);

    Voir aussi PWD, DIR, LS, ADDPATH.
```

## `clc`

```
CLC  Efface la fenêtre de commandes.
    CLC vide l'affichage ; les variables, elles, ne bougent pas — c'est
    CLEAR qui les efface.

    Syntaxe
       clc

    Exemples
       clc

    Voir aussi CLEAR, CLOSE, HOME, DIARY.
```

## `clear`

```
CLEAR  Efface des variables de l'espace de travail.
    CLEAR efface tout.
    CLEAR A B efface les variables nommées.
    CLEAR ALL efface aussi les fonctions en cache.

    Syntaxe
       clear
       clear a b
       clear all

    Exemples
       aEffacer = 1;
       clear aEffacer
       exist('aEffacer','var')        % 0

    Voir aussi CLC, WHO, WHOS, EXIST.
```

## `computer`

```
COMPUTER  Nom de la plate-forme.
    COMPUTER rend 'GLNXA64', 'MACA64', 'PCWIN64'… selon le système.

    Syntaxe
       c = computer

    Exemples
       computer
       ispc || isunix || ismac

    Voir aussi ISPC, ISUNIX, ISMAC, VERSION.
```

## `copyfile`

```
COPYFILE  Copie un fichier.
    COPYFILE(SOURCE,CIBLE) copie ; [OK,MSG] = COPYFILE(...) rend un compte
    rendu au lieu d'une erreur.

    Syntaxe
       copyfile(source,cible)
       [ok,msg] = copyfile(source,cible)

    Exemples
       a = fullfile(tempdir, 'a.txt');
       b = fullfile(tempdir, 'b.txt');
       fid = fopen(a,'w'); fprintf(fid,'x'); fclose(fid);
       copyfile(a, b);
       isfile(b)
       delete(a); delete(b);

    Voir aussi MOVEFILE, DELETE, ISFILE.
```

## `delete`

```
DELETE  Supprime un fichier.
    DELETE(NOM) efface le fichier ; le motif '*.txt' en efface plusieurs.

    Syntaxe
       delete(nom)

    Exemples
       f = fullfile(tempdir, 'essai.txt');
       fid = fopen(f, 'w'); fprintf(fid, 'x'); fclose(fid);
       delete(f);
       isfile(f)                      % 0

    Voir aussi RMDIR, ISFILE, DIR, MOVEFILE.
```

## `diary`

```
DIARY  Enregistre la session dans un fichier.
    DIARY ON commence l'enregistrement dans « diary », DIARY OFF l'arrête.
    DIARY(NOM) enregistre dans le fichier nommé.

    Syntaxe
       diary on
       diary off
       diary(nom)

    Exemples
       f = fullfile(tempdir,'journal.txt');
       diary(f);
       disp('ceci est enregistré');
       diary off
       delete(f);

    Voir aussi FPRINTF, EVALC, DISP.
```

## `dir`

```
DIR  Contenu d'un dossier.
    DIR rend la liste du dossier courant, sous forme d'un tableau de
    structures : champs name, folder, bytes, isdir.
    DIR(MOTIF) filtre : dir('*.m').

    Syntaxe
       s = dir
       s = dir(motif)

    Exemples
       fichiers = dir;
       isstruct(fichiers)
       fieldnames(fichiers)
       nombreM = numel(dir('*.m'));

    Voir aussi LS, PWD, EXIST, ISFOLDER, FULLFILE.
```

## `doc`

```
DOC  Documentation d'une fonction.
    DOC NOM affiche l'aide détaillée — la même que HELP, dans la
    présentation longue.

    Syntaxe
       doc nom

    Exemples
       doc fft
       doc('plot');

    Voir aussi HELP, LOOKFOR, WHICH, TYPE.
```

## `dos`

```
DOS  Exécute une commande de l'invite, sous Windows.
    [ETAT,SORTIE] = DOS(COMMANDE) rend le code de retour et la sortie.

    Syntaxe
       etat = dos(commande)
       [etat,sortie] = dos(commande)

    Exemples
       if ispc
           [etat, sortie] = dos('echo bonjour');
       end

    Voir aussi SYSTEM, UNIX, ISPC.
```

## `exit`

```
EXIT  Quitte MatLibre ; synonyme de QUIT.

    Syntaxe
       exit

    Exemples
       % exit                              % ferme la session

    Voir aussi QUIT, CLEAR, DIARY.
```

## `fileparts`

```
FILEPARTS  Découpe un chemin.
    [DOSSIER,NOM,EXT] = FILEPARTS(CHEMIN) sépare le dossier, le nom et
    l'extension — point compris.

    Syntaxe
       [dossier,nom,ext] = fileparts(chemin)

    Exemples
       [d,n,e] = fileparts('/tmp/essai.m');
       n
       e                              % '.m'
       [~,nom] = fileparts('rapport.pdf');

    Voir aussi FULLFILE, FILESEP, EXIST, DIR.
```

## `filesep`

```
FILESEP  Séparateur de chemin du système : « / » ou « \ ».

    Syntaxe
       s = filesep

    Exemples
       filesep
       ['dossier' filesep 'fichier']  % mais FULLFILE est préférable

    Voir aussi FULLFILE, FILEPARTS, PATHSEP.
```

## `fullfile`

```
FULLFILE  Assemble un chemin avec le bon séparateur.
    FULLFILE(A,B,...) colle les morceaux avec « / » ou « \ » selon le
    système, sans jamais en doubler un.

    Syntaxe
       chemin = fullfile(a,b,...)

    Exemples
       fullfile('dossier', 'fichier.txt')
       fullfile(tempdir, 'essai.mat')
       fullfile('a', 'b', 'c.m')

    Voir aussi FILEPARTS, FILESEP, PATHSEP, EXIST.
```

## `getenv`

```
GETENV  Lit une variable d'environnement.
    GETENV(NOM) rend sa valeur, ou le texte vide si elle n'existe pas.

    Syntaxe
       v = getenv(nom)

    Exemples
       setenv('MATLIBRE_ESSAI', 'oui');
       getenv('MATLIBRE_ESSAI')
       isempty(getenv('VARIABLE_QUI_NEXISTE_PAS'))

    Voir aussi SETENV, SYSTEM, COMPUTER.
```

## `getpid`

```
GETPID  Numéro du processus courant.

    Syntaxe
       p = getpid

    Exemples
       p = getpid;
       p > 0

    Voir aussi SYSTEM, COMPUTER, GETENV.
```

## `graphics_toolkit`

```
GRAPHICS_TOOLKIT  Le moteur de rendu graphique employé.
    GRAPHICS_TOOLKIT rend le nom du moteur qui dessine les figures. C'est
    le nom d'Octave ; MatLibre le garde pour que les scripts qui
    l'interrogent ne s'arrêtent pas. Le rendu se fait en SVG, un format
    vectoriel qu'aucune bibliothèque externe n'est nécessaire pour
    produire.

    Syntaxe
       nom = graphics_toolkit

    Exemples
       graphics_toolkit       % 'svg'
       strcmp(graphics_toolkit(), 'svg')      % vrai

    Voir aussi FIGURE, PRINT, SAVEAS, PLOT.
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

## `isfile`

```
ISFILE  Le chemin désigne-t-il un fichier.

    Syntaxe
       tf = isfile(chemin)

    Exemples
       isfile(tempdir)                % 0 — c'est un dossier
       f = fullfile(tempdir,'x.txt');
       fid = fopen(f,'w'); fclose(fid);
       isfile(f)                      % 1
       delete(f);

    Voir aussi ISFOLDER, EXIST, DIR.
```

## `isfolder`

```
ISFOLDER  Le chemin désigne-t-il un dossier.

    Syntaxe
       tf = isfolder(chemin)

    Exemples
       isfolder(tempdir)              % 1
       isfolder('n''existe pas')      % 0

    Voir aussi ISFILE, EXIST, MKDIR, DIR.
```

## `ismac`

```
ISMAC  Tourne-t-on sous macOS.

    Syntaxe
       tf = ismac

    Exemples
       ismac
       if ismac, disp('macOS'); end

    Voir aussi ISPC, ISUNIX, COMPUTER.
```

## `ispc`

```
ISPC  Tourne-t-on sous Windows.

    Syntaxe
       tf = ispc

    Exemples
       ispc
       if ispc, sep = '\'; else, sep = '/'; end
       isequal(sep, filesep)

    Voir aussi ISUNIX, ISMAC, COMPUTER, FILESEP.
```

## `isunix`

```
ISUNIX  Tourne-t-on sous Linux ou macOS.

    Syntaxe
       tf = isunix

    Exemples
       isunix
       ispc + isunix                  % l'un ou l'autre

    Voir aussi ISPC, ISMAC, COMPUTER.
```

## `lookfor`

```
LOOKFOR  Cherche un mot dans la première ligne d'aide des fonctions.
    LOOKFOR MOT liste les fonctions dont le résumé contient le mot : c'est
    ainsi qu'on trouve une fonction dont on ignore le nom.

    Syntaxe
       lookfor mot

    Exemples
       lookfor fourier
       lookfor('inverse');

    Voir aussi HELP, DOC, WHICH, EXIST.
```

## `ls`

```
LS  Liste les fichiers d'un dossier.
    LS affiche le dossier courant ; S = LS le rend en texte.
    LS(MOTIF) filtre.

    Syntaxe
       ls
       s = ls
       ls(motif)

    Exemples
       s = ls;
       ischar(s) || iscell(s)

    Voir aussi DIR, PWD, CD, EXIST.
```

## `matlibre_aide_structuree`

```
matlibre_aide_structuree  Aide decoupee en sections.
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
MAXNUMCOMPTHREADS  Nombre de fils de calcul utilisés.
    N = MAXNUMCOMPTHREADS rend le nombre courant.
    MAXNUMCOMPTHREADS(N) le fixe.

    Syntaxe
       n = maxNumCompThreads
       maxNumCompThreads(n)

    Exemples
       n = maxNumCompThreads;
       n >= 1

    Voir aussi PARPOOL, NUMLABS, MEMORY.
```

## `memory`

```
MEMORY  Mémoire disponible.
    MEMORY affiche l'état ; S = MEMORY le rend en structure.

    Syntaxe
       memory
       s = memory

    Exemples
       s = memory;
       isstruct(s)

    Voir aussi WHOS, CLEAR, COMPUTER.
```

## `mexext`

```
MEXEXT  Extension des fichiers MEX de la plate-forme.

    Syntaxe
       e = mexext

    Exemples
       mexext
       ischar(mexext)

    Voir aussi COMPUTER, VERSION, MEX.
```

## `mfilename`

```
MFILENAME  Nom du fichier en cours d'exécution.
    MFILENAME rend le nom sans extension du script ou de la fonction qui
    l'appelle, et le texte vide à l'invite.
    MFILENAME('fullpath') rend le chemin complet, sans extension.

    Syntaxe
       nom = mfilename
       chemin = mfilename('fullpath')

    Exemples
       nom = mfilename;
       ischar(nom)

    Voir aussi WHICH, INPUTNAME, DBSTACK, EXIST.
```

## `mkdir`

```
MKDIR  Crée un dossier.
    MKDIR(D) crée le dossier D, avec ses parents au besoin.
    [OK,MESSAGE] = MKDIR(D) rend un compte rendu au lieu d'une erreur.

    Syntaxe
       mkdir(dossier)
       [ok,message] = mkdir(dossier)

    Exemples
       d = fullfile(tempdir, 'essaiMatLibre');
       mkdir(d);
       isfolder(d)
       rmdir(d);

    Voir aussi RMDIR, ISFOLDER, DIR, DELETE.
```

## `more`

```
MORE  Pagination de l'affichage.
    MORE ON coupe l'affichage page par page, MORE OFF le laisse défiler.

    Syntaxe
       more on
       more off

    Exemples
       more off

    Voir aussi DIARY, DISP, FORMAT.
```

## `movefile`

```
MOVEFILE  Déplace ou renomme un fichier.

    Syntaxe
       movefile(source,cible)
       [ok,msg] = movefile(source,cible)

    Exemples
       a = fullfile(tempdir, 'a.txt');
       b = fullfile(tempdir, 'b.txt');
       fid = fopen(a,'w'); fprintf(fid,'x'); fclose(fid);
       movefile(a, b);
       isfile(a)                      % 0
       delete(b);

    Voir aussi COPYFILE, DELETE, DIR.
```

## `path`

```
PATH  Chemin de recherche.
    PATH affiche le chemin ; P = PATH le rend en texte, les dossiers
    séparés par PATHSEP.

    Syntaxe
       path
       p = path

    Exemples
       p = path;
       dossiers = strsplit(p, pathsep);
       numel(dossiers) > 0

    Voir aussi ADDPATH, RMPATH, PATHSEP, WHICH, REHASH.
```

## `pathsep`

```
PATHSEP  Séparateur des dossiers dans le chemin de recherche.
    PATHSEP rend « : » sous Unix et « ; » sous Windows.

    Syntaxe
       s = pathsep

    Exemples
       pathsep
       dossiers = strsplit(path, pathsep);
       numel(dossiers) >= 1

    Voir aussi PATH, FILESEP, ADDPATH, FULLFILE.
```

## `pwd`

```
PWD  Dossier courant.
    PWD rend le chemin du dossier courant.

    Syntaxe
       p = pwd

    Exemples
       p = pwd;
       ischar(p)
       cd(p);                         % on y reste

    Voir aussi CD, DIR, FULLFILE, WHAT.
```

## `quit`

```
QUIT  Quitte MatLibre.
    QUIT ferme la session ; EXIT en est le synonyme.

    Syntaxe
       quit
       exit

    Exemples
       % quit                         % ferme la session

    Voir aussi EXIT, CLEAR, DIARY.
```

## `rehash`

```
REHASH  Reconstruit l'index des fonctions du chemin.
    REHASH fait relire les dossiers du chemin : un fichier qu'on vient
    d'écrire devient appelable sans redémarrer.

    Syntaxe
       rehash

    Exemples
       rehash

    Voir aussi ADDPATH, PATH, WHICH, EXIST.
```

## `rmdir`

```
RMDIR  Supprime un dossier.
    RMDIR(D) supprime le dossier s'il est vide.
    RMDIR(D,'s') le supprime avec son contenu.

    Syntaxe
       rmdir(dossier)
       rmdir(dossier,'s')

    Exemples
       d = fullfile(tempdir,'aSupprimer');
       mkdir(d);
       rmdir(d);
       isfolder(d)                    % 0

    Voir aussi MKDIR, DELETE, ISFOLDER, DIR.
```

## `rmpath`

```
RMPATH  Retire un dossier du chemin de recherche.

    Syntaxe
       rmpath(dossier)

    Exemples
       d = tempdir;
       addpath(d);
       rmpath(d);

    Voir aussi ADDPATH, PATH, WHICH.
```

## `setenv`

```
SETENV  Écrit une variable d'environnement.

    Syntaxe
       setenv(nom,valeur)

    Exemples
       setenv('MATLIBRE_ESSAI', '42');
       str2double(getenv('MATLIBRE_ESSAI'))

    Voir aussi GETENV, SYSTEM.
```

## `system`

```
SYSTEM  Exécute une commande du système.
    [ETAT,SORTIE] = SYSTEM(COMMANDE) rend le code de retour et la sortie.

    Syntaxe
       etat = system(commande)
       [etat,sortie] = system(commande)

    Exemples
       [etat, sortie] = system('echo bonjour');
       etat                           % 0
       strtrim(sortie)

    Voir aussi DOS, UNIX, GETENV, COMPUTER.
```

## `tempdir`

```
TEMPDIR  Dossier des fichiers temporaires du système.

    Syntaxe
       d = tempdir

    Exemples
       d = tempdir;
       isfolder(d)

    Voir aussi TEMPNAME, FULLFILE, MKDIR.
```

## `tempname`

```
TEMPNAME  Nom de fichier temporaire, unique.

    Syntaxe
       f = tempname

    Exemples
       f = tempname;
       isfile(f)                      % 0 — il n'existe pas encore

    Voir aussi TEMPDIR, FULLFILE, FOPEN.
```

## `type`

```
TYPE  Affiche le contenu d'un fichier.
    TYPE NOM affiche le fichier, comme « cat » d'un terminal.

    Syntaxe
       type nom

    Exemples
       f = fullfile(tempdir,'t.m');
       fid = fopen(f,'w'); fprintf(fid,'a = 1;\n'); fclose(fid);
       type(f)
       delete(f);

    Voir aussi FILEREAD, DIR, WHICH, EDIT.
```

## `unix`

```
UNIX  Exécute une commande du shell, sous Linux et macOS.
    [ETAT,SORTIE] = UNIX(COMMANDE) rend le code de retour et la sortie.

    Syntaxe
       etat = unix(commande)
       [etat,sortie] = unix(commande)

    Exemples
       if isunix
           [etat, sortie] = unix('echo bonjour');
           strtrim(sortie)
       end

    Voir aussi SYSTEM, DOS, ISUNIX, GETENV.
```

## `ver`

```
VER  Versions installées.
    VER affiche la version du noyau et des toolboxes ; S = VER les rend en
    structure.

    Syntaxe
       ver
       s = ver

    Exemples
       s = ver;
       isstruct(s)

    Voir aussi VERSION, COMPUTER, WHICH.
```

## `version`

```
VERSION  Version de MatLibre.

    Syntaxe
       v = version

    Exemples
       version
       ischar(version)

    Voir aussi VER, COMPUTER, MEXEXT.
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
WHO  Liste les variables de l'espace de travail.
    WHO affiche les noms ; C = WHO les rend en cellule.

    Syntaxe
       who
       c = who

    Exemples
       uneVariable = 1;
       c = who;
       any(strcmp(c, 'uneVariable'))

    Voir aussi WHOS, CLEAR, EXIST.
```

## `whos`

```
WHOS  Liste les variables avec leur taille et leur classe.
    WHOS affiche un tableau ; S = WHOS le rend en structure.

    Syntaxe
       whos
       s = whos

    Exemples
       uneMatrice = magic(4);
       s = whos;
       isstruct(s)

    Voir aussi WHO, CLEAR, CLASS, SIZE.
```

