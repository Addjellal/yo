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
ASSERTALMOSTEQUAL  Vérifie l'égalité à une tolérance près.
    ASSERTALMOSTEQUAL(A,B) accepte un écart de l'ordre de l'arrondi.
    ASSERTALMOSTEQUAL(A,B,TOL) impose la tolérance.

    C'est ce qu'il faut pour comparer des flottants : « 0.1+0.2 == 0.3 »
    est faux.

    Syntaxe
       assertAlmostEqual(a,b)
       assertAlmostEqual(a,b,tol)

    Exemples
       assertAlmostEqual(0.1 + 0.2, 0.3);
       assertAlmostEqual(pi, 3.14159, 1e-4);

    Voir aussi ASSERTEQUAL, ASSERT, EPS.
```

## `assertElementsAlmostEqual`

```
ASSERTELEMENTSALMOSTEQUAL  Compare deux tableaux, élément par élément, à
    une tolérance près.

    Syntaxe
       assertElementsAlmostEqual(a,b)
       assertElementsAlmostEqual(a,b,tol)

    Exemples
       assertElementsAlmostEqual([1 2] + 1e-14, [1 2]);

    Voir aussi ASSERTALMOSTEQUAL, ASSERTEQUAL, ASSERT.
```

## `assertEqual`

```
ASSERTEQUAL  Vérifie l'égalité de deux valeurs, dans un test.
    ASSERTEQUAL(A,B) lève une erreur si A et B diffèrent.

    Syntaxe
       assertEqual(a,b)

    Exemples
       assertEqual([1 2], [1 2]);
       try
           assertEqual(1, 2);
       catch e
           disp('différent, comme attendu');
       end

    Voir aussi ASSERT, ASSERTALMOSTEQUAL, ASSERTERROR, ISEQUAL.
```

## `assertError`

```
ASSERTERROR  Vérifie qu'un appel lève bien une erreur.
    ASSERTERROR(F) échoue si F ne lève rien.
    ASSERTERROR(F,ID) exige en plus l'identifiant.

    Syntaxe
       assertError(f)
       assertError(f,id)

    Exemples
       assertError(@() error('rate'));
       assertError(@() error('Mon:id','rate'), 'Mon:id');

    Voir aussi ASSERT, ERROR, MEXCEPTION, TRY.
```

## `fail`

```
FAIL  Faire échouer un test, avec un message.
    FAIL(MESSAGE) lève une erreur d'identifiant
    « MATLAB:assertion:failed ». C'est ce qu'on écrit dans la branche
    d'un test qui n'aurait jamais dû être atteinte — là où ASSERT n'a
    rien à comparer.

    Syntaxe
       fail(message)

    Exemples
       essai = false;
       try
           fail('cette branche ne devrait pas etre atteinte');
       catch e
           essai = strcmp(e.identifier, 'MATLAB:assertion:failed');
       end
       essai                  % vrai

    Voir aussi ASSERT, ERROR, TRY, MEXCEPTION.
```

## `runtests`

```
RUNTESTS  Exécute les scripts de test d'un dossier.
    RUNTESTS(DOSSIER) exécute les fichiers « test_*.m » et rend le compte
    rendu.

    Syntaxe
       resultats = runtests(dossier)

    Exemples
       % resultats = runtests('tests/scripts');
       disp('runtests exécute une campagne entière');

    Voir aussi ASSERT, ERROR, PROFILE.
```

