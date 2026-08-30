# cartes

Fonctions natives du groupe `cartes`.

## `containers.Map`

```
CONTAINERS.MAP  Dictionnaire : une valeur par clé.
    M = CONTAINERS.MAP() crée une table vide, dont les clés sont des
    chaînes. M = CONTAINERS.MAP(CLES,VALEURS) la remplit d'emblée, à
    partir de deux tableaux de cellules de même longueur.
    M = CONTAINERS.MAP('KeyType',K,'ValueType',V) impose les types.

    On lit et l'on écrit par la clé, entre parenthèses. La table est un
    objet à référence : la passer à une fonction ne la copie pas, et ce
    que la fonction y écrit se voit au retour.

    Syntaxe
       M = containers.Map()
       M = containers.Map(cles,valeurs)
       valeur = M(cle)
       M(cle) = valeur

    Exemples
       m = containers.Map({'a', 'b'}, {1, 2});
       m('a')                 % 1
       m('c') = 3;
       m.isKey('c')           % vrai
       m.Count                % 3
       sort(m.keys)           % {'a', 'b', 'c'}

    Voir aussi ISKEY, KEYS, VALUES, REMOVE, STRUCT, DICTIONARY.
```

## `isKey`

```
ISKEY  La table contient-elle cette clé.

    Syntaxe
       tf = isKey(m,cle)

    Exemples
       m = containers.Map({'a','b'}, {1, 2});
       isKey(m,'a')                   % 1
       isKey(m,'z')                   % 0
       if ~isKey(m,'z'), m('z') = 0; end

    Voir aussi CONTAINERS, KEYS, VALUES, REMOVE.
```

## `keys`

```
KEYS  Les clés d'une table associative, triées.

    Syntaxe
       c = keys(m)

    Exemples
       m = containers.Map({'b','a'}, {2, 1});
       keys(m)                        % {'a','b'} — triées
       numel(keys(m))

    Voir aussi VALUES, ISKEY, CONTAINERS, REMOVE.
```

## `mapCount`

```
MAPCOUNT  Nombre d'entrées d'un dictionnaire.
    MAPCOUNT(M) rend le nombre de clés que porte la table M. C'est ce que
    rend la propriété M.Count, sous forme de fonction : utile pour la
    passer à CELLFUN ou ARRAYFUN.

    Syntaxe
       N = mapCount(M)

    Exemples
       m = containers.Map({'a', 'b'}, {1, 2});
       mapCount(m)            % 2
       m('c') = 3;
       mapCount(m)            % 3
       mapCount(containers.Map())     % 0

    Voir aussi CONTAINERS.MAP, KEYS, VALUES, ISKEY, NUMEL.
```

## `remove`

```
REMOVE  Retire une clé d'une table associative.

    Syntaxe
       m = remove(m,cle)

    Exemples
       m = containers.Map({'a','b'}, {1, 2});
       remove(m,'a');
       keys(m)

    Voir aussi CONTAINERS, ISKEY, KEYS, RMFIELD.
```

## `values`

```
VALUES  Les valeurs d'une table associative, dans l'ordre des clés.

    Syntaxe
       c = values(m)
       c = values(m,cles)

    Exemples
       m = containers.Map({'a','b'}, {1, 2});
       values(m)
       values(m, {'b'})

    Voir aussi KEYS, ISKEY, CONTAINERS.
```

