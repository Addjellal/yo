# Toolbox `symbolique`

```
% Symbolic Math Toolbox — calcul formel.
%
% Une expression est un arbre : {operateur, sous-expression, ...}, les
% feuilles étant des nombres ou des noms de variables. Les fonctions
% ci-dessous manipulent cet arbre.
%
%   symvar, symnum   - Feuilles : variable, constante
%   symadd, symsub, symmul, symdiv, sympow, symfun - Constructeurs
%   symdiff          - Dérivée par rapport à une variable
%   symsimplify      - Simplification des cas triviaux
%   symsubs          - Substitution
%   symeval          - Évaluation numérique
%   symstr           - Écriture lisible
%   symint           - Primitive des formes polynomiales
```

## `symadd`

```
SYMADD Somme de deux expressions.
```

## `symdiff`

```
SYMDIFF Dérivée symbolique d'une expression.
  D = SYMDIFF(E,'x') applique les règles usuelles : somme, produit,
  quotient, puissance et composition des fonctions élémentaires.
```

## `symdiv`

```
SYMDIV Quotient de deux expressions.
```

## `symeval`

```
SYMEVAL Évaluation numérique d'une expression.
  V = SYMEVAL(E,{'x','y'},[1 2]) remplace puis calcule.
```

## `symfun`

```
SYMFUN Application d'une fonction élémentaire.
  Fonctions reconnues : sin, cos, tan, exp, log, sqrt.
```

## `symint`

```
SYMINT Primitive des formes polynomiales et élémentaires.
  Reconnaît les constantes, x^n, sin, cos, exp et les sommes.
```

## `symmul`

```
SYMMUL Produit de deux expressions.
```

## `symnum`

```
SYMNUM Feuille « constante ».
```

## `sympow`

```
SYMPOW Puissance : A élevé à B.
```

## `symsimplify`

```
SYMSIMPLIFY Simplification des cas triviaux (0, 1, constantes).
```

## `symstr`

```
SYMSTR Écriture lisible d'une expression symbolique.
```

## `symsub`

```
SYMSUB Différence de deux expressions.
```

## `symsubs`

```
SYMSUBS Substitution d'une variable par une expression ou un nombre.
```

## `symvar`

```
SYMVAR Feuille « variable ».
```

