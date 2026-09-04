function H = matlibre_hessienne(fonction, point)
%MATLIBRE_HESSIENNE Hessienne par différences finies centrées.
%   Le pas suit l'échelle de chaque coordonnée : la racine cubique de
%   l'epsilon machine équilibre l'erreur de troncature et l'erreur
%   d'arrondi.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    point = point(:);
    n = numel(point);
    pas = max(abs(point), 1e-2) * eps ^ (1 / 4);
    H = zeros(n, n);
    centre = fonction(point);
    for i = 1:n
        for j = i:n
            ei = zeros(n, 1); ei(i) = pas(i);
            ej = zeros(n, 1); ej(j) = pas(j);
            if i == j
                valeur = (fonction(point + ei) - 2 * centre + fonction(point - ei)) ...
                         / (pas(i) ^ 2);
            else
                valeur = (fonction(point + ei + ej) - fonction(point + ei - ej) ...
                        - fonction(point - ei + ej) + fonction(point - ei - ej)) ...
                         / (4 * pas(i) * pas(j));
            end
            H(i, j) = valeur;
            H(j, i) = valeur;
        end
    end
end
