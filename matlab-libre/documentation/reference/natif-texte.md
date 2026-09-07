# Chaines de caracteres

Fonctions natives du groupe `texte`.

## `blanks`

```
BLANKS  Chaîne de N espaces.

    Syntaxe
       s = blanks(n)

    Exemples
       ['[' blanks(3) ']']            % '[   ]'
       numel(blanks(5))               % 5

    Voir aussi SPACE, STRTRIM, REPMAT, SPRINTF.
```

## `cellstr`

```
CELLSTR  Convertit un tableau de caractères en cellule de textes.
    CELLSTR(S) fait une cellule d'une ligne par ligne de S, blancs de fin
    retirés.

    Syntaxe
       C = cellstr(s)

    Exemples
       C = cellstr(char('un','deux'))
       numel(C)                       % 2
       C{2}

    Voir aussi CHAR, ISCELLSTR, STRSPLIT, STRING.
```

## `compose`

```
COMPOSE  Formate vers une string.
    COMPOSE(FORMAT,...) est SPRINTF, mais rend une string.

    Syntaxe
       s = compose(format,...)

    Exemples
       s = compose('%d points', 42);
       isstring(s)

    Voir aussi SPRINTF, STRING, NUM2STR.
```

## `contains`

```
CONTAINS  Le texte contient-il le motif.
    CONTAINS(S,MOTIF) rend un booléen — plus lisible que « ~isempty(strfind(...)) ».
    CONTAINS(S,MOTIF,'IgnoreCase',true) ignore la casse.

    Syntaxe
       tf = contains(s,motif)
       tf = contains(s,motif,'IgnoreCase',true)

    Exemples
       contains('bonjour', 'jour')        % 1
       contains({'abc','xyz'}, 'b')       % [1 0]
       contains('Bonjour', 'bon', 'IgnoreCase', true)

    Voir aussi STRFIND, STARTSWITH, ENDSWITH, REGEXP.
```

## `count`

```
COUNT  Nombre d'occurrences d'un motif.
    N = COUNT(TEXTE,MOTIF) compte les occurrences sans recouvrement :
    « aaa » ne contient qu'une fois « aa », la seconde occurrence
    chevauchant la première. MOTIF peut être une cellule ; les comptes
    s'additionnent.

    N = COUNT(...,'IgnoreCase',true) ne distingue pas la casse.

    Syntaxe
       n = count(str,motif)

    Exemples
       count('abcabc', 'abc')          % 2
       count('aaa', 'aa')              % 1 : sans recouvrement
       count({'aa','aaa'}, 'a')        % [2 3]

    Voir aussi CONTAINS, STRFIND, MATCHES, NUMEL.
```

## `deblank`

```
DEBLANK  Retire les blancs de fin.
    DEBLANK(S) enlève les espaces de fin, mais garde ceux du début — c'est
    la différence avec STRTRIM.

    Syntaxe
       t = deblank(s)

    Exemples
       ['[' deblank('  a  ') ']']     % '[  a]'
       numel(deblank('abc   '))       % 3

    Voir aussi STRTRIM, STRIP, BLANKS.
```

## `endsWith`

```
ENDSWITH  Le texte finit-il par le motif.

    Syntaxe
       tf = endsWith(s,motif)
       tf = endsWith(s,motif,'IgnoreCase',true)

    Exemples
       endsWith('fichier.txt', '.txt')        % 1
       noms = {'a.m','b.c'};
       noms(endsWith(noms, '.m'))

    Voir aussi STARTSWITH, CONTAINS, FILEPARTS.
```

## `erase`

```
ERASE  Retire du texte.
    S = ERASE(TEXTE,MOTIF) supprime toutes les occurrences du motif. MOTIF
    peut être une cellule de motifs, tous retirés à la suite.

    C'est REPLACE avec un remplacement vide, et c'est ainsi qu'on nettoie
    un texte de ses marques sans avoir à écrire la chaîne vide.

    Syntaxe
       newStr = erase(str,motif)

    Exemples
       erase('bonjour le monde', 'le ')     % 'bonjour monde'
       erase({'a1b','a2b'}, 'a')            % {'1b'  '2b'}
       erase('a-b-c', '-')                  % 'abc'

    Voir aussi REPLACE, STRREP, INSERTAFTER, EXTRACTBEFORE.
```

## `extractAfter`

