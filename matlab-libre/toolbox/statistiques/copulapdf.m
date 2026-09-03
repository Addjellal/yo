function y = copulapdf(famille, u, parametre, nu)
%COPULAPDF Densité d'une copule.
%   Y = COPULAPDF('Gaussian',U,RHO) rend la densité de la copule
%   gaussienne ; 'Clayton', 'Frank' et 'Gumbel' sont traitées pour deux
%   variables.
%
%   Exemple :
%      copulapdf('Gaussian', [0.5 0.5], 0.7)
%
%   Voir aussi COPULACDF, COPULARND, MVNPDF.
    famille = lower(char(famille));
    u = double(u);
    if size(u, 2) == 1
        u = u(:).';
    end
    u = min(max(u, eps), 1 - eps);
    d = size(u, 2);
    switch famille
        case 'gaussian'
            R = eye(d) * (1 - parametre) + parametre;
            if ~isscalar(parametre)
                R = double(parametre);
            end
            z = norminv(u);
            y = mvnpdf(z, zeros(1, d), R) ./ prod(normpdf(z), 2);
        case 't'
            R = eye(d) * (1 - parametre) + parametre;
            if ~isscalar(parametre)
                R = double(parametre);
            end
            t = tinv(u, nu);
            % Densité multivariée de Student, divisée par les marges.
            quadratique = sum((t / R) .* t, 2);
            constante = gamma((nu + d) / 2) / ...
                (gamma(nu / 2) * (nu * pi) ^ (d / 2) * sqrt(det(R)));
            densite = constante * (1 + quadratique / nu) .^ (-(nu + d) / 2);
            y = densite ./ prod(tpdf(t, nu), 2);
        case 'clayton'
            exigerDeux(d);
            a = parametre;
            y = (1 + a) * (u(:, 1) .* u(:, 2)) .^ (-1 - a) .* ...
                (u(:, 1) .^ (-a) + u(:, 2) .^ (-a) - 1) .^ (-2 - 1 / a);
        case 'frank'
            exigerDeux(d);
            a = parametre;
            numerateur = a * expm1(-a) * exp(-a * (u(:, 1) + u(:, 2)));
            denominateur = (expm1(-a) + expm1(-a * u(:, 1)) .* expm1(-a * u(:, 2))) .^ 2;
            y = numerateur ./ denominateur;
        case 'gumbel'
            exigerDeux(d);
            a = parametre;
            lu = -log(u(:, 1));
            lv = -log(u(:, 2));
            somme = lu .^ a + lv .^ a;
            c = exp(-somme .^ (1 / a));
            y = c .* (lu .* lv) .^ (a - 1) ./ (u(:, 1) .* u(:, 2)) .* ...
                somme .^ (1 / a - 2) .* (somme .^ (1 / a) + a - 1);
        otherwise
            error('stats:copulapdf:Famille', 'Famille inconnue : %s.', famille);
    end
end

function exigerDeux(d)
    if d ~= 2
        error('stats:copulapdf:Dimension', ...
              'Les copules archimédiennes ne sont traitées qu''à deux variables.');
    end
end
