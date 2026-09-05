function bloc = matlibre_id_bloc(donnees, indice)
%MATLIBRE_ID_BLOC Données d'une expérience donnée.
%   B = MATLIBRE_ID_BLOC(D,INDICE) rend la matrice de l'expérience, que
%   les données soient une matrice unique ou un tableau de cellules.
%
%   Exemple :
%      matlibre_id_bloc({[1;2], [3;4]}, 2)      % 3; 4
%
%   Voir aussi IDDATA.
    if iscell(donnees)
        bloc = donnees{indice};
    else
        bloc = donnees;
    end
end