```
EXTRACTAFTER  Ce qui suit un motif.
    S = EXTRACTAFTER(TEXTE,MOTIF) rend ce qui vient après la première
    occurrence du motif, et la chaîne vide si le motif est absent.
    S = EXTRACTAFTER(TEXTE,N) rend ce qui suit le N-ième caractère.

    Rendre une chaîne vide plutôt qu'une erreur permet d'enchaîner sans
    tester : c'est le comportement de MATLAB.

    Syntaxe
       newStr = extractAfter(str,motif)
       newStr = extractAfter(str,n)

    Exemples
       extractAfter('bonjour monde', 'bonjour ')   % 'monde'
       extractAfter('abcdef', 3)                   % 'def'
       extractAfter('abc', 'z')                    % ''

    Voir aussi EXTRACTBEFORE, EXTRACTBETWEEN, ERASE, STRFIND.
```

## `extractBefore`

```
EXTRACTBEFORE  Ce qui précède un motif.
    S = EXTRACTBEFORE(TEXTE,MOTIF) rend ce qui vient avant la première
    occurrence du motif, et la chaîne vide si le motif est absent.
    S = EXTRACTBEFORE(TEXTE,N) rend les N-1 premiers caractères.

    Syntaxe
       newStr = extractBefore(str,motif)
       newStr = extractBefore(str,n)

    Exemples
       extractBefore('bonjour monde', ' monde')    % 'bonjour'
       extractBefore('abcdef', 4)                  % 'abc'
       extractBefore('fichier.txt', '.')           % 'fichier'

    Voir aussi EXTRACTAFTER, EXTRACTBETWEEN, ERASE.
```

## `extractBetween`

```
EXTRACTBETWEEN  Ce qui sépare deux motifs.
    S = EXTRACTBETWEEN(TEXTE,DEBUT,FIN) rend ce qui se trouve entre la
    première occurrence de DEBUT et la première occurrence de FIN qui la
    suit. S = EXTRACTBETWEEN(TEXTE,A,B) rend les caractères de rang A à B.

    S = EXTRACTBETWEEN(...,'Boundaries','inclusive') garde les deux motifs
    dans le résultat ; par défaut ils en sont exclus.

    Syntaxe
       newStr = extractBetween(str,debut,fin)
       newStr = extractBetween(str,a,b)

    Exemples
       extractBetween('<a>texte</a>', '<a>', '</a>')      % 'texte'
       extractBetween('abcdef', 2, 4)                     % 'bcd'
       extractBetween('<a>x</a>', '<a>', '</a>', 'Boundaries', 'inclusive')

    Voir aussi EXTRACTAFTER, EXTRACTBEFORE, REGEXP.
```

## `insertAfter`

```
INSERTAFTER  Insère du texte après un motif.
    S = INSERTAFTER(TEXTE,MOTIF,AJOUT) pose AJOUT après chaque occurrence
    du motif, non seulement après la première.

    Syntaxe
       newStr = insertAfter(str,motif,ajout)

    Exemples
       insertAfter('abc', 'b', 'X')        % 'abXc'
       insertAfter('a,b,c', ',', ' ')      % 'a, b, c'
       insertAfter({'ab','cb'}, 'b', '!')  % {'ab!'  'cb!'}

    Voir aussi INSERTBEFORE, ERASE, REPLACE, EXTRACTAFTER.
```

## `insertBefore`

```
INSERTBEFORE  Insère du texte avant un motif.
    S = INSERTBEFORE(TEXTE,MOTIF,AJOUT) pose AJOUT avant chaque occurrence
    du motif.

    Syntaxe
       newStr = insertBefore(str,motif,ajout)

    Exemples
       insertBefore('abc', 'b', 'X')       % 'aXbc'
       insertBefore('fichier.txt', '.', '_v2')   % 'fichier_v2.txt'

    Voir aussi INSERTAFTER, ERASE, REPLACE, EXTRACTBEFORE.
```

## `iscellstr`

```
ISCELLSTR  La cellule ne contient-elle que du texte.
    ISCELLSTR(C) rend vrai si C est une cellule dont toutes les cases sont
    des tableaux de caractères.

    Syntaxe
       tf = iscellstr(c)

    Exemples
       iscellstr({'a','bb'})          % 1
       iscellstr({'a',1})             % 0
       iscellstr('abc')               % 0 — ce n'est pas une cellule

    Voir aussi ISCELL, ISCHAR, CELLSTR, ISSTRING.
```

## `isdigit`

