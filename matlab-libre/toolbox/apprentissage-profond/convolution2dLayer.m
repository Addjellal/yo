function c = convolution2dLayer(taille, filtres, varargin)
%CONVOLUTION2DLAYER Couche de convolution bidimensionnelle.
%   C = CONVOLUTION2DLAYER(TAILLE,FILTRES) où TAILLE est le côté du
%   noyau, ou [H L]. Options : 'Stride' (pas, 1 par défaut) et 'Padding'
%   (0 par défaut, ou 'same' pour garder la taille).
%
%   Les poids sont initialisés par la règle de Glorot au premier appel de
%   TRAINNETWORK, quand la profondeur d'entrée est connue.
%
%   Exemple :
%      c = convolution2dLayer(3, 8, 'Padding', 'same');
    if numel(taille) < 2, taille = [taille taille]; end
    pas = 1;
    marge = 0;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'stride'
                pas = varargin{k + 1};
                if numel(pas) < 2, pas = [pas pas]; end
            case 'padding'
                marge = varargin{k + 1};
        end
    end
    if numel(pas) < 2, pas = [pas pas]; end
    c = struct('type', 'conv2d', 'taille', taille(:)', 'filtres', filtres, ...
               'pas', pas(:)', 'marge', marge, 'W', [], 'b', []);
end
