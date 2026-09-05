function donnees = matlibre_id_colonnes(brut)
%MATLIBRE_ID_COLONNES Données rangées en colonnes, une par voie.
%   D = MATLIBRE_ID_COLONNES(BRUT) accepte un vecteur, une matrice ou un
%   tableau de cellules — une case par expérience — et rend la même chose
%   avec les voies en colonnes.
%
%   Exemple :
%      size(matlibre_id_colonnes([1 2 3]))      % 3 1
%
%   Voir aussi IDDATA.
    if isempty(brut)
        donnees = [];
        return
    end
    if iscell(brut)
        donnees = cell(1, numel(brut));
        for k = 1:numel(brut)
            donnees{k} = matlibre_id_colonnes(brut{k});
        end
        return
    end
    donnees = double(brut);
    if isvector(donnees)
        donnees = donnees(:);
    end
end
