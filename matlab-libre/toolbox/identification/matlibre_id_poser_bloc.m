function obj = matlibre_id_poser_bloc(obj, champ, indice, bloc)
%MATLIBRE_ID_POSER_BLOC Range les données d'une expérience.
%   OBJ = MATLIBRE_ID_POSER_BLOC(OBJ,CHAMP,INDICE,BLOC) écrit dans la
%   propriété nommée, à la bonne place selon que le jeu porte une ou
%   plusieurs expériences.
%
%   Exemple :
%      z = matlibre_id_poser_bloc(iddata((1:3)'), 'OutputData', 1, (4:6)');
%
%   Voir aussi IDDATA.
    if iscell(obj.(champ))
        courant = obj.(champ);
        courant{indice} = bloc;
        obj.(champ) = courant;
    else
        obj.(champ) = bloc;
    end
end
