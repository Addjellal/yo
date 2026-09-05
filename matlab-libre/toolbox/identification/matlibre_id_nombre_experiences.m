function n = matlibre_id_nombre_experiences(obj)
%MATLIBRE_ID_NOMBRE_EXPERIENCES Combien d'expériences porte un jeu.
%   N = MATLIBRE_ID_NOMBRE_EXPERIENCES(OBJ) rend un si les données sont
%   une seule matrice, et le nombre de cases si elles sont en cellules.
%
%   Exemple :
%      matlibre_id_nombre_experiences(iddata((1:5)'))      % 1
%
%   Voir aussi IDDATA, MERGE.
    if iscell(obj.OutputData)
        n = numel(obj.OutputData);
    else
        n = 1;
    end
end
