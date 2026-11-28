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

Les arguments nom-valeur s'écrivent aussi `f(x, Nom=valeur)`, la forme
de MATLAB depuis R2021a : la fonction reçoit `"Nom", valeur`, le nom en
chaîne, comme si on l'avait écrit ainsi. Comme dans MATLAB, cette forme
ne vaut que dans les parenthèses d'un appel, après tous les autres
arguments — un argument ordinaire qui la suit est refusé à l'analyse —,
et elle ne sert pas à indexer une variable.

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

Un dossier `+geo` sur le chemin fait un paquet : `+geo/distance.m` se
nomme `geo.distance`, `+geo/Point.m` la classe `geo.Point`, et un
`+unites` dedans `geo.unites.f`. Comme sous MATLAB, une fonction de
paquet ne répond pas à son nom court ; une classe de paquet se dérive
(`classdef Point3 < geo.Point`, `p@geo.Point(x, y)`), et ses méthodes
statiques et constantes s'atteignent par `geo.Point.origine()`.

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

Au terminal, la ligne de commande s'édite comme dans la fenêtre de
commandes de MATLAB :

| touche | effet |
|---|---|
| ← →, Début, Fin (Ctrl-A, Ctrl-E) | se déplacer ; Ctrl-← et Ctrl-→ par mot |
| ↑ ↓ | l'historique, filtré par ce qui est déjà tapé : `pl` puis ↑ rappelle le dernier `plot(...)` |
| Tab | compléter une variable, une fonction, un champ (`s.al` → `s.alpha`), un fichier entre apostrophes ou après `cd`, `load`, `run`… ; quand les choix ne s'accordent plus, les montrer |
| Échap | effacer la ligne |
| Ctrl-K, Ctrl-U, Ctrl-W | couper jusqu'au bout, jusqu'au début, le mot précédent |
| Ctrl-C | abandonner la ligne (pendant un calcul : l'interrompre) |
| Ctrl-D | sur une ligne vide, finir la session |
| Ctrl-L | effacer l'écran |

L'historique se garde d'une session à l'autre dans `~/.matlibre_historique`
(lisible de son seul propriétaire, mille commandes) ; la variable
`MATLIBRE_HISTORIQUE` en donne un autre, ou, vide, n'en garde aucun. Après
une faute de frappe, la commande corrigée du « Did you mean: » est posée
dans la saisie : Entrée l'exécute, Échap l'efface. Sous
`MATLIBRE_EDITION=0`, ou quand la sortie n'est pas un terminal, la console
lit ligne à ligne, sans édition ; quand l'entrée n'est pas un terminal (un
tube, un fichier), elle n'écrit pas non plus d'invite.
