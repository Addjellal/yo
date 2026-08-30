# Cellules et structures

Fonctions natives du groupe `structures`.

## `cell`

```
CELL  Tableau de cellules vide.
    CELL(N) rend une cellule N par N, chaque case contenant [].
    CELL(M,N) rend une cellule M par N.

    Une cellule contient n'importe quoi dans chaque case : c'est ce qu'on
    prend quand les éléments n'ont ni la même taille ni le même type.

    Syntaxe
       C = cell(n)
       C = cell(m,n)

    Exemples
       C = cell(1,3);
       C{1} = 'texte';
       C{2} = magic(3);
       C{3} = @sin;
       class(C{2})

    Voir aussi ISCELL, CELLFUN, NUM2CELL, CELL2MAT, STRUCT.
```

## `cell2mat`

```
CELL2MAT  Recolle une cellule en un tableau.
    CELL2MAT(C) concatène le contenu des cases ; elles doivent s'assembler.

    Syntaxe
       A = cell2mat(C)

    Exemples
       cell2mat({1 2; 3 4})
       cell2mat({[1 2], [3]})         % [1 2 3]
       isequal(cell2mat(num2cell(magic(3))), magic(3))

    Voir aussi NUM2CELL, MAT2CELL, CAT, CELLFUN.
```

## `cell2struct`

```
CELL2STRUCT  Construit une structure depuis une cellule et des noms.
    CELL2STRUCT(C,CHAMPS,DIM) prend les valeurs de C et les noms de
    CHAMPS.

    Syntaxe
       s = cell2struct(c,champs,dim)

    Exemples
       s = cell2struct({1; 'deux'}, {'a','b'}, 1);
       s.a
       s.b

    Voir aussi STRUCT2CELL, STRUCT, FIELDNAMES.
```

## `deal`

```
DEAL  Distribue des valeurs à plusieurs sorties.
    [A,B,...] = DEAL(X) donne X à toutes les sorties.
    [A,B,...] = DEAL(X,Y,...) distribue une entrée par sortie.

    C'est ce qui permet d'affecter d'un coup les éléments d'une cellule.

    Syntaxe
       [a,b] = deal(x)
       [a,b] = deal(x,y)

    Exemples
       [a,b,c] = deal(0);             % tout à zéro
       [x,y] = deal(1,2);
       C = {10, 20};
       [p,q] = deal(C{:});            % 10 et 20

    Voir aussi STRUCT, CELL, VARARGOUT.
```

## `fieldnames`

```
FIELDNAMES  Noms des champs d'une structure.
    FIELDNAMES(S) rend une cellule colonne des noms, dans l'ordre où ils
    ont été créés.

    Syntaxe
       C = fieldnames(s)

    Exemples
       s = struct('a',1,'b',2);
       fieldnames(s)
       for c = fieldnames(s)'
           fprintf('%s = %g\n', c{1}, s.(c{1}));
       end

    Voir aussi ISFIELD, RMFIELD, STRUCT, ORDERFIELDS.
```

## `getfield`

```
GETFIELD  Lit un champ par son nom.
    GETFIELD(S,NOM) vaut S.(NOM) ; c'est utile quand le nom est calculé.

    Syntaxe
       v = getfield(s,nom)

    Exemples
       s = struct('largeur',3);
       getfield(s,'largeur')          % 3
       nom = 'largeur';
       s.(nom)                        % la même chose, en plus court

    Voir aussi SETFIELD, ISFIELD, FIELDNAMES.
```

## `isfield`

```
ISFIELD  La structure a-t-elle ce champ.
    ISFIELD(S,NOM) rend vrai si S porte le champ NOM.
    ISFIELD(S,{'a','b'}) rend un booléen par nom.

    Syntaxe
       tf = isfield(s,nom)
       tf = isfield(s,noms)

    Exemples
       s.largeur = 3;
       isfield(s,'largeur')           % 1
       isfield(s,{'largeur','hauteur'})  % [1 0]
       if ~isfield(s,'hauteur')
           s.hauteur = 1;             % valeur par défaut
       end

    Voir aussi FIELDNAMES, RMFIELD, ISSTRUCT, STRUCT.
```

## `mat2cell`

```
MAT2CELL  Découpe une matrice en blocs, dans une cellule.
    MAT2CELL(A,LIGNES,COLONNES) découpe A selon les tailles données ; leur
    somme doit faire la taille de A.

    Syntaxe
       C = mat2cell(A,lignes,colonnes)

    Exemples
       A = magic(4);
       C = mat2cell(A, [2 2], [2 2]);
       size(C)                        % [2 2]
       C{1,1}

    Voir aussi CELL2MAT, NUM2CELL, RESHAPE.
```

## `num2cell`

```
NUM2CELL  Un tableau vers une cellule, élément par élément.
    NUM2CELL(A) rend une cellule de la taille de A, chaque case portant un
    élément.

    Syntaxe
       C = num2cell(A)

    Exemples
       C = num2cell([1 2 3]);
       C{2}                           % 2
       size(num2cell(magic(3)))       % [3 3]

    Voir aussi CELL2MAT, MAT2CELL, CELL, ARRAYFUN.
```

## `orderfields`

```
ORDERFIELDS  Range les champs d'une structure par ordre alphabétique.

    Syntaxe
       t = orderfields(s)

    Exemples
       s = struct('b',2,'a',1);
       t = orderfields(s);
       fieldnames(t)

    Voir aussi FIELDNAMES, RMFIELD, STRUCT, SORT.
```

## `rmfield`

```
RMFIELD  Retire un champ d'une structure.
    RMFIELD(S,NOM) rend S sans ce champ.
    RMFIELD(S,{'a','b'}) en retire plusieurs.

    Syntaxe
       t = rmfield(s,nom)

    Exemples
       s = struct('a',1,'b',2,'c',3);
       t = rmfield(s,'b');
       fieldnames(t)

    Voir aussi ISFIELD, FIELDNAMES, SETFIELD, STRUCT.
```

## `setfield`

```
SETFIELD  Écrit un champ par son nom.
    SETFIELD(S,NOM,V) rend S avec le champ modifié.

    Syntaxe
       s = setfield(s,nom,v)

    Exemples
       s = struct('a',1);
       s = setfield(s,'b',2);
       fieldnames(s)

    Voir aussi GETFIELD, RMFIELD, ISFIELD.
```

## `struct`

```
STRUCT  Crée une structure.
    STRUCT('champ',valeur,...) crée une structure avec ces champs.
    STRUCT('champ',{v1,v2}) crée un tableau de structures, une par valeur
    de la cellule.
    STRUCT() crée une structure sans champ.

    Syntaxe
       s = struct('champ',valeur,...)
       s = struct()

    Exemples
       s = struct('nom','Ada','age',36);
       s.nom
       t = struct('x', {1, 2, 3});     % tableau 1x3 de structures
       numel(t)
       t(2).x

    Voir aussi ISSTRUCT, FIELDNAMES, ISFIELD, RMFIELD, STRUCT2CELL.
```

## `struct2cell`

```
STRUCT2CELL  Les valeurs d'une structure, en cellule colonne.

    Syntaxe
       c = struct2cell(s)

    Exemples
       s = struct('a',1,'b','deux');
       c = struct2cell(s);
       numel(c)                       % 2
       c{2}

    Voir aussi CELL2STRUCT, FIELDNAMES, STRUCT, NUM2CELL.
```

