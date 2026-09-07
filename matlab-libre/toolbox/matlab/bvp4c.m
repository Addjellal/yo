function sol = bvp4c(odefun, bcfun, solinit, options)
%BVP4C Problème aux limites en deux points, par collocation.
%   SOL = BVP4C(ODEFUN,BCFUN,SOLINIT) résout y' = ODEFUN(x,y) sous les
%   conditions BCFUN(ya,yb) = 0, en partant de la devinette SOLINIT que
%   rend BVPINIT.
%   SOL = BVP4C(...,OPTIONS) accepte 'RelTol' et 'NMax' via BVPSET.
%
%   SOL porte le maillage dans SOL.X et la solution dans SOL.Y, une
%   colonne par point. DEVAL l'évalue entre les points.
%
%   Un problème aux limites ne s'intègre pas : on ne connaît pas tout
%   l'état d'un bout, donc on ne peut pas partir. La méthode discrétise
%   tout l'intervalle à la fois et résout le grand système non linéaire
%   qui en résulte — d'où le nom de collocation.
%
%   La formule employée est celle de Lobatto IIIa à trois points, d'ordre
%   quatre : sur chaque maille on impose que la solution vérifie
%   l'équation aux deux bouts et au milieu, le point milieu étant lui-même
%   déduit d'un développement d'Hermite. C'est la formule de MATLAB, et
%   c'est ce que le « 4c » du nom désigne — ordre quatre, collocation.
%
%   Le système est résolu par la méthode de Newton, dont la jacobienne est
%   calculée par différences finies. Une devinette trop lointaine fait
%   diverger : un problème aux limites peut avoir plusieurs solutions, et
%   c'est la devinette qui choisit.
%
%   Exemple :
%      % y'' + y = 0, y(0) = 0, y(pi/2) = 1 : la solution est sin.
%      f = @(x, y) [y(2); -y(1)];
%      cl = @(ya, yb) [ya(1); yb(1) - 1];
%      sol = bvp4c(f, cl, bvpinit(linspace(0, pi/2, 11), [0 1]));
%      max(abs(sol.y(1, :) - sin(sol.x))) < 1e-6
%
%   Voir aussi BVPINIT, BVPSET, DEVAL, ODE45.
    if nargin < 4, options = struct(); end
    relTol = matlibre_ode_option(options, 'RelTol', 1e-6);
    maxIterations = matlibre_ode_option(options, 'NMax', 50);

    x = double(solinit.x(:))';
    Y = double(solinit.y);
    n = size(Y, 1);
    N = numel(x);

    v = Y(:);
    for iteration = 1:maxIterations
        r = residus(odefun, bcfun, x, v, n, N);
        if norm(r, inf) < relTol * max(1, norm(v, inf))
            break
        end
        J = jacobienne(odefun, bcfun, x, v, n, N);
        pas = -J \ r;
        % Amortissement : un pas de Newton entier peut sortir du bassin
        % de convergence, et le diviser suffit presque toujours a y rester.
        lambda = 1;
        meilleur = norm(r);
        for essai = 1:20
            candidat = v + lambda * pas;
            rCandidat = residus(odefun, bcfun, x, candidat, n, N);
            if norm(rCandidat) < meilleur
                v = candidat;
                break
            end
            lambda = lambda / 2;
            if essai == 20
                v = v + lambda * pas;
            end
        end
    end
    sol = struct('x', x, 'y', reshape(v, n, N), 'solver', 'bvp4c');
end

function r = residus(odefun, bcfun, x, v, n, N)
% Le residu de collocation sur chaque maille, plus les conditions aux
% limites. Le systeme est carre : n*(N-1) equations de maille et n
% conditions, pour n*N inconnues.
    Y = reshape(v, n, N);
    r = zeros(n * N, 1);
    for i = 1:N-1
        h = x(i + 1) - x(i);
        yi = Y(:, i);
        yj = Y(:, i + 1);
        fi = colonne(odefun(x(i), yi), n);
        fj = colonne(odefun(x(i + 1), yj), n);
        % Le point milieu, par developpement d'Hermite : c'est lui qui
        % porte l'ordre quatre.
        ym = (yi + yj) / 2 - h / 8 * (fj - fi);
        fm = colonne(odefun(x(i) + h / 2, ym), n);
        r((i-1)*n + (1:n)) = yj - yi - h / 6 * (fi + 4 * fm + fj);
    end
    cl = bcfun(Y(:, 1), Y(:, end));
    r((N-1)*n + (1:n)) = cl(:);
end

function J = jacobienne(odefun, bcfun, x, v, n, N)
% Par differences finies : le probleme est de taille modeste, et une
% jacobienne analytique demanderait a l'appelant de la fournir.
    m = numel(v);
    J = zeros(m);
    r0 = residus(odefun, bcfun, x, v, n, N);
    for k = 1:m
        pas = sqrt(eps) * max(1, abs(v(k)));
        vk = v;
        vk(k) = vk(k) + pas;
        J(:, k) = (residus(odefun, bcfun, x, vk, n, N) - r0) / pas;
    end
end

function c = colonne(v, n)
    c = reshape(double(v), n, 1);
end
