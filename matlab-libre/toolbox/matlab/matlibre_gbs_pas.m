function [y, erreur] = matlibre_gbs_pas(f, t, y0, h)
%MATLIBRE_GBS_PAS Un pas de Gragg-Bulirsch-Stoer.
%   On traverse le pas H avec 2, 4, 6, 8 puis 10 sous-pas par la règle du
%   point milieu modifiée, et l'on extrapole les cinq résultats vers un
%   sous-pas nul par le tableau d'Aitken-Neville.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   L'erreur de la règle du point milieu modifiée est une série en
%   puissances paires du sous-pas. C'est ce qui rend l'extrapolation
%   efficace : chaque colonne du tableau supprime le terme suivant de la
%   série, et l'ordre monte de deux à chaque fois au lieu d'un.
%
%   L'écart entre les deux dernières colonnes estime l'erreur : c'est le
%   procédé habituel, celui qui évite de calculer une seconde solution.
%
%   Exemple :
%      [y, e] = matlibre_gbs_pas(@(t, v) -v, 0, 1, 0.1);
%      abs(y - exp(-0.1)) < 1e-12
%
%   Voir aussi ODE89, ODE113, ODE45.
    niveaux = 5;
    sousPas = 2:2:2*niveaux;
    n = numel(y0);
    tableau = zeros(n, niveaux);
    for k = 1:niveaux
        tableau(:, k) = pointMilieuModifie(f, t, y0, h, sousPas(k));
    end
    % Aitken-Neville sur les carres des sous-pas : l'erreur etant paire,
    % c'est h^2 qui est la variable d'extrapolation.
    carres = (h ./ sousPas) .^ 2;
    for colonne = 2:niveaux
        for ligne = niveaux:-1:colonne
            facteur = carres(ligne - colonne + 1) / carres(ligne);
            tableau(:, ligne) = tableau(:, ligne) + ...
                (tableau(:, ligne) - tableau(:, ligne - 1)) / (facteur - 1);
        end
    end
    y = tableau(:, niveaux);
    erreur = abs(tableau(:, niveaux) - tableau(:, niveaux - 1));
end

function y = pointMilieuModifie(f, t, y0, H, n)
% La regle du point milieu modifiee de Gragg : un demi-pas d'Euler, des
% pas centres, et une moyenne finale qui annule le terme d'erreur impair.
    h = H / n;
    yPrecedent = y0;
    yCourant = y0 + h * f(t, y0);
    for k = 1:n-1
        yNeuf = yPrecedent + 2 * h * f(t + k * h, yCourant);
        yPrecedent = yCourant;
        yCourant = yNeuf;
    end
    y = 0.5 * (yCourant + yPrecedent + h * f(t + H, yCourant));
end
