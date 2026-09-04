function c = globalAveragePooling2dLayer(varargin)
%GLOBALAVERAGEPOOLING2DLAYER Moyenne sur toute l'image, canal par canal.
%   C = GLOBALAVERAGEPOOLING2DLAYER() rend un nombre par canal : la
%   moyenne de sa carte d'activation. Elle remplace avantageusement les
%   couches denses de fin de réseau convolutif — elle n'a aucun poids, et
%   accepte des images de n'importe quelle taille.
%
%   Exemple :
%      c = globalAveragePooling2dLayer('Name', 'moyenne');
%
%   Voir aussi GLOBALMAXPOOLING2DLAYER, AVERAGEPOOLING2DLAYER.
    c = struct('type', 'globalavgpool', 'nom', matlibre_couche_nom(varargin));
end
