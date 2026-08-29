# deboguage

Fonctions natives du groupe `deboguage`.

## `dbclear`

```
DBCLEAR  Retire des points d'arrêt.
    DBCLEAR ALL les retire tous.
    DBCLEAR IN fichier retire ceux d'un fichier.

    Syntaxe
       dbclear all
       dbclear in fichier

    Exemples
       dbstop if error
       dbclear all
       dbstatus

    Voir aussi DBSTOP, DBSTATUS.
```

## `dbcont`

```
DBCONT  Reprend l'exécution après un point d'arrêt.

    Syntaxe
       dbcont

    Exemples
       % À l'invite « K>> » : dbcont reprend jusqu'au prochain arrêt.
       disp('dbcont s''emploie à l''arrêt');

    Voir aussi DBSTOP, DBSTEP, DBQUIT.
```

## `dbquit`

```
DBQUIT  Abandonne le débogage et rend la main à l'invite.

    Syntaxe
       dbquit

    Exemples
       % À l'invite « K>> » : dbquit abandonne l'exécution en cours.
       disp('dbquit s''emploie à l''arrêt');

    Voir aussi DBSTOP, DBCONT, DBSTEP.
```

## `dbstack`

```
DBSTACK  Pile des appels.
    DBSTACK affiche la pile ; S = DBSTACK la rend en structure, champs
    file, name et line.

    Syntaxe
       dbstack
       s = dbstack

    Exemples
       s = dbstack;
       isstruct(s)

    Voir aussi DBSTOP, DBSTEP, MFILENAME, ERROR.
```

## `dbstatus`

```
DBSTATUS  Liste les points d'arrêt posés.

    Syntaxe
       dbstatus
       s = dbstatus

    Exemples
       dbclear all
       dbstatus

    Voir aussi DBSTOP, DBCLEAR.
```

## `dbstep`

```
DBSTEP  Avance d'une ligne dans le débogueur.
    DBSTEP exécute la ligne courante et s'arrête à la suivante.
    DBSTEP IN entre dans l'appel ; DBSTEP OUT en sort.

    Syntaxe
       dbstep
       dbstep in
       dbstep out

    Exemples
       % À l'invite « K>> » d'un point d'arrêt :
       %   dbstep        % ligne suivante
       %   dbstep in     % entrer dans l'appel
       disp('dbstep s''emploie à l''arrêt');

    Voir aussi DBSTOP, DBCONT, DBQUIT, DBSTACK, KEYBOARD.
```

## `dbstop`

```
DBSTOP  Pose un point d'arrêt.
    DBSTOP IN fichier AT ligne arrête avant cette ligne.
    DBSTOP IF ERROR arrête à la première erreur.

    Syntaxe
       dbstop in fichier at ligne
       dbstop if error

    Exemples
       dbstop if error
       dbstatus
       dbclear all

    Voir aussi DBCLEAR, DBSTATUS, DBSTEP, DBCONT, DBQUIT, KEYBOARD.
```

## `keyboard`

```
KEYBOARD  Rend la main à l'utilisateur au milieu d'un programme.
    KEYBOARD suspend l'exécution et donne l'invite « K>> » : on inspecte
    et modifie les variables, puis DBCONT reprend.

    Syntaxe
       keyboard

    Exemples
       % Posé dans un script, « keyboard » ouvre l'invite « K>> ».
       disp('keyboard suspend le programme là où il est écrit');

    Voir aussi DBSTOP, DBCONT, DBQUIT, INPUT.
```

## `matlibre_profil_lignes`

```
matlibre_profil_lignes  Passages ligne a ligne d'une fonction.
```

## `profile`

```
PROFILE  Profileur : où passe le temps.
    PROFILE ON démarre la mesure, PROFILE OFF l'arrête.
    PROFILE VIEWER affiche le classement des fonctions.
    S = PROFILE('info') rend le relevé en structure.
    PROFILE CLEAR efface les mesures.

    Syntaxe
       profile on
       profile off
       profile viewer
       s = profile('info')

    Exemples
       profile on
       for k = 1:100, y = fft(randn(1,64)); end
       profile off
       s = profile('info');
       isstruct(s)
       profile clear

    Voir aussi TIC, TOC, DBSTOP, KEYBOARD.
```

