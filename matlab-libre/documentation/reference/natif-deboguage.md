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
dbcont  Reprend l'execution.
```

## `dbquit`

```
dbquit  Abandonne l'execution.
```

## `dbstack`

```
dbstack  Pile des appels.
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
dbstep  Avance d'une instruction.
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
keyboard  Rend la main a l'utilisateur.
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

