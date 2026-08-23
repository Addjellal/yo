# Toolbox `types`

```
% Types de données — durées, dates, catégories, tables.
%
% Ces classes complètent les types natifs du langage. Elles s'appuient sur
% « subsref » et « subsasgn », que l'interpréteur route vers la classe,
% comme le décrit la documentation MathWorks. À l'intérieur d'une méthode,
% l'indexation reste celle du langage : c'est la règle de MATLAB.
%
% Classes
%   duration          - Durée, stockée en secondes
%   calendarDuration  - Durée de calendrier (mois, jours, temps)
%   datetime          - Date et heure, numéro de série compatible datenum
%   categorical       - Valeurs prises dans un ensemble fini
%   table             - Tableau à colonnes nommées et hétérogènes
%   timetable         - Table indexée par un axe de temps
%
% Durées
%   seconds, minutes, hours, days, years, milliseconds - construction et
%                       extraction ; le format d'affichage suit l'unité
%   isduration        - Test de type
%
% Durées de calendrier
%   caldays, calweeks, calmonths, calquarters, calyears - construction et
%                       extraction
%   time              - Partie horaire, sous forme de duration
%   iscalendarduration - Test de type
%
% Dates
%   NaT               - Date manquante
%   isdatetime, isnat - Tests
%   year, month, day, hour, minute, second - composantes (méthodes)
%   quarter, week, weekday, isweekend, ymd, hms, timeofday - dérivées
%   dateshift, between, caldiff, isbetween - déplacements et écarts
%   datenum, datevec, datestr, posixtime, exceltime, juliandate - conversions
%
% Catégories
%   categories, iscategory, addcats, removecats, mergecats, renamecats,
%   reordercats, setcats, countcats, isundefined, isordinal - méthodes
%   iscategorical     - Test de type
%
% Tables
%   array2table, cell2table, struct2table - construction
%   table2array, table2cell, table2struct - conversion
%   readtable, writetable                 - fichiers délimités
%   istable, height, width                - inspection
%   head, tail, sortrows, summary         - exploration
%   addvars, removevars, movevars, renamevars, convertvars - variables
%   varfun, rowfun, groupsummary          - calculs, groupés ou non
%   join, innerjoin, outerjoin            - jointures par clé
%
% Tables temporelles
%   table2timetable, timetable2table - conversions
%   retime, synchronize              - ré-échantillonnage et réunion
%   isregular, istimetable           - inspection
%
% Outils internes
%   appliquerReste, assignerReste - application d'une chaîne d'indexation
%                       restante, partagée par tous les subsref/subsasgn
```

## `NaT`

```
NAT Date manquante (« Not-a-Time »).
  T = NAT construit un scalaire manquant ; NAT(N) une matrice N x N,
  NAT(M,N) une matrice M x N.
```

## `appliquerReste`

```
APPLIQUERRESTE Applique une suite d'accès subsref à une valeur ordinaire.
  V = APPLIQUERRESTE(V,S) où S est la structure décrite par la
  documentation de subsref : champs « type » et « subs ». Les classes de
  ce dossier s'en servent pour traiter la fin d'une chaîne d'accès une
  fois leur propre premier accès résolu.
```

## `array2table`

```
ARRAY2TABLE Convertit une matrice en table, une colonne par variable.
  T = ARRAY2TABLE(A) nomme les variables A1, A2, ...
  T = ARRAY2TABLE(A,'VariableNames',NOMS) impose les noms,
  T = ARRAY2TABLE(A,'RowNames',NOMS) nomme les lignes.
```

## `assignerReste`

```
ASSIGNERRESTE Applique une suite d'accès subsasgn à une valeur ordinaire.
```

## `caldays`

```
CALDAYS Durée de calendrier en caldays, ou nombre de caldays d'une durée.
```

## `calendarDuration`

```
CALENDARDURATION Durée exprimée en unités de calendrier.
  CD = CALENDARDURATION(Y,M,D) construit une durée de Y années, M mois et
  D jours. CALENDARDURATION(Y,M,D,H,MI,S) ajoute une partie horaire.

  Une durée de calendrier n'est pas une durée fixe : un mois vaut 28, 29,
  30 ou 31 jours selon la date à laquelle on l'ajoute. Les composantes
  sont donc rangées séparément : mois, jours, et temps en secondes.

  Exemple :
     cd = calmonths(3) + caldays(2)   % 3mo 2d
     calmonths(cd)                    % 3

  Voir aussi CALYEARS, CALQUARTERS, CALMONTHS, CALWEEKS, CALDAYS, TIME.
```

## `calmonths`

```
CALMONTHS Durée de calendrier en calmonths, ou nombre de calmonths d'une durée.
  CD = CALMONTHS(N) construit une durée de calendrier.
  N = CALMONTHS(CD) rend le nombre entier correspondant.
```

## `calquarters`

