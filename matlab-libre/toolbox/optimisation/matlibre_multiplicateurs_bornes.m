function multiplicateurs = matlibre_multiplicateurs_bornes(p, bas, haut)
%MATLIBRE_MULTIPLICATEURS_BORNES Bornes actives au point trouvé.
%   M = MATLIBRE_MULTIPLICATEURS_BORNES(P,BAS,HAUT) rend une structure de
%   deux champs, « lower » et « upper », valant un là où la solution
%   touche la borne et zéro ailleurs.
%
%   Un multiplicateur non nul signale que la borne retient la solution :
%   sans elle, le critère continuerait de décroître dans cette direction.
%
%   Exemple :
%      matlibre_multiplicateurs_bornes([0; 5], [0; -inf], []).lower
%
%   Voir aussi LSQCURVEFIT, LSQNONLIN.
    n = numel(p);
    basse = zeros(n, 1);
    haute = zeros(n, 1);
    if ~isempty(bas)
        bas = reshape(bas, [], 1);
        actives = isfinite(bas) & abs(p - bas) <= 1e-10 * max(1, abs(bas));
        basse(actives) = 1;
    end
    if ~isempty(haut)
        haut = reshape(haut, [], 1);
        actives = isfinite(haut) & abs(p - haut) <= 1e-10 * max(1, abs(haut));
        haute(actives) = 1;
    end
    multiplicateurs = struct('lower', basse, 'upper', haute);
end
