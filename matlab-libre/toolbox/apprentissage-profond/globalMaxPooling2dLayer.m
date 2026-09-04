function c = globalMaxPooling2dLayer(varargin)
%GLOBALMAXPOOLING2DLAYER Maximum sur toute l'image, canal par canal.
%   C = GLOBALMAXPOOLING2DLAYER() rend un nombre par canal : le maximum de
%   sa carte d'activation, c'est-à-dire la réponse la plus forte du motif
%   que ce canal détecte, où qu'il se trouve dans l'image.
%
%   Exemple :
%      c = globalMaxPooling2dLayer();
%
%   Voir aussi GLOBALAVERAGEPOOLING2DLAYER, MAXPOOLING2DLAYER.
    c = struct('type', 'globalmaxpool', 'nom', matlibre_couche_nom(varargin));
end
