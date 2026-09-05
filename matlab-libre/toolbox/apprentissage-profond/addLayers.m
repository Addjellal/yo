function lg = addLayers(lg, couches)
%ADDLAYERS Ajoute des couches à un graphe, sans les raccorder.
%   LG = ADDLAYERS(LG,COUCHES) ajoute les couches et leur attribue un nom
%   si elles n'en portent pas. Les raccordements se posent ensuite par
%   CONNECTLAYERS : c'est ce découpage qui permet de décrire une branche
%   avant de savoir où elle se rebranchera.
%
%   Exemple :
%      lg = layerGraph();
%      lg = addLayers(lg, {reluLayer('Name', 'relu1')});
%
%   Voir aussi LAYERGRAPH, CONNECTLAYERS, DLNETWORK.
    % Les couches arrivent sous trois formes : une couche seule, une
    % cellule de couches, ou le tableau de structures que « [c1; c2] »
    % produit — la notation naturelle en MATLAB. Le tableau doit être
    % éclaté, sans quoi la suite prendrait ses champs pour une liste
    % d'arguments.
    if isstruct(couches) && numel(couches) > 1
        couches = arrayfun(@(c) c, couches, 'UniformOutput', false);
    elseif ~iscell(couches)
        couches = {couches};
    end
    for k = 1:numel(couches)
        couche = couches{k};
        nom = '';
        if isfield(couche, 'nom')
            nom = couche.nom;
        end
        if isempty(nom)
            nom = matlibre_reseau_nom_libre(lg.Names, couche.type);
        end
        if any(strcmp(lg.Names, nom))
            error('nnet:layerGraph:NomPris', ...
                  'Une couche porte déjà le nom « %s ».', nom);
        end
        couche.nom = nom;
        lg.Layers{end + 1} = couche;
        lg.Names{end + 1} = nom;
    end
end
