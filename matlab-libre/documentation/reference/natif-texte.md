# Chaines de caracteres

Fonctions natives du groupe `texte`.

## `blanks`

```
blanks  Chaine de n espaces.
```

## `cellstr`

```
cellstr  Vers cellule de textes.
```

## `compose`

```
compose  Formate vers une string.
```

## `contains`

```
contains  Le texte contient-il le motif.
```

## `deblank`

```
deblank  Retire les blancs finaux.
```

## `endsWith`

```
endsWith  Finit par le motif.
```

## `fliplr_str`

```
fliplr_str  Inverse un texte.
```

## `iscellstr`

```
iscellstr  Cellule de textes ?
```

## `isdigit`

```
isdigit  Caracteres numeriques.
```

## `isletter`

```
isletter  Caracteres alphabetiques.
```

## `isspace`

```
isspace  Caracteres blancs.
```

## `lower`

```
lower  Passe en minuscules.
```

## `matlab.lang.makeUniqueStrings`

```
matlab.lang.makeUniqueStrings  Rend les noms uniques.
```

## `matlab.lang.makeValidName`

```
matlab.lang.makeValidName  Rend un identifiant valide.
```

## `natsort`

```
natsort  Tri naturel (identite ici).
```

## `num2str_`

```
num2str_  Reserve.
```

## `pad`

```
pad  Complete par des espaces.
```

## `regexp`

```
REGEXP  Cherche une expression régulière.
    [DEBUT] = REGEXP(TEXTE,MOTIF) rend les positions des correspondances.
    REGEXP(TEXTE,MOTIF,OPTION) choisit ce qui est rendu :
       'match'   les textes trouvés
       'tokens'  les groupes capturés
       'names'   les groupes nommés
       'split'   les morceaux entre les correspondances
       'once'    la première correspondance seulement
       'start', 'end' les positions

    Syntaxe
       debut = regexp(texte,motif)
       trouve = regexp(texte,motif,'match')
       jetons = regexp(texte,motif,'tokens')

    Exemples
       regexp('a1b22c', '\d+', 'match')       % {'1','22'}
       regexp('nom: Jean', '(\w+): (\w+)', 'tokens')
       regexp('a,b;c', '[,;]', 'split')       % {'a','b','c'}

    Voir aussi REGEXPI, REGEXPREP, STRFIND, CONTAINS.
```

## `regexpi`

```
regexpi  Expression reguliere, sans la casse.
```

## `regexprep`

```
regexprep  Remplacement par motif.
```

## `reverse`

```
reverse  Inverse un texte.
```

## `startsWith`

```
startsWith  Commence par le motif.
```

## `strcat`

```
strcat  Concatene des textes.
```

## `strcmp`

```
STRCMP  Compare deux chaînes.
    TF = STRCMP(S1,S2) rend vrai si les deux chaînes sont identiques,
    longueur comprise. La comparaison tient compte de la casse.
    Si l'un des arguments est une cellule, la comparaison est faite terme
    à terme et rend un tableau logique.

    L'égalité « == » compare caractère par caractère et exige la même
    longueur : STRCMP est ce qu'il faut pour comparer des chaînes.

    Syntaxe
       tf = strcmp(s1,s2)

    Exemples
       strcmp('abc', 'abc')            % 1
       strcmp('abc', 'ABC')            % 0
       strcmp({'a','b'}, 'a')          % [1 0]

    Voir aussi STRCMPI, STRNCMP, ISEQUAL, CONTAINS.
```

## `strcmpi`

```
strcmpi  Comparaison sans la casse.
```

## `strfind`

```
strfind  Positions d'un motif.
```

## `string`

```
string  Vers tableau string.
```

## `strip`

```
strip  Retire les blancs aux deux bouts.
```

## `strjoin`

```
STRJOIN  Assemble une cellule de chaînes.
    S = STRJOIN(C) joint avec une espace.
    S = STRJOIN(C,DELIM) joint avec le délimiteur donné.

    Syntaxe
       str = strjoin(C)
       str = strjoin(C,delimiteur)

    Exemples
       strjoin({'a','b','c'}, ', ')    % 'a, b, c'
       strjoin(noms, filesep)

    Voir aussi STRSPLIT, JOIN, SPRINTF.
```

## `strjust`

```
strjust  Justifie un tableau de caracteres.
```

## `strlength`

```
strlength  Longueur de chaque texte.
```

## `strncmp`

```
strncmp  Comparaison des n premiers.
```

## `strncmpi`

```
strncmpi  Comparaison des n premiers, sans la casse.
```

## `strrep`

```
STRREP  Remplace du texte.
    S = STRREP(TEXTE,ANCIEN,NOUVEAU) remplace toutes les occurrences.

    Syntaxe
       newStr = strrep(str,ancien,nouveau)

    Exemples
       strrep('abcabc', 'b', 'X')      % 'aXcaXc'
       strrep(chemin, '\', '/')

    Voir aussi REGEXPREP, STRFIND, ERASE, INSERTAFTER.
```

## `strsplit`

```
STRSPLIT  Découpe une chaîne.
    C = STRSPLIT(S) découpe S sur les blancs et rend une cellule.
    C = STRSPLIT(S,DELIM) découpe sur le délimiteur donné, qui peut être
    une chaîne ou une cellule de chaînes.

    Syntaxe
       C = strsplit(str)
       C = strsplit(str,delimiteur)

    Exemples
       strsplit('a,b,c', ',')          % {'a','b','c'}
       strsplit('un deux trois')       % {'un','deux','trois'}
       strsplit('a1b2c', {'1','2'})    % {'a','b','c'}

    Voir aussi STRJOIN, SPLIT, STRTOK, REGEXP.
```

## `strtok`

```
strtok  Premier jeton et reste.
```

## `strtrim`

```
strtrim  Retire les blancs aux deux bouts.
```

## `strvcat`

```
strvcat  Empile des textes en lignes.
```

## `tolower`

```
tolower  Passe en minuscules.
```

## `toupper`

```
toupper  Passe en majuscules.
```

## `upper`

```
upper  Passe en majuscules.
```

