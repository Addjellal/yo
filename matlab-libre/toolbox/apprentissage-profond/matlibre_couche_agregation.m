function [pas, marge] = matlibre_couche_agregation(taille, arguments)
%MATLIBRE_COUCHE_AGREGATION Pas et remplissage d'une couche d'agrégation.
%   [PAS,MARGE] = MATLIBRE_COUCHE_AGREGATION(TAILLE,ARGUMENTS) rend le pas
%   — la taille de la fenêtre par défaut, comme dans MATLAB — et le
%   remplissage.
%
%   Exemple :
%      [p, m] = matlibre_couche_agregation(2, {'Stride', 1});
%
%   Voir aussi MAXPOOLING1DLAYER, AVERAGEPOOLING1DLAYER.
    pas = taille;
    marge = 0;
    for k = 1:2:numel(arguments) - 1
        switch lower(char(arguments{k}))
            case 'stride',  pas = double(arguments{k + 1});
            case 'padding', marge = arguments{k + 1};
        end
    end
end
