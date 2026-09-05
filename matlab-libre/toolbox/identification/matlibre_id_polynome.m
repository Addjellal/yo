function p = matlibre_id_polynome(brut)
%MATLIBRE_ID_POLYNOME Polynôme en l'opérateur de décalage, en ligne.
%   P = MATLIBRE_ID_POLYNOME(BRUT) rend un vecteur ligne. Un polynôme vide
%   vaut un : c'est la convention des modèles, où un polynôme absent ne
%   filtre rien.
%
%   Exemple :
%      matlibre_id_polynome([1; -0.8])      % 1 -0.8
%
%   Voir aussi IDPOLY.
    if isempty(brut)
        p = 1;
        return
    end
    p = double(brut(:)).';
end
