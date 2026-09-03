function [energieApproximation, energiesHorizontales, energiesVerticales, energiesDiagonales] = wenergy2(C, S)
%WENERGY2 Répartition de l'énergie d'une image décomposée.
%   [EA,EH,EV,ED] = WENERGY2(C,S) rend le pourcentage d'énergie porté par
%   l'approximation, puis, du niveau un au niveau le plus grossier, celui
%   des détails horizontaux, verticaux et diagonaux.
%
%   [EA,ED] = WENERGY2(C,S) range les trois familles de détails dans une
%   matrice à trois colonnes, un niveau par ligne, comme MATLAB.
%
%   L'énergie se conserve pour une ondelette orthogonale : les
%   pourcentages somment alors exactement à cent. Pour une biorthogonale
%   ils somment à peu près, le banc n'étant pas orthogonal.
%
%   Exemple :
%      [c, s] = wavedec2(magic(16), 2, 'haar');
%      [ea, ed] = wenergy2(c, s);
%      ea + sum(ed(:))                % 100
%
%   Voir aussi WENERGY, WAVEDEC2, DETCOEF2, APPCOEF2.
    total = sum(C .^ 2);
    if total == 0
        total = 1;
    end
    niveaux = size(S, 1) - 2;
    energieApproximation = 100 * sum(C(1:prod(S(1, :))) .^ 2) / total;
    parNiveau = zeros(niveaux, 3);
    position = prod(S(1, :));
    % Le vecteur va du niveau le plus grossier au plus fin ; la sortie va
    % dans l'autre sens, comme celle de DETCOEF2.
    for k = 1:niveaux
        n = prod(S(k + 1, :));
        for famille = 1:3
            bloc = C(position + (1:n));
            parNiveau(niveaux - k + 1, famille) = 100 * sum(bloc .^ 2) / total;
            position = position + n;
        end
    end
    if nargout <= 2
        energiesHorizontales = parNiveau;
    else
        energiesHorizontales = parNiveau(:, 1).';
        energiesVerticales = parNiveau(:, 2).';
        energiesDiagonales = parNiveau(:, 3).';
    end
end
