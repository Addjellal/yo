# Fonctions de fonctions

Fonctions natives du groupe `fonctionnel`.

## `arrayfun`

```
ARRAYFUN  Applique une fonction à chaque élément d'un tableau.
    B = ARRAYFUN(F,A) applique F à chaque élément.
    B = ARRAYFUN(F,A,'UniformOutput',false) rend une cellule.

    Une opération vectorisée est presque toujours plus rapide :
    ARRAYFUN sert quand la fonction ne se vectorise pas.

    Syntaxe
       B = arrayfun(f,A)
       B = arrayfun(f,A,'UniformOutput',false)

    Exemples
       arrayfun(@(k) k^2, 1:4)                      % [1 4 9 16]
       arrayfun(@(k) zeros(k), 1:3, 'UniformOutput', false)

    Voir aussi CELLFUN, STRUCTFUN, BSXFUN.
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
       cellfun(@(s) upper(s), noms, 'UniformOutput', false)
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
       if exist('resultat','var'), ... end
       if exist('donnees.mat','file') == 2, ... end

    Voir aussi WHICH, ISFIELD, ISVARNAME.
```

## `feval`

```
feval  Appelle une fonction nommee.
```

## `func2str`

```
func2str  Poignee -> texte.
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
nargin  Nombre d'arguments recus.
```

## `narginchk`

```
narginchk  Verifie le nombre d'entrees.
```

## `nargout`

```
nargout  Nombre de sorties demandees.
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
str2func  Texte -> poignee.
```

## `structfun`

```
structfun  Applique a chaque champ.
```

