# Polynomes et interpolation

Fonctions natives du groupe `polynomes`.

## `deconv`

```
DECONV  Division polynomiale.
    [Q,R] = DECONV(A,B) rend le quotient et le reste de A par B : c'est
    l'inverse de CONV.

    Syntaxe
       [q,r] = deconv(a,b)

    Exemples
       [q, r] = deconv([1 0 -1], [1 1]);
       q                              % [1 -1], soit x - 1
       all(abs(r) < 1e-12)

    Voir aussi CONV, POLYDIV, ROOTS, FILTER.
```

## `interp1`

```
INTERP1  Interpolation en une dimension.
    VQ = INTERP1(X,V,XQ) interpole les valeurs V définies aux points X,
    aux points demandés XQ. X doit être monotone.
    VQ = INTERP1(X,V,XQ,METHODE) choisit la méthode : 'linear' (défaut),
    'nearest', 'previous', 'next', 'pchip', 'spline', 'cubic'.
    VQ = INTERP1(X,V,XQ,METHODE,EXTRAP) donne la valeur hors bornes, ou
    'extrap' pour extrapoler. Sans cela, hors bornes rend NaN.

    Syntaxe
       vq = interp1(x,v,xq)
       vq = interp1(x,v,xq,methode)
       vq = interp1(x,v,xq,methode,extrapolation)

    Exemples

       interp1([1 2 3], [10 20 30], 2.5)        % 25
       t = 0:0.5:10;  y = sin(t);  tq = 0:0.1:10;
       yq = interp1(t, y, tq, 'spline');
       yq = interp1(t, y, tq, 'linear', 0);     % 0 hors bornes

    Voir aussi INTERP2, SPLINE, PCHIP, POLYFIT.
```

## `interp2`

```
INTERP2  Interpolation sur une grille à deux dimensions.
    INTERP2(X,Y,Z,XQ,YQ) interpole Z, défini sur la grille (X,Y), aux
    points demandés.

    Syntaxe
       zq = interp2(X,Y,Z,xq,yq)
       zq = interp2(X,Y,Z,xq,yq,methode)

    Exemples
       [X, Y] = meshgrid(0:4);
       Z = X + Y;
       abs(interp2(X, Y, Z, 1.5, 2.5) - 4) < 1e-12

    Voir aussi INTERP1, MESHGRID, SURF, SPLINE.
```

## `poly`

```
POLY  Polynôme dont on donne les racines, ou polynôme caractéristique.
    POLY(R), R étant un vecteur de racines, rend les coefficients du
    polynôme unitaire correspondant.
    POLY(A), A étant une matrice carrée, rend son polynôme
    caractéristique.

    Syntaxe
       p = poly(r)
       p = poly(A)

    Exemples
       poly([1 -1])                   % [1 0 -1], soit x^2 - 1
       p = poly([2 3]);
       sort(roots(p))'                % [2 3], on revient aux racines
       poly([2 0; 0 3])

    Voir aussi ROOTS, POLYVAL, CONV, EIG.
```

## `polyder`

```
POLYDER  Dérivée d'un polynôme.
    POLYDER(P) rend les coefficients de la dérivée.
    POLYDER(A,B) dérive le produit A*B.

    Syntaxe
       d = polyder(p)
       d = polyder(a,b)

    Exemples
       polyder([1 0 -1])              % [2 0], soit 2x
       p = [1 -3 2];
       racinesExtremum = roots(polyder(p));

    Voir aussi POLYINT, POLYVAL, ROOTS, DIFF.
```

## `polyfit`

