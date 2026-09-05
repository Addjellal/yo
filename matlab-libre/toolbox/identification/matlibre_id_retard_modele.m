function nk = matlibre_id_retard_modele(modele)
%MATLIBRE_ID_RETARD_MODELE Retard d'entrée d'un modèle polynomial.
%   NK = MATLIBRE_ID_RETARD_MODELE(MODELE) rend le retard que le modèle
%   déclare dans ses ordres, ou, à défaut, celui que trahissent les zéros
%   de tête de son numérateur.
%
%   Le déclarer vaut mieux que le lire : un coefficient estimé peut
%   tomber exactement à zéro, et le retard apparent changerait alors sans
%   que le modèle ait changé.
%
%   Exemple :
%      matlibre_id_retard_modele(idpoly(1, [0 0.2]))      % 1
%
%   Voir aussi IDPOLY, GETPVEC.
    if ~isempty(modele.Ordres) && numel(modele.Ordres) >= 6
        nk = modele.Ordres(6);
        return
    end
    nk = matlibre_id_retard(modele.B);
end
