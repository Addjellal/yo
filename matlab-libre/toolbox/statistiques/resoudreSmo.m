function [alpha, biais] = resoudreSmo(K, cible, C, tolerance, maxIter)
%RESOUDRESMO Optimisation minimale séquentielle du dual d'une SVM.
%   Deux multiplicateurs bougent à la fois, ce qui garde la contrainte
%   somme(alpha_i y_i) = 0 sans passer par un solveur général. C'est
%   l'algorithme de Platt, dans sa version simplifiée : le second
%   multiplicateur est tiré au hasard parmi les autres.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = numel(cible);
    alpha = zeros(n, 1);
    biais = 0;
    passages = 0;
    maxPassages = 5;
    iteration = 0;
    while passages < maxPassages && iteration < maxIter
        changements = 0;
        for i = 1:n
            Ei = sortieSmo(K, alpha, cible, biais, i) - cible(i);
            if (cible(i) * Ei < -tolerance && alpha(i) < C) || ...
               (cible(i) * Ei > tolerance && alpha(i) > 0)
                j = i;
                while j == i
                    j = randi(n);
                end
                Ej = sortieSmo(K, alpha, cible, biais, j) - cible(j);
                ancienI = alpha(i);
                ancienJ = alpha(j);
                if cible(i) ~= cible(j)
                    bas = max(0, alpha(j) - alpha(i));
                    haut = min(C, C + alpha(j) - alpha(i));
                else
                    bas = max(0, alpha(i) + alpha(j) - C);
                    haut = min(C, alpha(i) + alpha(j));
                end
                if bas >= haut
                    continue;
                end
                eta = 2 * K(i, j) - K(i, i) - K(j, j);
                if eta >= 0
                    continue;
                end
                alpha(j) = alpha(j) - cible(j) * (Ei - Ej) / eta;
                alpha(j) = min(max(alpha(j), bas), haut);
                if abs(alpha(j) - ancienJ) < 1e-12
                    continue;
                end
                alpha(i) = alpha(i) + cible(i) * cible(j) * (ancienJ - alpha(j));
                b1 = biais - Ei - cible(i) * (alpha(i) - ancienI) * K(i, i) ...
                     - cible(j) * (alpha(j) - ancienJ) * K(i, j);
                b2 = biais - Ej - cible(i) * (alpha(i) - ancienI) * K(i, j) ...
                     - cible(j) * (alpha(j) - ancienJ) * K(j, j);
                if alpha(i) > 0 && alpha(i) < C
                    biais = b1;
                elseif alpha(j) > 0 && alpha(j) < C
                    biais = b2;
                else
                    biais = (b1 + b2) / 2;
                end
                changements = changements + 1;
            end
        end
        iteration = iteration + 1;
        if changements == 0
            passages = passages + 1;
        else
            passages = 0;
        end
    end
end

function s = sortieSmo(K, alpha, cible, biais, i)
    s = sum(alpha .* cible .* K(:, i)) + biais;
end
