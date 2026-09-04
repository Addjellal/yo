function c = convolution1dLayer(taille, filtres, varargin)
%CONVOLUTION1DLAYER Couche de convolution sur une dimension.
%   C = CONVOLUTION1DLAYER(TAILLE,FILTRES) fait glisser FILTRES filtres de
%   TAILLE positions le long de la séquence. Chaque filtre détecte un
%   motif temporel, où qu'il apparaisse : c'est l'équivalent, pour un
%   signal, de ce qu'une convolution d'image fait d'un motif spatial.
%
%   Options et valeurs par défaut :
%     'Stride'          1
%     'Padding'         0, ou 'same' pour garder la longueur
%     'DilationFactor'  1 ; l'écarter élargit le champ vu sans ajouter de
%                       poids, ce qui est la façon usuelle de couvrir un
%                       long passé
%
%   Exemple :
%      c = convolution1dLayer(5, 16, 'Padding', 'same');
%
%   Voir aussi CONVOLUTION2DLAYER, MAXPOOLING1DLAYER, DLCONV.
    pas = 1;
    marge = 0;
    dilatation = 1;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'stride',         pas = double(varargin{k + 1});
            case 'padding',        marge = varargin{k + 1};
            case 'dilationfactor', dilatation = double(varargin{k + 1});
        end
    end
    c = struct('type', 'conv1d', 'taille', taille, 'filtres', filtres, ...
               'pas', pas, 'marge', marge, 'dilatation', dilatation, ...
               'W', [], 'b', [], 'nom', matlibre_couche_nom(varargin));
end