```
ISDIGIT  Quels caractères sont des chiffres.

    Syntaxe
       tf = isdigit(s)

    Exemples
       isdigit('a1b2')                % [0 1 0 1]
       s = 'ref-2024';
       str2double(s(isdigit(s)))      % 2024

    Voir aussi ISLETTER, ISSPACE, STR2DOUBLE, REGEXP.
```

## `isletter`

```
ISLETTER  Quels caractères sont des lettres.

    Syntaxe
       tf = isletter(s)

    Exemples
       isletter('a1b')                % [1 0 1]
       s = 'ab12cd';
       s(isletter(s))                 % 'abcd'

    Voir aussi ISSPACE, ISDIGIT, ISVARNAME.
```

## `isspace`

```
ISSPACE  Quels caractères sont des blancs.
    ISSPACE(S) rend un booléen par caractère.

    Syntaxe
       tf = isspace(s)

    Exemples
       isspace('a b')                 % [0 1 0]
       s = 'un  mot';
       s(~isspace(s))                 % retirer tous les blancs

    Voir aussi ISLETTER, ISDIGIT, STRTRIM, REGEXPREP.
```

## `lower`

```
LOWER  Met le texte en minuscules.
    LOWER(S) rend S en minuscules.

    Syntaxe
       t = lower(s)

    Exemples
       lower('BONJOUR')               % 'bonjour'
       reponse = 'OUI';
       if strcmp(lower(reponse), 'oui')
           disp('accepté');
       end

    Voir aussi UPPER, STRCMPI.
```

## `matches`

```
MATCHES  Le texte est-il exactement le motif.
    TF = MATCHES(TEXTE,MOTIF) est vrai quand le texte est égal au motif
    tout entier. MOTIF peut être une cellule : vrai si l'un d'eux
    correspond.

    C'est la différence entre « est-ce ce mot » et « ce mot y est-il » :
    CONTAINS se contente d'une occurrence, MATCHES exige l'égalité.

    TF = MATCHES(...,'IgnoreCase',true) ne distingue pas la casse.

    Syntaxe
       tf = matches(str,motif)

    Exemples
       matches('abc', 'abc')           % 1
       matches('abc', 'ab')            % 0 : CONTAINS dirait 1
       matches({'a','b'}, 'a')         % [1 0]
       matches('ABC', 'abc', 'IgnoreCase', true)   % 1

    Voir aussi CONTAINS, STRCMP, STARTSWITH, ENDSWITH.
```

## `matlab.lang.makeUniqueStrings`

```
MATLAB.LANG.MAKEUNIQUESTRINGS  Rendre uniques des noms qui se répètent.
    MATLAB.LANG.MAKEUNIQUESTRINGS(C) ajoute un numéro aux doublons d'un
    tableau de cellules de chaînes, jusqu'à ce que tous diffèrent. Le
    premier de chaque groupe garde son nom.

    Syntaxe
       U = matlab.lang.makeUniqueStrings(C)

    Exemples
       matlab.lang.makeUniqueStrings({'a', 'a', 'b'})     % 'a'  'a_1'  'b'
       numel(unique(matlab.lang.makeUniqueStrings({'x', 'x', 'x'})))   % 3
       matlab.lang.makeUniqueStrings({'a', 'b'})          % inchange

    Voir aussi UNIQUE, MATLAB.LANG.MAKEVALIDNAME, GENVARNAME.
```

## `matlab.lang.makeValidName`

```
MATLAB.LANG.MAKEVALIDNAME  Rendre un texte utilisable comme nom de variable.
    MATLAB.LANG.MAKEVALIDNAME(S) remplace ce qui ne peut pas figurer dans
    un nom de variable — espaces, accents, ponctuation — par des
    soulignés, et fait précéder d'un « x » un nom qui commencerait par un
    chiffre. Le résultat est un nom que le langage accepte.

    Syntaxe
       N = matlab.lang.makeValidName(S)

    Exemples
       matlab.lang.makeValidName('mon nom')       % 'mon_nom'
       matlab.lang.makeValidName('2eme')          % 'x2eme'
       matlab.lang.makeValidName({'a-b', 'c d'})  % {'a_b', 'c_d'}
       isvarname(matlab.lang.makeValidName('%!'))  % vrai

    Voir aussi ISVARNAME, MATLAB.LANG.MAKEUNIQUESTRINGS, GENVARNAME.
```

## `natsort`

