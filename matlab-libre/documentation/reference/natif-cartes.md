# cartes

Fonctions natives du groupe `cartes`.

## `containers.Map`

```
containers.Map  Table associative a semantique de poignee.
  M = containers.Map() cree une table vide.
  M = containers.Map(CLES, VALEURS) l'initialise.
  M('cle') lit, M('cle') = v ecrit, keys/values/isKey/remove.
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
mapCount  Nombre d'entrees.
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

