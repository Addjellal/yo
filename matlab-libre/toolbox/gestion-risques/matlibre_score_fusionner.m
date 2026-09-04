function bornes = matlibre_score_fusionner(colonne, bornes, minimum)
%MATLIBRE_SCORE_FUSIONNER Supprime les bornes qui font des tranches trop rares.
%   Une tranche de trois dossiers ne dit rien : son poids de la preuve
%   serait déterminé par le hasard. On la fond dans sa voisine.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    change = true;
    while change && ~isempty(bornes)
        change = false;
        rangs = matlibre_score_rang(colonne, bornes);
        comptes = zeros(1, numel(bornes) + 1);
        for k = 1:numel(comptes)
            comptes(k) = sum(rangs == k);
        end
        [plusPetit, rang] = min(comptes);
        if plusPetit < minimum
            aRetirer = min(max(rang, 1), numel(bornes));
            bornes(aRetirer) = [];
            change = true;
        end
    end
end