```
NATSORT  Tri naturel : les nombres se comparent comme des nombres.
    NATSORT(C) trie un tableau de cellules de chaînes en comparant les
    suites de chiffres par leur valeur et non caractère par caractère :
    « fichier2 » passe avant « fichier10 », que l'ordre alphabétique met
    à l'envers. Les zéros de tête ne comptent pas.

    [C,I] = NATSORT(C) rend aussi les indices, comme SORT.

    Cette fonction n'existe pas dans MATLAB : c'est une contribution
    connue du dépôt d'échange, que MatLibre fournit d'origine parce que
    le besoin revient à chaque liste de fichiers.

    Syntaxe
       T = natsort(C)
       [T,I] = natsort(C)

    Exemples
       natsort({'a10', 'a2', 'a1'})       % 'a1'  'a2'  'a10'
       sort({'a10', 'a2', 'a1'})          % 'a1'  'a10'  'a2', l'ordre du texte
       [t, i] = natsort({'v3', 'v1'});
       i                                  % 2  1

    Voir aussi SORT, SORTROWS, DIR, STRCMP.
```

## `newline`

```
NEWLINE  Le caractère de fin de ligne.
    NEWLINE rend le caractère de saut de ligne, celui que sprintf écrit
    pour « \n ». Il sert à assembler du texte sans passer par SPRINTF.

    Syntaxe
       c = newline

    Exemples
       double(newline)        % 10
       texte = ['premiere' newline 'seconde'];
       numel(strsplit(texte, newline))    % 2
       isequal(newline, sprintf('\n'))    % vrai

    Voir aussi SPRINTF, STRSPLIT, STRJOIN, BLANKS, COMPOSE.
```

## `pad`

```
PAD  Complète des textes à la même longueur.
    PAD(C) complète d'espaces jusqu'à la plus longue chaîne.
    PAD(C,N) complète jusqu'à N caractères.
    PAD(C,N,'left') complète à gauche.

    Syntaxe
       t = pad(c)
       t = pad(c,n)
       t = pad(c,n,cote)

    Exemples
       pad({'a','bbb'})
       numel(pad('ab', 5))                % 5

    Voir aussi STRJUST, BLANKS, STRTRIM, CHAR.
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
REGEXPI  Expression régulière, sans distinguer la casse.
    REGEXPI(S,MOTIF,...) est REGEXP en ignorant majuscules et minuscules.

    Syntaxe
       k = regexpi(s,motif)
       t = regexpi(s,motif,'match')

    Exemples
       regexpi('ABC', 'b')                % 2
       regexpi('Bonjour Bonsoir', 'bon\w+', 'match')

    Voir aussi REGEXP, REGEXPREP, STRCMPI, CONTAINS.
```

## `regexprep`

```
REGEXPREP  Remplace par expression régulière.
    REGEXPREP(S,MOTIF,REMPLACEMENT) remplace toutes les occurrences ; le
    remplacement peut citer les groupes par $1, $2…

    Syntaxe
       t = regexprep(s,motif,remplacement)

    Exemples
       regexprep('a1b22c', '\d+', '#')            % 'a#b#c'
       regexprep('2024-05-01', '(\d+)-(\d+)-(\d+)', '$3/$2/$1')
       regexprep('  trop   d''espaces ', '\s+', ' ')

    Voir aussi REGEXP, STRREP, REGEXPI.
```

## `regexptranslate`

```
REGEXPTRANSLATE  Rend un texte utilisable comme motif.
    S = REGEXPTRANSLATE('escape',TEXTE) protège les caractères qui ont un
    sens dans une expression régulière, de sorte que le texte se cherche
    littéralement.
    S = REGEXPTRANSLATE('wildcard',TEXTE) traduit les jokers du shell :
    l'astérisque devient « .* » et le point d'interrogation « . ».
    S = REGEXPTRANSLATE('flexible',TEXTE) rend le texte tel quel.

    Sans « escape », chercher « a.b » trouverait aussi « axb » : le point
    est un joker en expression régulière, et l'oubli est une source
    classique de faux positifs.

    Syntaxe
       s = regexptranslate(op,str)

    Exemples
       regexptranslate('escape', 'a.b*c')      % 'a\.b\*c'
       regexptranslate('wildcard', '*.txt')    % '.*\.txt'
       regexp('a.b', regexptranslate('escape', 'a.b'), 'once')

    Voir aussi REGEXP, REGEXPREP, STRFIND, CONTAINS.
```

## `replace`

