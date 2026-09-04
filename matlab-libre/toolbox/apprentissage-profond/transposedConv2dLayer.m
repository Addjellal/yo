function c = transposedConv2dLayer(taille, filtres, varargin)
%TRANSPOSEDCONV2DLAYER Convolution transposée, qui agrandit l'image.
%   C = TRANSPOSEDCONV2DLAYER(TAILLE,FILTRES) fait le chemin inverse d'une
%   convolution : là où celle-ci résume un voisinage en un point, celle-ci
%   étale un point sur un voisinage. Avec un pas de deux, elle double la
%   taille de l'image — c'est la couche qui remonte l'échelle dans les
%   réseaux de segmentation et les générateurs.
%
%   Options et valeurs par défaut :
%     'Stride'    1, le facteur d'agrandissement
%     'Cropping'  0, ce qu'on retire des bords après coup, ou 'same'
%
%   Exemple :
%      c = transposedConv2dLayer(4, 8, 'Stride', 2, 'Cropping', 1);
%
%   Voir aussi CONVOLUTION2DLAYER, DLCONV.
    pas = [1 1];
    rognage = 0;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'stride',   pas = matlibre_dl_couple(varargin{k + 1});
            case 'cropping', rognage = varargin{k + 1};
        end
    end
    if numel(taille) < 2
        taille = [taille taille];
    end
    c = struct('type', 'transposedconv2d', 'taille', taille(:).', ...
               'filtres', filtres, 'pas', pas, 'rognage', rognage, ...
               'W', [], 'b', [], 'nom', matlibre_couche_nom(varargin));
end
