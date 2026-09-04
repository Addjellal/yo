function x = matlibre_dl_entree(donnees)
%MATLIBRE_DL_ENTREE Données d'entrée, en DLARRAY.
%   X = MATLIBRE_DL_ENTREE(D) enveloppe D si ce n'en est pas déjà un, et
%   lui donne le format qu'impose sa forme.
%
%   Exemple :
%      dims(matlibre_dl_entree(zeros(3, 8)))      % CB
%
%   Voir aussi DLNETWORK, DLARRAY.
    if isa(donnees, 'dlarray')
        x = donnees;
        if isempty(dims(x))
            x = dlarray(x, matlibre_dl_format_entree(x));
        end
        return
    end
    x = dlarray(donnees, matlibre_dl_format_entree(donnees));
end