```
REPLACE  Remplace un ou plusieurs motifs.
    S = REPLACE(TEXTE,ANCIEN,NOUVEAU) remplace toutes les occurrences.
    ANCIEN peut être une cellule de motifs ; NOUVEAU est alors soit unique,
    soit de même longueur, et chaque motif reçoit son remplacement.

    C'est ce qui la distingue de STRREP, qui ne prend qu'un motif. Les
    remplacements s'appliquent dans l'ordre donné : un motif qui apparaît
    dans le résultat d'un précédent sera lui aussi remplacé.

    Syntaxe
       newStr = replace(str,ancien,nouveau)

    Exemples
       replace('a-b-c', '-', '+')                 % 'a+b+c'
       replace('abc', {'a','c'}, {'x','y'})       % 'xby'
       replace({'aa','ba'}, 'a', 'Z')             % {'ZZ'  'bZ'}

    Voir aussi ERASE, STRREP, REGEXPREP, INSERTAFTER.
```

## `reverse`

```
REVERSE  Renverse un texte.

    Syntaxe
       t = reverse(s)

    Exemples
       reverse('abc')                     % 'cba'
       s = 'kayak';
       strcmp(s, reverse(s))              % un palindrome

    Voir aussi FLIP, FLIPLR, STRTRIM.
```

## `startsWith`

```
STARTSWITH  Le texte commence-t-il par le motif.

    Syntaxe
       tf = startsWith(s,motif)
       tf = startsWith(s,motif,'IgnoreCase',true)

    Exemples
       startsWith('fichier.txt', 'fichier')   % 1
       startsWith({'a.m','b.c'}, 'a')         % [1 0]

    Voir aussi ENDSWITH, CONTAINS, STRNCMP.
```

## `strcat`

```
STRCAT  Concatène des textes.
    STRCAT(S1,S2,...) colle les textes. Sur des tableaux de caractères,
    les blancs de fin sont retirés — pas ceux d'une cellule.

    Syntaxe
       t = strcat(s1,s2,...)

    Exemples
       strcat('abc', 'def')           % 'abcdef'
       strcat({'a','b'}, '_1')
       ['abc' 'def']                  % la façon la plus directe

    Voir aussi STRJOIN, SPRINTF, HORZCAT.
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
STRCMPI  Compare deux textes sans distinguer la casse.
    STRCMPI(S1,S2) rend vrai si les textes sont égaux à la casse près.

    Syntaxe
       tf = strcmpi(s1,s2)

    Exemples
       strcmpi('Oui','oui')           % 1
       strcmp('Oui','oui')            % 0
       strcmpi({'A','b'}, 'a')        % [1 0]

    Voir aussi STRCMP, STRNCMPI, LOWER.
```

## `strfind`

```
STRFIND  Cherche un motif dans un texte.
    STRFIND(S,MOTIF) rend les positions de départ de chaque occurrence,
    et un vecteur vide s'il n'y en a pas.

    Syntaxe
       k = strfind(s,motif)

    Exemples
       strfind('abracadabra', 'abra')     % [1 8]
       isempty(strfind('abc', 'z'))       % 1
       numel(strfind('aaa', 'aa'))        % 2 — les occurrences se recouvrent

    Voir aussi CONTAINS, REGEXP, STRREP, STRTOK.
```

## `string`

```
STRING  Convertit en tableau de strings.
    STRING(X) rend une string : "abc" plutôt que 'abc'. Les strings se
    concatènent avec « + », se comparent avec « == », et gardent leurs
    blancs de fin — ce que les tableaux de caractères ne font pas.

    Syntaxe
       s = string(x)

    Exemples
       s = string('abc');
       isstring(s)                        % 1
       string(42)
       string({'a','b'})

    Voir aussi ISSTRING, CHAR, CELLSTR, STRLENGTH.
```

## `strip`

```
STRIP  Retire les blancs aux deux bouts.
    STRIP(S) est l'équivalent moderne de STRTRIM.

    Syntaxe
       t = strip(s)

    Exemples
       strip('  abc  ')
       numel(strip('  a  '))              % 1

    Voir aussi STRTRIM, DEBLANK, PAD.
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
       noms = {'usr', 'local', 'bin'};
       strjoin(noms, filesep)

    Voir aussi STRSPLIT, JOIN, SPRINTF.
```

## `strjust`

```
STRJUST  Justifie les lignes d'un tableau de caractères.
    STRJUST(S,'right') aligne à droite, 'left' à gauche, 'center' au
    milieu.

    Syntaxe
       t = strjust(s,cote)

    Exemples
       s = char('un','trois');
       size(strjust(s,'right'))

    Voir aussi CHAR, STRTRIM, BLANKS, PAD.
```

