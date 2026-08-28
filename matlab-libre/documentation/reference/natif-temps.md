# Temps et dates

Fonctions natives du groupe `temps`.

## `clock`

```
clock  Date et heure en vecteur.
```

## `cputime`

```
cputime  Temps processeur consomme.
```

## `date`

```
date  Date du jour.
```

## `datenum`

```
datenum  Date -> numero de serie.
```

## `datestr`

```
datestr  Numero de serie -> texte.
```

## `datevec`

```
datevec  Numero de serie -> vecteur.
```

## `etime`

```
etime  Secondes entre deux vecteurs d'horloge.
```

## `matlibre_addmonths`

```
matlibre_addmonths  Ajout de mois calendaires avec calage de fin de mois.
```

## `matlibre_num2ymd`

```
matlibre_num2ymd  Numero de serie -> matrice Nx6 de composantes.
```

## `matlibre_weekday`

```
matlibre_weekday  Jour de la semaine (1 = dimanche), vectorise.
```

## `matlibre_ymd2num`

```
matlibre_ymd2num  Composantes de date -> numero de serie (vectorise).
```

## `now`

```
now  Date et heure courantes en numero de serie.
```

## `pause`

```
pause  Attend un nombre de secondes.
```

## `tic`

```
TIC  Démarre le chronomètre.
    TIC met à zéro le chronomètre ; TOC lit le temps écoulé.
    ID = TIC rend un identifiant, à passer à TOC : c'est ce qui permet
    d'imbriquer deux mesures.

    Syntaxe
       tic
       id = tic;

    Exemples
       tic; y = fft(x); toc
       id = tic; ... ; ecoule = toc(id);

    Voir aussi TOC, CPUTIME, TIMEIT, PROFILE.
```

## `toc`

```
TOC  Lit le chronomètre.
    TOC affiche le temps écoulé depuis TIC.
    T = TOC rend ce temps en secondes, sans l'afficher.
    T = TOC(ID) lit le chronomètre démarré par « ID = TIC ».

    Syntaxe
       toc
       t = toc;
       t = toc(id);

    Exemples
       tic; pause(0.5); t = toc;      % t vaut environ 0.5

    Voir aussi TIC, CPUTIME, TIMEIT.
```

## `weekday`

```
weekday  Jour de la semaine.
```

