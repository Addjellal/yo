function rapport = analyzeNetwork(reseau)
%ANALYZENETWORK Décrit un réseau couche par couche.
%   ANALYZENETWORK(RESEAU) affiche, pour chaque couche, son nom, son type,
%   la taille qu'elle produit et le nombre de coefficients qu'elle
%   apprend, puis le total.
%
%   RAPPORT = ANALYZENETWORK(RESEAU) rend cette description dans une
%   table, sans rien afficher.
%
%   MATLAB ouvre une fenêtre ; MatLibre écrit un tableau, qui dit la même
%   chose et se lit dans un journal.
%
%   Exemple :
%      analyzeNetwork(dlnetwork({featureInputLayer(4), fullyConnectedLayer(3)}))
%
%   Voir aussi DLNETWORK, LAYERGRAPH.
    if ~isa(reseau, 'dlnetwork')
        reseau = dlnetwork(reseau);
    end
    noms = reseau.Names(:);
    types = cell(numel(noms), 1);
    coefficients = zeros(numel(noms), 1);
    for k = 1:numel(noms)
        types{k} = reseau.Layers{k}.type;
        parametres = matlibre_reseau_lire(reseau.Learnables, noms{k});
        champs = fieldnames(parametres);
        for j = 1:numel(champs)
            coefficients(k) = coefficients(k) + numel(matlibre_dl_valeur(parametres.(champs{j})));
        end
    end
    rapport = table(noms, types, coefficients, ...
                    'VariableNames', {'Name', 'Type', 'Learnables'});
    if nargout > 0
        return
    end
    fprintf('%-20s %-20s %12s\n', 'couche', 'type', 'coefficients');
    for k = 1:numel(noms)
        fprintf('%-20s %-20s %12d\n', noms{k}, types{k}, coefficients(k));
    end
    fprintf('%-20s %-20s %12d\n', 'total', '', sum(coefficients));
end
