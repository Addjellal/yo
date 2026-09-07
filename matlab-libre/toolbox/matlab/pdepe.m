function sol = pdepe(m, pdefun, icfun, bcfun, xmesh, tspan, options)
%PDEPE Équation aux dérivées partielles parabolique ou elliptique en 1-D.
%   SOL = PDEPE(M,PDEFUN,ICFUN,BCFUN,XMESH,TSPAN) résout
%
%      c(x,t,u,du/dx) du/dt = x^-m d/dx ( x^m f(x,t,u,du/dx) ) + s(...)
%
%   où M vaut 0 en géométrie plane, 1 en cylindrique et 2 en sphérique.
%   PDEFUN rend [C,F,S] ; ICFUN rend la condition initiale en un point ;
%   BCFUN rend [PL,QL,PR,QR] pour les conditions P + Q*F = 0 aux deux
%   bouts. SOL est un tableau TSPAN par XMESH par composante.
%
%   La méthode est celle des lignes : on discrétise l'espace, ce qui
%   change l'équation aux dérivées partielles en un système d'équations
%   différentielles ordinaires en temps, puis on l'intègre par ODE15S. Le
%   système est raide — la raideur croît comme le carré du nombre de
%   points — et c'est pour cela qu'un solveur explicite n'y suffit pas.
%
%   La discrétisation en espace est en volumes finis : le flux F est
%   évalué aux milieux de mailles, et la divergence prise entre eux. Cette
%   écriture conserve exactement la quantité intégrée, ce qu'une
%   différence finie centrée ne fait pas — et c'est ce qui compte pour une
%   équation de conservation.
%
%   Le terme x^m traite la symétrie : en cylindrique et en sphérique,
%   l'aire de la surface traversée croît avec le rayon, et c'est ce
%   facteur qui l'exprime.
%
%   Une condition de Dirichlet — Q nul — n'est pas une équation
%   différentielle : la valeur au bord est déterminée à chaque instant en
%   résolvant P = 0, non intégrée.
%
%   Exemple :
%      % Equation de la chaleur sur [0,1], bords a zero, creneau initial.
%      f = @(x, t, u, dudx) deal(1, dudx, 0);
%      ic = @(x) sin(pi * x);
%      bc = @(xl, ul, xr, ur, t) deal(ul, 0, ur, 0);
%      x = linspace(0, 1, 21);
%      t = linspace(0, 0.1, 6);
%      sol = pdepe(0, f, ic, bc, x, t);
%      % La solution exacte est sin(pi x) exp(-pi^2 t).
%      max(abs(sol(end, :)' - sin(pi * x)' * exp(-pi^2 * 0.1))) < 5e-3
%
%   Voir aussi ODE15S, BVP4C, PDEVAL, INTERP1.
    if nargin < 7, options = struct(); end
    x = double(xmesh(:))';
    t = double(tspan(:))';
    N = numel(x);
    % M ne prend que trois valeurs : elles nomment les trois geometries a
    % symetrie, et il n'y en a pas d'autre en dimension un.
    if ~isscalar(m) || ~any(m == [0 1 2])
        error('MATLAB:pdepe:InvalidM', 'M doit valoir 0, 1 ou 2.');
    end
    if N < 3
        error('MATLAB:pdepe:InvalidXMesh', 'XMESH doit compter au moins trois points.');
    end
    if numel(t) < 3
        error('MATLAB:pdepe:InvalidTSpan', 'TSPAN doit compter au moins trois instants.');
    end
    if any(diff(x) <= 0)
        error('MATLAB:pdepe:InvalidXMesh', 'XMESH doit etre strictement croissant.');
    end
    % En cylindrique et en spherique, x est un rayon : il ne peut pas etre
    % negatif, et le facteur x^m n'aurait pas de sens s'il l'etait.
    if m > 0 && x(1) < 0
        error('MATLAB:pdepe:InvalidXMesh', ...
              'XMESH(1) doit etre positif ou nul quand M vaut 1 ou 2.');
    end
    u0 = double(icfun(x(1)));
    nu = numel(u0);

    U0 = zeros(nu, N);
    for k = 1:N
        v = icfun(x(k));
        U0(:, k) = v(:);
    end

    % Quels bords sont de Dirichlet : Q nul veut dire que la valeur est
    % imposee, non que le flux l'est.
    [~, ql0, ~, qr0] = bcfun(x(1), U0(:, 1), x(end), U0(:, end), t(1));
    dirichletGauche = double(ql0(:)) == 0;
    dirichletDroite = double(qr0(:)) == 0;

    v0 = U0(:);
    derivee = @(tt, vv) matlibre_pdepe_derivee(tt, vv, m, pdefun, bcfun, x, nu, ...
                                               dirichletGauche, dirichletDroite);
    relTol = matlibre_ode_option(options, 'RelTol', 1e-6);
    absTol = matlibre_ode_option(options, 'AbsTol', 1e-8);
    % Le stencil ne touche que le noeud et ses deux voisins : la
    % jacobienne est tridiagonale par blocs. Le dire au solveur lui permet
    % de la construire en trois evaluations au lieu d'une par inconnue --
    % le cout passe de N^2 a N, et c'est ce qui rend la methode des lignes
    % praticable sur un maillage fin.
    motif = zeros(nu * N);
    for i = 1:N
        for jj = max(1, i - 1):min(N, i + 1)
            motif((i-1)*nu + (1:nu), (jj-1)*nu + (1:nu)) = 1;
        end
    end
    [~, V] = ode15s(derivee, t, v0, ...
                    odeset('RelTol', relTol, 'AbsTol', absTol, 'JPattern', motif));

    sol = zeros(numel(t), N, nu);
    for k = 1:size(V, 1)
        U = reshape(V(k, :), nu, N);
        for j = 1:nu
            sol(k, :, j) = U(j, :);
        end
    end
    if nu == 1
        sol = reshape(sol, numel(t), N);
    end
end
