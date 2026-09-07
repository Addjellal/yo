function c = maxPooling2dLayer(taille, varargin)
%MAXPOOLING2DLAYER Sous-échantillonnage par le maximum.
%   C = MAXPOOLING2DLAYER(TAILLE) ; le pas vaut la taille par défaut,
%   comme dans MATLAB. Option : 'Stride'.
%
%   Exemple :
%      c = maxPooling2dLayer(2);
%      c.taille                    % 2 2 : une fenetre carree
%
%   Voir aussi AVERAGEPOOLING2DLAYER, MAXPOOL, CONVOLUTION2DLAYER.
    if numel(taille) < 2, taille = [taille taille]; end
    pas = taille;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'stride')
            pas = varargin{k + 1};
            if numel(pas) < 2, pas = [pas pas]; end
        end
    end
    c = struct('type', 'maxpool', 'taille', taille(:)', 'pas', pas(:)', 'nom', matlibre_couche_nom(varargin));
end