```
CALQUARTERS Durée de calendrier en calquarters, ou nombre de calquarters d'une durée.
  CD = CALQUARTERS(N) construit une durée de calendrier.
  N = CALQUARTERS(CD) rend le nombre entier correspondant.
```

## `calweeks`

```
CALWEEKS Durée de calendrier en calweeks, ou nombre de calweeks d'une durée.
```

## `calyears`

```
CALYEARS Durée de calendrier en calyears, ou nombre de calyears d'une durée.
  CD = CALYEARS(N) construit une durée de calendrier.
  N = CALYEARS(CD) rend le nombre entier correspondant.
```

## `categorical`

```
CATEGORICAL Tableau de valeurs prises dans un ensemble fini de catégories.
  C = CATEGORICAL(A) transforme un tableau de textes, un tableau
  numérique ou un tableau logique en catégories, triées par ordre
  croissant. C = CATEGORICAL(A,ENSEMBLE) impose la liste des catégories,
  et C = CATEGORICAL(A,ENSEMBLE,NOMS) leur donne d'autres noms.
  CATEGORICAL(...,'Ordinal',true) rend les catégories ordonnées : les
  comparaisons < <= > >= deviennent alors licites.

  Les valeurs absentes de l'ensemble sont indéfinies : leur code vaut 0 et
  elles s'affichent « <undefined> ».

  Exemple :
     c = categorical({'petit','grand','petit'})
     categories(c)        % {'grand';'petit'}
     countcats(c)         % [1 2]

  Voir aussi CATEGORIES, ISCATEGORY, ADDCATS, REMOVECATS, MERGECATS,
  RENAMECATS, REORDERCATS, SETCATS, COUNTCATS, ISUNDEFINED.
```

## `cell2table`

```
CELL2TABLE Convertit une cellule à deux dimensions en table.
  Chaque colonne devient une variable : numérique si toutes ses cases le
  sont, cellule de textes sinon.
```

## `datetime`

```
DATETIME Point dans le temps, avec date et heure.
  T = DATETIME(Y,M,D) construit une date à minuit.
  T = DATETIME(Y,M,D,H,MI,S) précise l'heure ; S peut être fractionnaire.
  T = DATETIME(V) accepte un vecteur de date [Y M D H MI S] par ligne.
  T = DATETIME(TEXTE) lit 'aaaa-mm-jj hh:mm:ss' ou 'jj-MMM-aaaa'.
  T = DATETIME('now'), 'today', 'yesterday', 'tomorrow'.
  T = DATETIME(X,'ConvertFrom',SOURCE) avec SOURCE parmi 'datenum',
  'posixtime', 'excel', 'juliandate'.

  L'état interne est un numéro de série compatible DATENUM : 1 correspond
  au 1er janvier de l'an 0. Les composantes s'obtiennent par YEAR, MONTH,
  DAY, HOUR, MINUTE, SECOND, ou par les propriétés du même nom.

  Exemple :
     t = datetime(2024, 2, 29, 13, 30, 0)
     t + caldays(1)
     t2 = datetime(2024, 3, 1);  t2 - t     % durée

  Voir aussi DURATION, CALENDARDURATION, NAT, DATESHIFT, CALDIFF.
```

## `days`

```
DAYS Durée en jours, ou jours d'une durée.
  D = DAYS(X) construit une durée dont le format d'affichage est 'd'.
  X = DAYS(D) rend le nombre de jours d'une durée.
```

## `duration`

```
DURATION Durée, longueur de temps sans origine.
  D = DURATION(H,M,S) construit une durée à partir d'heures, minutes et
  secondes. D = DURATION(H,M,S,MS) ajoute des millisecondes.
  D = DURATION(X) où X est numérique interprète X comme des secondes.

  La propriété Format contrôle l'affichage. Les valeurs reconnues sont
  'y', 'd', 'h', 'm', 's' (un nombre suivi de l'unité) et les formats
  d'horloge 'dd:hh:mm:ss', 'hh:mm:ss', 'mm:ss', 'hh:mm', éventuellement
  suivis d'un point et de un à neuf 'S' pour les fractions de seconde.

  Exemple :
     d = hours(2) + minutes(30)   % 2.5 hr
     seconds(d)                   % 9000
     d.Format = 'hh:mm:ss';
     char(d)                      % '02:30:00'

  Voir aussi SECONDS, MINUTES, HOURS, DAYS, YEARS, CALENDARDURATION.
```

## `hours`

```
HOURS Durée en heures, ou heures d'une durée.
  D = HOURS(X) construit une durée dont le format d'affichage est 'h'.
  X = HOURS(D) rend le nombre de heures d'une durée.
```

## `iscalendarduration`

```
ISCALENDARDURATION Vrai pour un tableau calendarDuration.
```

## `iscategorical`

```
ISCATEGORICAL Vrai pour un tableau categorical.
```

