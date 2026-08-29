# Optimisation et equations differentielles

Fonctions natives du groupe `optimisation`.

## `deval`

```
DEVAL  Évalue la solution d'une équation différentielle entre les pas.
    DEVAL(SOL,T) interpole la solution rendue par un solveur appelé avec
    une seule sortie.

    Syntaxe
       y = deval(sol,t)

    Exemples
       sol = ode45(@(t,y) -y, [0 2], 1);
       y = deval(sol, 1);
       abs(y - exp(-1)) < 1e-4

    Voir aussi ODE45, ODE15S, INTERP1.
```

## `fminbnd`

```
FMINBND  Minimum d'une fonction sur un intervalle.
    FMINBND(F,A,B) cherche le minimum de F entre A et B.
    [X,FVAL] = FMINBND(...) rend aussi la valeur atteinte.

    Syntaxe
       x = fminbnd(f,a,b)
       [x,fval] = fminbnd(f,a,b)

    Exemples
       abs(fminbnd(@(x) (x-3).^2, 0, 10) - 3) < 1e-4
       [x, f] = fminbnd(@cos, 0, 2*pi);
       abs(x - pi) < 1e-4

    Voir aussi FMINSEARCH, FMINUNC, FZERO, OPTIMSET.
```

## `fminsearch`

```
FMINSEARCH  Minimum sans dérivées, par simplexe de Nelder-Mead.
    FMINSEARCH(F,X0) minimise F à partir de X0, X0 pouvant être un
    vecteur : c'est la méthode à prendre quand on n'a pas le gradient.

    Syntaxe
       x = fminsearch(f,x0)
       [x,fval] = fminsearch(f,x0)

    Exemples
       x = fminsearch(@(v) (v(1)-1)^2 + (v(2)-2)^2, [0 0]);
       norm(x - [1 2]) < 1e-3
       rosenbrock = @(v) (1-v(1))^2 + 100*(v(2)-v(1)^2)^2;
       xr = fminsearch(rosenbrock, [-1.2 1]);

    Voir aussi FMINBND, FMINUNC, FSOLVE, OPTIMSET.
```

## `fminunc`

```
FMINUNC  Minimum sans contrainte, avec dérivées estimées.
    FMINUNC(F,X0) minimise F à partir de X0 par une méthode de descente.

    Syntaxe
       x = fminunc(f,x0)
       [x,fval] = fminunc(f,x0)

    Exemples
       x = fminunc(@(v) (v(1)-2)^2 + (v(2)+1)^2, [0 0]);
       norm(x - [2 -1]) < 1e-3

    Voir aussi FMINSEARCH, FMINBND, FSOLVE, OPTIMSET.
```

## `fsolve`

```
FSOLVE  Résout un système d'équations non linéaires.
    FSOLVE(F,X0) cherche X tel que F(X) = 0, à partir de X0.

    Syntaxe
       x = fsolve(f,x0)
       [x,fval] = fsolve(f,x0)

    Exemples
       f = @(v) [v(1)^2 + v(2)^2 - 1; v(1) - v(2)];
       x = fsolve(f, [1 0]);
       norm(f(x)) < 1e-6

    Voir aussi FZERO, FMINSEARCH, MLDIVIDE, LSQNONNEG.
```

## `fzero`

```
FZERO  Racine d'une fonction d'une variable.
    FZERO(F,X0) cherche une racine près de X0.
    FZERO(F,[A B]) cherche entre A et B, où F doit changer de signe.

    Syntaxe
       x = fzero(f,x0)
       x = fzero(f,[a b])

    Exemples
       fzero(@cos, 1)                         % pi/2
       fzero(@(x) x^2 - 2, [0 2])             % sqrt(2)
       abs(fzero(@(x) x^3 - x - 2, 1.5) - 1.5214) < 1e-3

    Voir aussi FSOLVE, FMINBND, ROOTS, FMINSEARCH.
```

## `integral`

```
INTEGRAL  Intégrale définie d'une fonction.
    INTEGRAL(F,A,B) intègre F de A à B, F étant une poignée vectorisée.

    Syntaxe
       q = integral(f,a,b)

    Exemples
       integral(@(x) sin(x), 0, pi)           % 2
       abs(integral(@(x) exp(-x.^2), -5, 5) - sqrt(pi)) < 1e-6

    Voir aussi TRAPZ, QUAD, QUADGK, INTEGRAL2, ODE45.
```

## `integral2`

```
INTEGRAL2  Intégrale double.
    INTEGRAL2(F,A,B,C,D) intègre F(x,y) sur le rectangle [A,B]x[C,D].

    Syntaxe
       q = integral2(f,a,b,c,d)

    Exemples
       abs(integral2(@(x,y) ones(size(x)), 0, 2, 0, 3) - 6) < 1e-8
       abs(integral2(@(x,y) x.*y, 0, 1, 0, 1) - 0.25) < 1e-8

    Voir aussi INTEGRAL, TRAPZ, QUAD2D.
```

## `lsqnonneg`

```
LSQNONNEG  Moindres carrés à solution positive.
    LSQNONNEG(C,D) minimise ||C*x - d|| sous la contrainte x >= 0.

    Syntaxe
       x = lsqnonneg(C,d)

    Exemples
       C = [1 0; 0 1; 1 1];
       d = [1; -1; 1];
       x = lsqnonneg(C, d);
       all(x >= 0)

    Voir aussi MLDIVIDE, PINV, FMINSEARCH, FSOLVE.
```

