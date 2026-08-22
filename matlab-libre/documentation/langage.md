# Le langage reconnu

Ce document liste ce que MatLibre comprend. Ce qui n'y figure pas n'est
pas reconnu ; la liste des écarts connus est dans
[`couverture.md`](couverture.md).

## Types

| Classe | Exemple | Remarque |
|---|---|---|
| `double` | `3.14`, `1e-3`, `0x1F`, `0b1010` | par défaut |
| `single` | `single(1)` | arrondi à la précision simple |
| `int8` … `uint64` | `int32(7)` | saturation aux bornes, arrondi au plus loin de zéro |
| `logical` | `true`, `x > 0` | |
| `char` | `'abc'` | tableau de codes |
| `string` | `"abc"` | `+` concatène |
| `cell` | `{1, 'deux'}` | `{}` imbrique, `[]` concatène |
| `struct` | `s.a = 1` | tableaux de structures compris |
| `function_handle` | `@sin`, `@(x) x^2` | |
| complexes | `3 + 4i` | toutes les opérations élémentaires |

Conversions : `double`, `single`, `int8`…`uint64`, `logical`, `char`,
`string`, `cell`, `cast`, `complex`.

## Opérateurs

Arithmétique `+ - * / \ ^` et leurs formes élément par élément
`.* ./ .\ .^` ; transposition `'` (conjuguée) et `.'` ; comparaisons
`== ~= < <= > >=` ; logique `& | ~ && ||` ; plage `a:b`, `a:pas:b`.

L'expansion implicite s'applique partout : `[1;2] + [10 20]` donne une
matrice 2×2.

## Instructions

```matlab
if cond, ... elseif cond, ... else, ... end
for k = expression, ... end          % parcourt les colonnes
parfor k = 1:n, ... end              % exécuté séquentiellement
while cond, ... end
do ... until cond                    % extension Octave
switch expr, case v, ... case {a,b}, ... otherwise, ... end
try, ... catch e, ... end
break, continue, return
global a b
persistent compteur
```

Le point-virgule éteint l'affichage. La virgule et le retour à la ligne le
laissent. `...` continue une ligne. `%` et `#` commencent un commentaire,
`%{ ... %}` un bloc.

Les affectations composées `+= -= *= /= ^=` et les incréments `++ --` sont
acceptés (extension Octave, également reconnue par MATLAB récent pour les
premières).

## Fonctions

```matlab
function [s1, s2] = nom(a, b, varargin)
    ...
end
```

`nargin`, `nargout`, `varargin`, `varargout`, `narginchk` fonctionnent
comme documenté. Un fichier peut contenir plusieurs fonctions : la
première porte le nom du fichier, les suivantes lui sont privées. Un
script peut définir des fonctions locales, écrites en fin de fichier,
comme MATLAB l'exige depuis R2016b.

Fonctions anonymes : `f = @(x, y) x + y`. La capture est faite à la
création, par valeur.

## Classes

```matlab
classdef Compteur
    properties
        valeur = 0
    end
    methods
        function obj = Compteur(depart)
            obj.valeur = depart;
        end
        function obj = incrementer(obj)
            obj.valeur = obj.valeur + 1;
        end
        function r = plus(a, b)
            r = Compteur(a.valeur + b.valeur);
        end
    end
end
```

Sémantique de valeur. Les méthodes d'opérateur (`plus`, `minus`, `mtimes`,
`eq`, `lt`…) sont appelées quand un opérande est un objet.

## Indexation

```matlab
A(2, 3)        A(:, 2)        A(end)       A(A > 0)
A(2, :) = []   A(5) = 7       % suppression, croissance
c{2}           c{:}           % liste séparée par des virgules
s.champ        s.(nom)        s(3).champ
```

## Entrées-sorties

`disp`, `fprintf`, `sprintf`, `num2str`, `mat2str`, `input`, `error`,
`warning`, `fopen`/`fclose`/`fgetl`/`fread`/`fwrite`, `fileread`,
`dlmread`/`dlmwrite`, `csvread`/`csvwrite`.

Le formatage suit celui de MATLAB, y compris le recyclage du format :
`sprintf('%d,', [1 2 3])` rend `1,2,3,`.

## Erreurs

`error('Composant:mnemonique', 'texte %d', 3)` lève une erreur dont
`try/catch` retrouve l'identifiant :

```matlab
try
    A = [1 2];
    A(5)
catch e
    disp(e.identifier);   % MATLAB:badsubscript
end
```

Les identifiants utilisés sont ceux de la documentation publique :
`MATLAB:UndefinedFunction`, `MATLAB:badsubscript`, `MATLAB:innerdim`,
`MATLAB:nonExistentField`, `MATLAB:dimagree`…

## Ligne de commande

```
matlibre                     interpréteur interactif
matlibre script.m a b        exécute un script, argv contient {'a','b'}
matlibre -e "expression"     évalue puis quitte
matlibre --path DOSSIER ...  ajoute un dossier au chemin de recherche
matlibre --test DOSSIER      exécute les fichiers test_*.m du dossier
```
