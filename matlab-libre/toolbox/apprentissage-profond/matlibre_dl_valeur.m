function v = matlibre_dl_valeur(x)
%MATLIBRE_DL_VALEUR Contenu numérique d'un opérande.
%   V = MATLIBRE_DL_VALEUR(X) rend le tableau que X porte, que X soit un
%   DLARRAY ou un tableau ordinaire. Les opérations mélangent librement
%   les deux : un poids suivi peut être multiplié par une constante.
%
%   Exemple :
%      matlibre_dl_valeur(dlarray([1 2]))     % 1 2
%
%   Voir aussi DLARRAY, EXTRACTDATA.
    if isa(x, 'dlarray')
        v = x.Valeur;
    else
        v = double(x);
    end
end
