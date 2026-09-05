function v = matlibre_rob_choisir(valeur, indice)
%MATLIBRE_ROB_CHOISIR Valeur commune ou valeur par degré de liberté.
%   Une consigne scalaire vaut pour tous les axes ; un vecteur en donne
%   une par axe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isscalar(valeur)
        v = valeur;
    else
        v = valeur(min(indice, numel(valeur)));
    end
end