## `ode113`

```
ODE113  Résout une équation différentielle, méthode à pas multiples.
    Utile quand la fonction est coûteuse à évaluer et la solution lisse.

    Syntaxe
       [t,y] = ode113(f,[t0 tf],y0)

    Exemples
       [t, y] = ode113(@(t,y) -y, [0 2], 1);
       abs(y(end) - exp(-2)) < 1e-3

    Voir aussi ODE45, ODE23, ODE15S.
```

## `ode15s`

```
ODE15S  Résout une équation différentielle raide.
    [T,Y] = ODE15S(F,[T0 TF],Y0) convient quand les échelles de temps sont
    très différentes — là où ODE45 avance à pas minuscules.

    Syntaxe
       [t,y] = ode15s(f,[t0 tf],y0)

    Exemples
       [t, y] = ode15s(@(t,y) -1000*(y - cos(t)), [0 1], 0);
       numel(t) > 1

    Voir aussi ODE45, ODE23S, ODESET.
```

## `ode23`

```
ODE23  Résout une équation différentielle, Runge-Kutta 2(3).
    Moins précis qu'ODE45 mais moins coûteux par pas : utile quand la
    tolérance demandée est lâche.

    Syntaxe
       [t,y] = ode23(f,[t0 tf],y0)

    Exemples
       [t, y] = ode23(@(t,y) -y, [0 2], 1);
       abs(y(end) - exp(-2)) < 1e-2

    Voir aussi ODE45, ODE113, ODE15S, ODESET.
```

## `ode23s`

```
ode23s  Solveur raide, Rosenbrock modifie (2,3).
```

## `ode23t`

```
ode23t  Solveur peu raide, regle des trapezes.
```

## `ode23tb`

```
ode23tb  Solveur raide, trapeze puis BDF2.
```

## `ode45`

```
ODE45  Résout une équation différentielle, méthode de Runge-Kutta 4(5).
    [T,Y] = ODE45(F,[T0 TF],Y0) intègre y' = f(t,y) de T0 à TF depuis Y0.
    C'est le solveur à essayer en premier ; ODE15S est pour les problèmes
    raides.

    Syntaxe
       [t,y] = ode45(f,[t0 tf],y0)
       [t,y] = ode45(f,tspan,y0,options)

    Exemples
       [t, y] = ode45(@(t,y) -2*y, [0 3], 1);
       abs(y(end) - exp(-6)) < 1e-4

       % Un oscillateur : y'' + y = 0, écrit en système d'ordre 1.
       [t, y] = ode45(@(t,v) [v(2); -v(1)], [0 2*pi], [1; 0]);
       abs(y(end,1) - 1) < 1e-3

    Voir aussi ODE23, ODE15S, ODESET, DEVAL, INTEGRAL.
```

## `odeget`

```
ODEGET  Lit une option de solveur différentiel.

    Syntaxe
       v = odeget(options,'Nom')
       v = odeget(options,'Nom',defaut)

    Exemples
       options = odeset('RelTol', 1e-7);
       odeget(options, 'RelTol')
       odeget(options, 'AbsTol', 1e-6)

    Voir aussi ODESET, ODE45, OPTIMGET.
```

## `odeset`

```
ODESET  Options des solveurs d'équations différentielles.
    ODESET('Nom',valeur,...) construit la structure d'options :
    'RelTol', 'AbsTol', 'MaxStep'.

    Syntaxe
       options = odeset('Nom',valeur,...)

    Exemples
       options = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
       [t, y] = ode45(@(t,y) -y, [0 1], 1, options);
       abs(y(end) - exp(-1)) < 1e-7

    Voir aussi ODEGET, ODE45, ODE15S, OPTIMSET.
```

## `optimget`

```
OPTIMGET  Lit une option d'optimisation.
    OPTIMGET(OPTIONS,'Nom',DEFAUT) rend la valeur, ou le défaut si elle
    n'est pas posée.

    Syntaxe
       v = optimget(options,'Nom')
       v = optimget(options,'Nom',defaut)

    Exemples
       options = optimset('TolX', 1e-8);
       optimget(options, 'TolX')
       optimget(options, 'MaxIter', 400)

    Voir aussi OPTIMSET, ODEGET.
```

## `optimset`

```
OPTIMSET  Options des solveurs d'optimisation.
    OPTIMSET('Nom',valeur,...) construit la structure : 'TolX', 'TolFun',
    'MaxIter', 'Display'.

    Syntaxe
       options = optimset('Nom',valeur,...)

    Exemples
       options = optimset('TolX', 1e-10);
       x = fminbnd(@(x) (x-3)^2, 0, 10, options);
       abs(x - 3) < 1e-6

    Voir aussi OPTIMGET, FMINBND, FMINSEARCH, ODESET.
```

## `quad`

```
quad  Quadrature de Simpson adaptative.
```

## `quadgk`

```
QUADGK  Intégrale par quadrature de Gauss-Kronrod.
    QUADGK(F,A,B) convient aux intégrandes difficiles et aux bornes
    infinies.

    Syntaxe
       q = quadgk(f,a,b)

    Exemples
       abs(quadgk(@(x) exp(-x.^2), -Inf, Inf) - sqrt(pi)) < 1e-6
       abs(quadgk(@sin, 0, pi) - 2) < 1e-8

    Voir aussi INTEGRAL, QUAD, TRAPZ.
```

