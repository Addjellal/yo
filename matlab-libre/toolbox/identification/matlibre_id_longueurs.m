function longueurs = matlibre_id_longueurs(donnees)
%MATLIBRE_ID_LONGUEURS Nombre d'échantillons de chaque expérience.
%   L = MATLIBRE_ID_LONGUEURS(D) rend un nombre par expérience.
%
%   Exemple :
%      matlibre_id_longueurs(zeros(10, 2))      % 10
%
%   Voir aussi IDDATA.
    if isempty(donnees)
        longueurs = 0;
    elseif iscell(donnees)
        longueurs = zeros(1, numel(donnees));
        for k = 1:numel(donnees)
            longueurs(k) = size(donnees{k}, 1);
        end
    else
        longueurs = size(donnees, 1);
    end
end