## `strlength`

```
STRLENGTH  Longueur du texte, caractère par caractère.
    STRLENGTH(S) rend le nombre de caractères ; sur une cellule, un nombre
    par élément.

    Syntaxe
       n = strlength(s)

    Exemples
       strlength('abc')               % 3
       strlength({'a','bb','ccc'})    % [1 2 3]

    Voir aussi LENGTH, NUMEL, SIZE.
```

## `strncmp`

```
STRNCMP  Compare les N premiers caractères.
    STRNCMP(S1,S2,N) rend vrai si les N premiers caractères coïncident.

    Syntaxe
       tf = strncmp(s1,s2,n)

    Exemples
       strncmp('bonjour','bonsoir',3) % 1
       strncmp('abc','abd',3)         % 0
       noms = {'test_a','autre'};
       strncmp(noms, 'test', 4)       % [1 0]

    Voir aussi STRCMP, STRNCMPI, STARTSWITH.
```

## `strncmpi`

```
STRNCMPI  Compare les N premiers caractères, sans distinguer la casse.

    Syntaxe
       tf = strncmpi(s1,s2,n)

    Exemples
       strncmpi('Bonjour','bonsoir',3)     % 1
       strncmp('Bonjour','bonsoir',3)      % 0

    Voir aussi STRNCMP, STRCMPI, STARTSWITH.
```

## `strrep`

```
STRREP  Remplace du texte.
    S = STRREP(TEXTE,ANCIEN,NOUVEAU) remplace toutes les occurrences.

    Syntaxe
       newStr = strrep(str,ancien,nouveau)

    Exemples

       strrep('abcabc', 'b', 'X')      % 'aXcaXc'
       chemin = 'C:\\dossier\\fichier.txt';
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
STRTOK  Détache le premier morceau d'un texte.
    [T,RESTE] = STRTOK(S) coupe au premier blanc.
    [T,RESTE] = STRTOK(S,SEP) coupe au premier caractère de SEP.

    Syntaxe
       t = strtok(s)
       [t,reste] = strtok(s,sep)

    Exemples
       [mot, reste] = strtok('un deux trois')
       [cle, valeur] = strtok('nom=valeur', '=')
       strtrim(valeur(2:end))

    Voir aussi STRSPLIT, REGEXP, STRFIND.
```

## `strtrim`

```
STRTRIM  Retire les blancs de début et de fin.
    STRTRIM(S) enlève espaces, tabulations et fins de ligne aux deux bouts.

    Syntaxe
       t = strtrim(s)

    Exemples
       strtrim('   ligne   ')          % 'ligne'
       ['[' strtrim(sprintf('  a  ')) ']']
       strtrim({'  un ', ' deux'})

    Voir aussi DEBLANK, STRIP, STRREP, ISSPACE.
```

## `strvcat`

```
STRVCAT  Empile des textes en lignes, en ignorant les vides.
    STRVCAT(S1,S2,...) complète d'espaces jusqu'à la plus longue ligne.
    C'est CHAR, à ceci près que les textes vides sont sautés.

    Syntaxe
       s = strvcat(s1,s2,...)

    Exemples
       s = strvcat('un','deux');
       size(s)                            % [2 4]
       size(strvcat('a','','b'))          % 2 lignes : le vide est ignoré
       size(char('a','','b'))             % 3 lignes : char le garde

    Voir aussi CHAR, CELLSTR, STRJUST.
```

## `tolower`

```
TOLOWER  Synonyme de LOWER, hérité du C.

    Syntaxe
       t = tolower(s)

    Exemples
       tolower('ABC')                     % 'abc'
       strcmp(tolower('Oui'), lower('Oui'))

    Voir aussi LOWER, UPPER, TOUPPER.
```

## `toupper`

```
TOUPPER  Synonyme de UPPER, hérité du C.

    Syntaxe
       t = toupper(s)

    Exemples
       toupper('abc')                     % 'ABC'
       strcmp(toupper('oui'), upper('oui'))

    Voir aussi UPPER, LOWER, TOLOWER.
```

## `upper`

```
UPPER  Met le texte en majuscules.
    UPPER(S) rend S en majuscules ; ce qui n'est pas une lettre ne bouge
    pas.

    Syntaxe
       t = upper(s)

    Exemples
       upper('bonjour')               % 'BONJOUR'
       upper({'un','deux'})
       strcmp(upper('Oui'), 'OUI')

    Voir aussi LOWER, STRCMPI, STRTRIM.
```

