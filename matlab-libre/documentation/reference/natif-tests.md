# Assertions et tests

Fonctions natives du groupe `tests`.

## `assert`

```
ASSERT  Vérifie une condition, et lève une erreur sinon.
    ASSERT(COND) lève une erreur si COND est faux.
    ASSERT(COND,MESSAGE,...) donne le message, avec le format de SPRINTF.
    ASSERT(COND,ID,MESSAGE,...) donne aussi l'identifiant.

    Syntaxe
       assert(cond)
       assert(cond,message,...)
       assert(cond,id,message,...)

    Exemples
       assert(1 + 1 == 2);
       n = 3;
       assert(n > 0, 'n doit être positif, reçu %d', n);
       try
           assert(false, 'MonModule:rate', 'raté');
       catch e
           disp(e.identifier);
       end

    Voir aussi ERROR, VALIDATEATTRIBUTES, TRY, WARNING.
```

## `assertAlmostEqual`

```
assertAlmostEqual  Egalite a une tolerance pres.
```

## `assertElementsAlmostEqual`

```
assertElementsAlmostEqual  Egalite element par element.
```

## `assertEqual`

```
assertEqual  Egalite exacte.
```

## `assertError`

```
assertError  Verifie qu'une fonction leve une erreur.
```

## `fail`

```
fail  Fait echouer un test.
```

## `runtests`

```
runtests  Execute les fichiers de test d'un dossier.
```

