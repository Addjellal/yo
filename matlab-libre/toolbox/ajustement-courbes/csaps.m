function [sortie, parametre] = csaps(x, y, p, xx, w)
%CSAPS Spline cubique de lissage.
%   PP = CSAPS(X,Y) rend la spline qui réalise le meilleur compromis entre
%   passer près des points et rester peu courbée. Elle minimise
%
%      p * somme(w_i * (y_i - f(x_i))^2) + (1-p) * integrale de f''^2
%
%   PP = CSAPS(X,Y,P) impose le paramètre de lissage, entre zéro et un.
%   À un, la spline interpole exactement ; à zéro, elle se réduit à la
%   droite des moindres carrés. Entre les deux, elle suit les données
%   d'autant plus fidèlement que P est proche de un.
%
%   VALEURS = CSAPS(X,Y,P,XX) évalue directement la spline en XX.
%   CSAPS(X,Y,P,XX,W) pondère les points.
%
%   [PP,P] = CSAPS(...) rend aussi le paramètre employé, ce qui est utile
%   quand on l'a laissé choisir.
%
%   Sans P, il est pris tel que le terme de fidélité et le terme de
%   courbure pèsent également au vu de l'espacement des données.
%
%   Exemple :
%      x = linspace(0, 2*pi, 40)';
%      y = sin(x) + 0.1 * randn(size(x));
%      pp = csaps(x, y, 0.99);
%      max(abs(ppval(pp, x) - sin(x))) < 0.2
%
%   Voir aussi SPAPS, SPLINE, CSAPE, FIT, PPVAL.
    x = double(x(:));
    y = double(y(:));
    n = numel(x);
    if n ~= numel(y)
        error('curvefit:csaps:Tailles', 'X et Y doivent avoir le même nombre d''éléments.');
    end
    [x, ordre] = sort(x);
    y = y(ordre);
    if nargin < 5 || isempty(w)
        w = ones(n, 1);
    else
        w = double(w(:));
        w = w(ordre);
    end
    if n < 3
        sortie = spline(x, y);
        parametre = 1;
        if nargin >= 4 && ~isempty(xx)
            sortie = ppval(sortie, xx);
        end
        return
    end
    h = diff(x);
    if nargin < 3 || isempty(p)
        % Le lambda par défaut est le cube de l'espacement moyen divisé
        % par six : c'est l'échelle à laquelle les deux termes du critère
        % se valent.
        lambda = mean(h) ^ 3 / 6;
        p = 1 / (1 + lambda);
    else
        p = double(p);
        if p >= 1
            lambda = 0;
        elseif p <= 0
            lambda = Inf;
        else
            lambda = (1 - p) / p;
        end
    end
    parametre = p;
    [Q, R] = matlibre_operateurs_spline(h);
    if isinf(lambda)
        % Courbure nulle : la spline se réduit à la droite des moindres
        % carrés pondérés.
        droite = ([x, ones(n, 1)] .* sqrt(w)) \ (y .* sqrt(w));
        a = droite(1) * x + droite(2);
        m = zeros(n, 1);
    else
        inverseW = spdiags(1 ./ w, 0, n, n);
        u = (R + lambda * (Q.' * inverseW * Q)) \ (Q.' * y);
        a = y - lambda * (inverseW * (Q * u));
        m = [0; full(u); 0];
    end
    pp = matlibre_pp_depuis_valeurs(x, a, m);
    if nargin >= 4 && ~isempty(xx)
        sortie = ppval(pp, xx);
    else
        sortie = pp;
    end
end
