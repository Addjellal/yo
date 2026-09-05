function nombre = matlibre_id_voies(donnees)
%MATLIBRE_ID_VOIES Nombre de voies d'un jeu de données.
%   N = MATLIBRE_ID_VOIES(D) rend le nombre de colonnes, zéro si le jeu
%   est vide.
%
%   Exemple :
%      matlibre_id_voies(zeros(10, 2))      % 2
%
%   Voir aussi IDDATA.
    if isempty(donnees)
        nombre = 0;
    elseif iscell(donnees)
        if isempty(donnees{1})
            nombre = 0;
        else
            nombre = size(donnees{1}, 2);
        end
    else
        nombre = size(donnees, 2);
    end
end
