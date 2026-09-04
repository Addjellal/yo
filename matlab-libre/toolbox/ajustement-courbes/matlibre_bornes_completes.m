function bornes = matlibre_bornes_completes(donnees, nombre, defaut)
%MATLIBRE_BORNES_COMPLETES Bornes d'un vecteur de coefficients.
%   B = MATLIBRE_BORNES_COMPLETES(DONNEES,NOMBRE,DEFAUT) complète des
%   bornes partielles avec la valeur par défaut, et rend un vecteur de la
%   bonne longueur.
%
%   Exemple :
%      matlibre_bornes_completes([0], 3, -inf)      % 0 -inf -inf
%
%   Voir aussi FIT, FITOPTIONS.
    bornes = repmat(defaut, 1, nombre);
    if isempty(donnees)
        return
    end
    donnees = double(donnees(:)).';
    n = min(numel(donnees), nombre);
    bornes(1:n) = donnees(1:n);
end
