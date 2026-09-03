function p = copulacdf(famille, u, parametre, nu)
%COPULACDF Fonction de répartition d'une copule.
%   P = COPULACDF('Gaussian',U,RHO) rend la répartition de la copule
%   gaussienne de corrélation RHO aux points U, dont chaque colonne est
%   une marge dans [0,1].
%   P = COPULACDF('t',U,RHO,NU) fait de même pour la copule de Student.
%   P = COPULACDF(FAMILLE,U,ALPHA) traite les copules archimédiennes
%   'Clayton', 'Frank' et 'Gumbel'.
%
%   Une copule décrit la dépendance entre variables indépendamment de
%   leurs lois marginales : c'est ce qui permet de coller n'importe
%   quelles marges sur une structure de dépendance donnée.
%
%   Exemple :
%      copulacdf('Clayton', [0.5 0.5], 2)
%      copulacdf('Gaussian', [0.5 0.5], 0.7)
%
%   Voir aussi COPULAPDF, COPULARND, MVNCDF, CORR.
    famille = lower(char(famille));
    u = double(u);
    if size(u, 2) == 1
        u = u(:).';
    end
    u = min(max(u, eps), 1 - eps);
    switch famille
        case 'gaussian'
            R = matriceCorrelation(parametre, size(u, 2));
            p = mvncdf(norminv(u), zeros(1, size(u, 2)), R);
        case 't'
            if nargin < 4
                error('stats:copulacdf:Nu', 'La copule de Student demande NU.');
            end
            R = matriceCorrelation(parametre, size(u, 2));
            p = copuleTCdf(u, R, nu);
        case 'clayton'
            alpha = parametre;
            if alpha == 0
                p = prod(u, 2);
            else
                somme = sum(u .^ (-alpha), 2) - (size(u, 2) - 1);
                p = max(somme, 0) .^ (-1 / alpha);
            end
        case 'frank'
            alpha = parametre;
            if alpha == 0
                p = prod(u, 2);
            else
                produit = prod(expm1(-alpha * u), 2);
                p = -log(1 + produit / expm1(-alpha) ^ (size(u, 2) - 1)) / alpha;
            end
        case 'gumbel'
            alpha = parametre;
            somme = sum((-log(u)) .^ alpha, 2);
            p = exp(-somme .^ (1 / alpha));
        otherwise
            error('stats:copulacdf:Famille', 'Famille inconnue : %s.', famille);
    end
    p = min(max(p, 0), 1);
end

function R = matriceCorrelation(parametre, d)
    if isscalar(parametre)
        R = eye(d) * (1 - parametre) + parametre;
    else
        R = double(parametre);
    end
end

function p = copuleTCdf(u, R, nu)
% La copule de Student n'a pas de forme close : on l'intègre par
% simulation, ce qui suffit pour la précision qu'on en attend.
    d = size(u, 2);
    n = 20000;
    L = chol(R + 1e-12 * eye(d), 'lower');
    z = (L * randn(d, n)).';
    w = sqrt(nu ./ chi2rnd(nu, n, 1));
    t = z .* repmat(w, 1, d);
    seuils = tinv(u, nu);
    p = zeros(size(u, 1), 1);
    for k = 1:size(u, 1)
        dedans = true(n, 1);
        for j = 1:d
            dedans = dedans & (t(:, j) <= seuils(k, j));
        end
        p(k) = mean(dedans);
    end
end