```
POLYFIT  Ajuste un polynôme aux moindres carrés.
    P = POLYFIT(X,Y,N) rend les coefficients du polynôme de degré N qui
    passe au plus près des points (X,Y), du degré le plus élevé au terme
    constant.
    [P,S] = POLYFIT(...) rend en plus une structure utile à POLYVAL pour
    estimer l'erreur.

    Syntaxe
       p = polyfit(x,y,n)
       [p,S] = polyfit(x,y,n)

    Exemples

       x = 0:10;
       y = 2*x + 1 + 0.1*randn(1,11);
       p = polyfit(x, y, 1);            % droite de régression
       yAjuste = polyval(p, x);
       plot(x, y, 'o', x, yAjuste, '-');

    Voir aussi POLYVAL, ROOTS, MLDIVIDE, INTERP1.
```

## `polyint`

```
POLYINT  Primitive d'un polynôme.
    POLYINT(P) rend la primitive de constante nulle.
    POLYINT(P,K) impose la constante d'intégration.

    Syntaxe
       q = polyint(p)
       q = polyint(p,k)

    Exemples
       polyint([2 0])                 % [1 0 0], soit x^2
       p = [3 0 0];
       q = polyint(p);
       polyval(q, 2) - polyval(q, 0)  % l'intégrale de 0 à 2

    Voir aussi POLYDER, POLYVAL, TRAPZ, INTEGRAL.
```

## `polyval`

```
POLYVAL  Évalue un polynôme.
    Y = POLYVAL(P,X) évalue en X le polynôme dont les coefficients sont
    P, du degré le plus élevé au terme constant.

    Syntaxe
       y = polyval(p,x)
       [y,delta] = polyval(p,x,S)

    Exemples

       polyval([1 0 -1], 2)             % x^2 - 1 en x = 2, soit 3
       x = 0:5;  y = x.^3 - x;  xq = 0:0.5:5;
       polyval(polyfit(x,y,3), xq)

    Voir aussi POLYFIT, ROOTS, CONV, POLYDER.
```

## `polyvalm`

```
POLYVALM  Évalue un polynôme au sens matriciel.
    POLYVALM(P,A) remplace x par la matrice A : x² devient A*A, et le
    terme constant devient c*EYE(A).

    Syntaxe
       Y = polyvalm(p,A)

    Exemples
       A = [1 2; 3 4];
       polyvalm([1 0 0], A)               % A*A
       norm(polyvalm([1 0 0], A) - A*A) < 1e-12

    Voir aussi POLYVAL, EXPM, EIG, POLY.
```

## `ppval`

```
PPVAL  Évalue une forme polynomiale par morceaux.
    PPVAL(PP,XQ) évalue en XQ la forme rendue par SPLINE.

    Syntaxe
       y = ppval(pp,xq)

    Exemples
       x = 0:4;  y = x.^2;
       pp = spline(x, y);
       abs(ppval(pp, 2.5) - 6.25) < 1e-6

    Voir aussi SPLINE, INTERP1.
```

## `roots`

```
ROOTS  Racines d'un polynôme.
    R = ROOTS(P) rend les racines du polynôme dont les coefficients sont
    P, du degré le plus élevé au terme constant. Elles sont calculées
    comme les valeurs propres de la matrice compagnon.

    Syntaxe
       r = roots(p)

    Exemples
       roots([1 0 -1])                  % [1; -1] — les racines de x^2-1
       roots([1 2 5])                   % -1 ± 2i

    Voir aussi POLY, POLYVAL, EIG, POLYFIT.
```

## `spline`

```
SPLINE  Interpolation par splines cubiques.
    SPLINE(X,Y,XQ) rend les valeurs interpolées en XQ.
    PP = SPLINE(X,Y) rend la forme par morceaux, à évaluer avec PPVAL.

    Syntaxe
       yq = spline(x,y,xq)
       pp = spline(x,y)

    Exemples
       x = 0:0.5:4;  y = sin(x);
       xq = 0:0.05:4;
       yq = spline(x, y, xq);
       max(abs(yq - sin(xq))) < 0.02
       pp = spline(x, y);
       abs(ppval(pp, 1) - spline(x,y,1)) < 1e-12

    Voir aussi INTERP1, PPVAL, POLYFIT.
```

