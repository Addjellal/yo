function u = copularnd(famille, parametre, varargin)
%COPULARND Tirages d'une copule.
%   U = COPULARND('Gaussian',RHO,N) tire N points de la copule
%   gaussienne ; chaque colonne est uniforme sur [0,1], et la dépendance
%   entre colonnes est celle de la copule.
%   U = COPULARND('t',RHO,NU,N) tire de la copule de Student.
%   U = COPULARND(FAMILLE,ALPHA,N) traite 'Clayton', 'Frank' et
%   'Gumbel' à deux variables.
%
%   Exemple :
%      u = copularnd('Gaussian', 0.8, 1000);
%      corr(u(:, 1), u(:, 2))      % proche de 0,8
%
%   Voir aussi COPULACDF, COPULAPDF, MVNRND.
    famille = lower(char(famille));
    switch famille
        case 'gaussian'
            n = varargin{1};
            R = parametre;
            if isscalar(R)
                R = [1 R; R 1];
            end
            d = size(R, 1);
            z = mvnrnd(zeros(1, d), R, n);
            u = normcdf(z);
        case 't'
            nu = varargin{1};
            n = varargin{2};
            R = parametre;
            if isscalar(R)
                R = [1 R; R 1];
            end
            d = size(R, 1);
            z = mvnrnd(zeros(1, d), R, n);
            w = sqrt(nu ./ chi2rnd(nu, n, 1));
            u = tcdf(z .* repmat(w, 1, d), nu);
        case {'clayton', 'frank', 'gumbel'}
            n = varargin{1};
            u = archimedienne(famille, parametre, n);
        otherwise
            error('stats:copularnd:Famille', 'Famille inconnue : %s.', famille);
    end
end

function u = archimedienne(famille, alpha, n)
% Méthode conditionnelle : on tire la première marge uniformément, puis
% la seconde suivant sa loi conditionnelle, obtenue en inversant la
% dérivée de la copule.
    u1 = rand(n, 1);
    w = rand(n, 1);
    switch famille
        case 'clayton'
            if alpha == 0
                u2 = w;
            else
                u2 = (1 + u1 .^ (-alpha) .* (w .^ (-alpha / (1 + alpha)) - 1)) .^ (-1 / alpha);
            end
        case 'frank'
            if alpha == 0
                u2 = w;
            else
                u2 = -log(1 + w .* expm1(-alpha) ./ ...
                          (exp(-alpha * u1) - w .* expm1(-alpha * u1))) / alpha;
            end
        case 'gumbel'
            % Pas de forme close : on inverse la conditionnelle par
            % dichotomie, ce qui reste rapide et sûr.
            u2 = zeros(n, 1);
            for k = 1:n
                u2(k) = inverserConditionnelle(u1(k), w(k), alpha);
            end
    end
    u = [u1, min(max(u2, eps), 1 - eps)];
end

function v = inverserConditionnelle(u, cible, alpha)
    bas = eps;
    haut = 1 - eps;
    for iteration = 1:80
        milieu = (bas + haut) / 2;
        if conditionnelleGumbel(u, milieu, alpha) < cible
            bas = milieu;
        else
            haut = milieu;
        end
    end
    v = (bas + haut) / 2;
end

function c = conditionnelleGumbel(u, v, alpha)
    lu = -log(u);
    lv = -log(v);
    somme = lu ^ alpha + lv ^ alpha;
    c = exp(-somme ^ (1 / alpha)) * somme ^ (1 / alpha - 1) * lu ^ (alpha - 1) / u;
end
