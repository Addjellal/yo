# Temps et dates

Fonctions natives du groupe `temps`.

## `clock`

```
CLOCK  Date et heure courantes, en vecteur.
    CLOCK rend [année mois jour heure minute seconde].

    Syntaxe
       c = clock

    Exemples
       c = clock;
       numel(c)                       % 6
       c(1) > 2000

    Voir aussi NOW, DATE, DATESTR, ETIME, TIC.
```

## `cputime`

```
CPUTIME  Temps processeur consommé depuis le démarrage, en secondes.

    Syntaxe
       t = cputime

    Exemples
       t0 = cputime;
       y = fft(randn(1,4096));
       cputime - t0 >= 0

    Voir aussi TIC, TOC, ETIME, PROFILE.
```

## `date`

```
DATE  Date du jour, en texte.

    Syntaxe
       s = date

    Exemples
       s = date;
       ischar(s)

    Voir aussi CLOCK, NOW, DATESTR, DATENUM.
```

## `datenum`

```
DATENUM  Numéro de série d'une date.
    DATENUM(A,M,J) rend le numéro correspondant ; DATENUM(TEXTE) lit une
    date écrite. Les numéros se soustraient : la différence est en jours.

    Syntaxe
       d = datenum(a,m,j)
       d = datenum(texte)

    Exemples
       d1 = datenum(2024,1,1);
       d2 = datenum(2024,12,31);
       d2 - d1                        % 365 jours
       datenum(2024,5,1) > 0

    Voir aussi DATESTR, DATEVEC, NOW, ETIME.
```

## `datestr`

```
DATESTR  Écrit une date.
    DATESTR(D) écrit le numéro de série D ; DATESTR(D,FORMAT) impose le
    format, par exemple 'yyyy-mm-dd'.

    Syntaxe
       s = datestr(d)
       s = datestr(d,format)

    Exemples
       datestr(datenum(2024,5,1), 'yyyy-mm-dd')
       ischar(datestr(now))

    Voir aussi DATENUM, DATEVEC, NOW, CLOCK.
```

## `datevec`

```
DATEVEC  Décompose une date en [année mois jour heure minute seconde].

    Syntaxe
       v = datevec(d)

    Exemples
       v = datevec(datenum(2024,5,1));
       v(1:3)                         % [2024 5 1]

    Voir aussi DATENUM, DATESTR, CLOCK.
```

## `etime`

```
ETIME  Temps écoulé entre deux vecteurs d'horloge, en secondes.

    Syntaxe
       s = etime(t2,t1)

    Exemples
       t1 = clock;
       pause(0.05);
       ecoule = etime(clock, t1);
       ecoule >= 0.04

    Voir aussi TIC, TOC, CLOCK, CPUTIME.
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
NOW  Date et heure courantes, en numéro de série.

    Syntaxe
       d = now

    Exemples
       d = now;
       d > 700000
       datestr(now);

    Voir aussi CLOCK, DATE, DATESTR, DATENUM.
```

## `pause`

```
PAUSE  Suspend l'exécution.
    PAUSE(N) attend N secondes.
    PAUSE ON / PAUSE OFF autorise ou interdit les pauses.

    Syntaxe
       pause(n)
       pause on
       pause off

    Exemples
       tic; pause(0.05); ecoule = toc;
       ecoule >= 0.04

    Voir aussi TIC, TOC, DRAWNOW.
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

       x = randn(1,1024);
       tic; y = fft(x); toc
       id = tic; y = fft(x); ecoule = toc(id);

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
WEEKDAY  Jour de la semaine d'une date.
    [N,NOM] = WEEKDAY(D) rend le numéro — 1 pour dimanche — et son nom.

    Syntaxe
       n = weekday(d)
       [n,nom] = weekday(d)

    Exemples
       [n, nom] = weekday(datenum(2024,5,1));
       n >= 1 && n <= 7

    Voir aussi DATENUM, DATESTR, DATEVEC, NOW.
```

