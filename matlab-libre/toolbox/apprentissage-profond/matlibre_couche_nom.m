function nom = matlibre_couche_nom(arguments)
%MATLIBRE_COUCHE_NOM Nom donné à une couche, ou chaîne vide.
%   N = MATLIBRE_COUCHE_NOM(ARGUMENTS) lit l'option 'Name' parmi les
%   arguments d'un constructeur de couche. Sans nom, LAYERGRAPH en
%   attribuera un, tiré du type de la couche.
%
%   Exemple :
%      matlibre_couche_nom({'Name', 'conv1'})      % conv1
%
%   Voir aussi LAYERGRAPH, DLNETWORK.
    nom = '';
    for k = 1:2:numel(arguments) - 1
        if strcmpi(char(arguments{k}), 'name')
            nom = char(arguments{k + 1});
        end
    end
end
