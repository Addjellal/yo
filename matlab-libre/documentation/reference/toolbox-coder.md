# Toolbox `coder`

```
% MATLAB Coder — génération de code C.
%
% Le générateur traduit un sous-ensemble volontairement restreint du
% langage : fonctions à arguments scalaires, affectations, if, for, while,
% et les opérateurs arithmétiques et de comparaison. C'est le cœur de ce
% qu'on veut embarquer ; tout ce qui sort du sous-ensemble est signalé
% clairement plutôt que traduit approximativement.
%
%   codegen      - Traduit un fichier .m en C
%   codegenBuild - Traduit puis compile avec le compilateur du système
```

## `codegen`

```
CODEGEN Traduit une fonction MATLAB scalaire en C.
  CODE = CODEGEN('nom') rend le texte du fichier C.
  CODEGEN('nom','sortie.c') l'écrit sur disque.
```

## `codegenBuild`

```
CODEGENBUILD Génère le C puis le compile avec le compilateur du système.
```