## `isdatetime`

```
ISDATETIME Vrai pour un tableau datetime.
```

## `isduration`

```
ISDURATION Vrai pour un objet duration.
```

## `isnat`

```
ISNAT Vrai pour les éléments manquants d'un tableau datetime.
```

## `istable`

```
ISTABLE Vrai pour une table.
```

## `istimetable`

```
ISTIMETABLE Vrai pour une timetable.
```

## `milliseconds`

```
MILLISECONDS Durée en millisecondes, ou millisecondes d'une durée.
  D = MILLISECONDS(X) construit une durée affichée en secondes.
  X = MILLISECONDS(D) rend le nombre de millisecondes d'une durée.
```

## `minutes`

```
MINUTES Durée en minutes, ou minutes d'une durée.
  D = MINUTES(X) construit une durée dont le format d'affichage est 'm'.
  X = MINUTES(D) rend le nombre de minutes d'une durée.
```

## `readtable`

```
READTABLE Lit un fichier texte délimité et rend une table.
  T = READTABLE(FICHIER) devine le séparateur parmi la virgule, le
  point-virgule et la tabulation, et prend la première ligne comme
  noms de variables.
  READTABLE(...,'Delimiter',D) impose le séparateur.
  READTABLE(...,'ReadVariableNames',false) numérote les colonnes.
```

## `seconds`

```
SECONDS Durée en secondes, ou secondes d'une durée.
  D = SECONDS(X) construit une durée dont le format d'affichage est 's'.
  X = SECONDS(D) rend le nombre de secondes d'une durée.
```

## `struct2table`

```
STRUCT2TABLE Convertit un tableau de structures en table.
  Chaque champ devient une variable ; un tableau 1x1 dont les champs sont
  des colonnes est accepté également.
```

## `table`

```
TABLE Tableau de données à colonnes nommées et hétérogènes.
  T = TABLE(V1,V2,...) range chaque variable dans une colonne. Toutes les
  variables doivent avoir le même nombre de lignes.
  T = TABLE(...,'VariableNames',NOMS) nomme les colonnes,
  T = TABLE(...,'RowNames',NOMS) nomme les lignes.

  Indexation :
     T(lignes,variables)   sous-table
     T{lignes,variables}   contenu extrait et concaténé
     T.Nom                 une variable entière
     T.Properties          métadonnées (VariableNames, RowNames, ...)

  Exemple :
     t = table([1;2;3], {'a';'b';'c'}, 'VariableNames', {'n','lettre'});
     height(t)      % 3
     t.n            % [1;2;3]
     t(2,:)         % deuxième ligne

  Voir aussi ARRAY2TABLE, CELL2TABLE, STRUCT2TABLE, TABLE2ARRAY, HEAD,
  TAIL, SORTROWS, VARFUN, GROUPSUMMARY, INNERJOIN, OUTERJOIN, TIMETABLE.
```

## `table2timetable`

```
TABLE2TIMETABLE Convertit une table en timetable.
  TT = TABLE2TIMETABLE(T) utilise la première variable datetime ou
  duration comme axe de temps. TABLE2TIMETABLE(T,'RowTimes',T0) impose
  un autre vecteur d'instants.
```

## `time`

```
TIME Partie horaire d'une durée de calendrier, sous forme de duration.
```

## `timetable`

```
TIMETABLE Table dont chaque ligne porte un instant ou une durée.
  TT = TIMETABLE(T,V1,V2,...) où T est un vecteur datetime ou duration.
  TT = TIMETABLE(V1,V2,...,'RowTimes',T) donne le même résultat.
  TT = TIMETABLE(V1,...,'SampleRate',FS) ou 'TimeStep',DT engendre les
  instants à partir de zéro seconde.

  Indexation :
     TT(lignes,variables)  sous-timetable
     TT{lignes,variables}  contenu extrait
     TT.Nom                une variable
     TT.Properties.RowTimes  le vecteur des instants

  Exemple :
     t = datetime(2024,1,1) + caldays(0:2)';
     tt = timetable(t, [10;20;30], 'VariableNames', {'mesure'});
     height(tt)     % 3

  Voir aussi TABLE, RETIME, SYNCHRONIZE, TABLE2TIMETABLE.
```

## `writetable`

```
WRITETABLE Écrit une table dans un fichier texte délimité.
  WRITETABLE(T,FICHIER) écrit un fichier CSV avec une ligne d'en-tête.
  WRITETABLE(...,'Delimiter',D) choisit le séparateur,
  WRITETABLE(...,'WriteVariableNames',false) supprime l'en-tête.
```

## `years`

```
YEARS Durée en années (365,2425 jours), ou années d'une durée.
  D = YEARS(X) construit une durée dont le format d'affichage est 'y'.
  X = YEARS(D) rend le nombre de années d'une durée.
```

