function nom = matlibre_reseau_nom_seul(specification)
%MATLIBRE_RESEAU_NOM_SEUL Nom de couche, sans le nom du port.
%   N = MATLIBRE_RESEAU_NOM_SEUL('somme/in2') rend 'somme'. MATLAB nomme
%   les ports d'entrée d'une couche qui en a plusieurs ; MatLibre les
%   raccorde dans l'ordre où on les pose, et ne retient donc que la
%   couche.
%
%   Exemple :
%      matlibre_reseau_nom_seul('add/in2')     % add
%
%   Voir aussi CONNECTLAYERS.
    nom = char(specification);
    coupe = find(nom == '/', 1);
    if ~isempty(coupe)
        nom = nom(1:(coupe - 1));
    end
end
