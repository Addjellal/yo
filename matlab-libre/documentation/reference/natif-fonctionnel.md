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
ASSIGNIN  Écrit une variable dans un autre espace de travail.
    ASSIGNIN('base',NOM,VALEUR) crée la variable dans l'espace de base.

    Syntaxe
       assignin(ou,nom,valeur)

    Exemples
       assignin('base', 'resultatFinal', 3);
       evalin('base', 'resultatFinal')

    Voir aussi EVALIN, EVAL, GLOBAL.
```

## `builtin`

```
BUILTIN  Appelle la fonction native, sans passer par les surcharges.
    BUILTIN(NOM,ARG1,...) appelle la fonction native NOM même si une
    méthode de classe ou un fichier .m du chemin porte le même nom. C'est
    ce qu'écrit une méthode qui veut le comportement de base du type
    qu'elle surcharge — un SUBSREF de classe, par exemple, qui délègue au
    SUBSREF ordinaire ce qu'il ne traite pas lui-même.

    [A,B,...] = BUILTIN(...) rend plusieurs sorties, comme l'appel direct.

    Syntaxe
       y = builtin(nom,arg1,...)

    Exemples
       builtin('size', ones(2,3))       % [2 3]
       builtin(@max, [1 5 2])           % 5

    Voir aussi FEVAL, SUBSREF, SUBSASGN, WHICH, EXIST.
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
EVAL  Exécute du code écrit dans un texte.
    EVAL(TEXTE) exécute le texte.
    X = EVAL(TEXTE) évalue une expression et rend sa valeur.
    EVAL(TEXTE,SECOURS) exécute SECOURS si le premier échoue.

    Le code écrit dans du texte échappe à toute vérification : quand une
    autre voie existe — une poignée de fonction, un champ dynamique
    « s.(nom) », une cellule —, elle est préférable.

    Syntaxe
       eval(texte)
       x = eval(texte)
       eval(texte,secours)

    Exemples
       eval('a = 1 + 1;');
       a
       x = eval('2^10')
       eval('zzzInconnu', 'disp(''secours'')');

    Voir aussi EVALC, EVALIN, ASSIGNIN, FEVAL, STR2FUNC.
```

## `evalc`

```
EVALC  Évalue du texte en capturant l'affichage.
    EVALC(TEXTE) exécute le texte et rend tout ce qui aurait été affiché.
    C'est ainsi qu'on teste ce qu'une fonction imprime.

    Syntaxe
       s = evalc(texte)

    Exemples
       s = evalc('disp(''bonjour'')');
       strtrim(s)
       s2 = evalc('1+1');
       ~isempty(strfind(s2, '2'))

    Voir aussi EVAL, DIARY, DISP, SPRINTF.
```

## `evalin`

```
EVALIN  Évalue du texte dans un autre espace de travail.
    EVALIN('base',TEXTE) évalue dans l'espace de travail de base ;
    EVALIN('caller',TEXTE) dans celui de l'appelant.

    Syntaxe
       evalin(ou,texte)
       v = evalin(ou,texte)

    Exemples
       assignin('base', 'venuDAilleurs', 42);
       evalin('base', 'venuDAilleurs')

    Voir aussi ASSIGNIN, EVAL, EVALC.
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
FUNCTIONS  Renseignements sur une poignée de fonction.
    FUNCTIONS(F) rend une structure : le nom, le type ('simple' ou
    'anonymous'), et le fichier.

    Syntaxe
       s = functions(f)

    Exemples
       s = functions(@sin);
       s.function
       t = functions(@(x) x+1);
       t.type

    Voir aussi FUNC2STR, STR2FUNC, FEVAL, CLASS.
```

## `inputname`

```
INPUTNAME  Nom de la variable passée en argument.
    INPUTNAME(K) rend le nom de la K-ième entrée telle que l'appelant l'a
    écrite, ou le texte vide si ce n'était pas une variable.

    Syntaxe
       nom = inputname(k)

    Exemples
       f = @(x) class(x);
       f(1)

    Voir aussi MFILENAME, NARGIN, DBSTACK.
```

## `isvarname`

```
ISVARNAME  Le texte est-il un nom de variable valide.
    Un nom valide commence par une lettre et ne contient que lettres,
    chiffres et « _ ».

    Syntaxe
       tf = isvarname(s)

    Exemples
       isvarname('x1')                % 1
       isvarname('1x')                % 0
       isvarname('mon nom')           % 0

    Voir aussi GENVARNAME, EXIST, FIELDNAMES.
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
NARGINCHK  Vérifie le nombre d'arguments d'entrée.
    NARGINCHK(MIN,MAX) lève une erreur si NARGIN sort de l'intervalle.

    Syntaxe
       narginchk(min,max)

    Exemples
       try
           narginchk(2, 3);
       catch e
           disp(e.identifier);
       end

    Voir aussi NARGOUTCHK, NARGIN, VALIDATEATTRIBUTES, ERROR.
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
NARGOUTCHK  Vérifie le nombre d'arguments de sortie.
    NARGOUTCHK(MIN,MAX) lève une erreur si NARGOUT sort de l'intervalle.

    Syntaxe
       nargoutchk(min,max)

    Exemples
       nargoutchk(0, 2);

    Voir aussi NARGINCHK, NARGOUT, ERROR.
```

## `run`

```
RUN  Exécute un script désigné par son chemin.
    RUN(CHEMIN) exécute le script dans l'espace de travail courant, même
    si son dossier n'est pas sur le chemin de recherche — et même si son
    nom n'est pas un identifiant valide.

    Syntaxe
       run(chemin)

    Exemples
       f = fullfile(tempdir,'monScript.m');
       fid = fopen(f,'w'); fprintf(fid,'venuDuScript = 7;\n'); fclose(fid);
       run(f);
       venuDuScript                   % 7 — le script partage l'espace de travail
       delete(f);

    Voir aussi ADDPATH, EVAL, TYPE, WHICH.
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

