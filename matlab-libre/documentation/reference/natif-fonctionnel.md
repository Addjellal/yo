# Fonctions de fonctions

Fonctions natives du groupe `fonctionnel`.

## `arrayfun`

```
ARRAYFUN  Applique une fonction à chaque élément d'un tableau.
    ARRAYFUN(F,A) applique F à chaque élément ; F doit rendre un scalaire.
    ARRAYFUN(F,A,'UniformOutput',false) rend une cellule, ce qui permet à F
    de rendre n'importe quoi.

    Syntaxe
       B = arrayfun(f,A)
       C = arrayfun(f,A,'UniformOutput',false)

    Exemples
       arrayfun(@(x) x^2, 1:4)                    % [1 4 9 16]
       arrayfun(@(n) zeros(1,n), 1:3, 'UniformOutput', false)
       arrayfun(@(a,b) a+b, [1 2], [10 20])       % [11 22]

    Voir aussi CELLFUN, STRUCTFUN, MAP, FOR.
```

## `assignin`

```
assignin  Affecte dans un autre espace.
```

## `cellfun`

```
CELLFUN  Applique une fonction à chaque case d'une cellule.
    A = CELLFUN(F,C) applique F à chaque case et rend un tableau. F doit
    rendre un scalaire, sinon employer 'UniformOutput'.
    A = CELLFUN(F,C,'UniformOutput',false) rend une cellule : c'est ce
    qu'il faut dès que les résultats ne sont pas des scalaires.
    CELLFUN(F,C1,C2) applique F case par case sur plusieurs cellules.

    Syntaxe
       A = cellfun(f,C)
       A = cellfun(f,C,'UniformOutput',false)

    Exemples

       cellfun(@numel, {'a','bb','ccc'})            % [1 2 3]
       noms = {'ada', 'grace'};
       cellfun(@(s) upper(s), noms, 'UniformOutput', false)
       C = {[], 1, []};
       cellfun(@isempty, C)

    Voir aussi ARRAYFUN, STRUCTFUN, CELL2MAT, MAP.
```

## `eval`

```
eval  Evalue du code.
```

## `evalc`

```
evalc  Evalue et capture l'affichage.
```

## `evalin`

```
evalin  Evalue dans un autre espace.
```

## `exist`

```
EXIST  Ce que désigne un nom.
    E = EXIST(NOM) rend :
       0  rien
       1  une variable
       2  un fichier
       5  une fonction native
       7  un dossier
       8  une classe
    E = EXIST(NOM,GENRE) restreint la recherche : 'var', 'file', 'dir',
    'builtin', 'class'.

    Syntaxe
       e = exist(nom)
       e = exist(nom,genre)

    Exemples

       resultat = 1;
       if exist('resultat','var')
           disp('la variable existe');
       end
       if exist('donnees.mat','file') == 2
           disp('le fichier est là');
       end

    Voir aussi WHICH, ISFIELD, ISVARNAME.
```

## `feval`

```
FEVAL  Appelle une fonction désignée par son nom ou sa poignée.
    FEVAL(F,X1,...) appelle F avec les arguments donnés ; F est une
    poignée « @sin » ou un nom 'sin'.

    Syntaxe
       y = feval(f,x1,...)
       [y1,y2] = feval(f,...)

    Exemples
       feval(@sin, pi/2)              % 1
       feval('max', [3 1 4])          % 4
       nom = 'sqrt';
       feval(nom, 16)                 % 4

    Voir aussi FUNC2STR, STR2FUNC, ARRAYFUN, CELLFUN.
```

## `func2str`

```
FUNC2STR  Rend le texte d'une poignée de fonction.

    Syntaxe
       texte = func2str(f)

    Exemples
       func2str(@sin)                 % 'sin'
       func2str(@(x) x + 1)

    Voir aussi STR2FUNC, FEVAL.
```

## `functions`

```
functions  Information sur une poignee.
```

## `inputname`

```
inputname  Nom de l'argument appelant.
```

## `is_function_handle_`

```
Reserve.
```

## `isvarname`

```
isvarname  Nom de variable valide.
```

## `nargin`

```
NARGIN  Nombre d'arguments réellement passés à la fonction courante.
    NARGIN, dans le corps d'une fonction, rend le nombre d'entrées reçues :
    c'est ainsi qu'on donne des valeurs par défaut.
    NARGIN('nom') rend le nombre d'entrées déclarées par la fonction.

    Syntaxe
       n = nargin
       n = nargin('nom')

    Exemples
       f = @(varargin) numel(varargin);
       f(1,2,3)                       % 3
       nargin('size')

    Voir aussi NARGOUT, NARGINCHK, VARARGIN, EXIST.
```

## `narginchk`

```
narginchk  Verifie le nombre d'entrees.
```

## `nargout`

```
NARGOUT  Nombre de sorties demandées à la fonction courante.
    NARGOUT permet de ne calculer que ce qu'on demande : « [~,i] = max(x) »
    n'a pas le même coût que « m = max(x) ».
    NARGOUT('nom') rend le nombre de sorties déclarées.

    Syntaxe
       n = nargout
       n = nargout('nom')

    Exemples
       nargout('size')
       [m,i] = max([3 9 4]);          % la fonction voit nargout == 2

    Voir aussi NARGIN, NARGOUTCHK, VARARGOUT.
```

## `nargoutchk`

```
nargoutchk  Verifie le nombre de sorties.
```

## `run`

```
run  Execute un script, meme hors du chemin de recherche.
```

## `str2func`

```
STR2FUNC  Fabrique une poignée à partir d'un texte.
    STR2FUNC('sin') rend @sin.
    STR2FUNC('@(x) x.^2') rend la fonction anonyme écrite dans le texte.

    Syntaxe
       f = str2func(texte)

    Exemples
       f = str2func('cos');
       f(0)                           % 1
       g = str2func('@(x) x.^2 + 1');
       g(3)                           % 10

    Voir aussi FUNC2STR, FEVAL, ARRAYFUN.
```

## `structfun`

```
STRUCTFUN  Applique une fonction à chaque champ d'une structure.
    STRUCTFUN(F,S) applique F à chaque valeur et rend un vecteur colonne.
    STRUCTFUN(F,S,'UniformOutput',false) rend une structure.

    Syntaxe
       v = structfun(f,s)
       t = structfun(f,s,'UniformOutput',false)

    Exemples
       s = struct('a',1,'b',4);
       structfun(@(x) x*2, s)
       structfun(@(x) x*2, s, 'UniformOutput', false)

    Voir aussi ARRAYFUN, CELLFUN, FIELDNAMES.
```

