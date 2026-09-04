function y = avgpool(x, fenetre, varargin)
%AVGPOOL Agrégation par la moyenne.
%   Y = AVGPOOL(X,FENETRE) remplace chaque fenêtre par sa moyenne. Plus
%   douce que le maximum, elle garde la contribution de tous les pixels.
%
%   Options et valeurs par défaut :
%     'Stride'       la taille de la fenêtre
%     'Padding'      0, ou 'same'
%     'DataFormat'   le format, quand X n'en porte pas
%
%   La moyenne porte sur la fenêtre entière, remplissage compris.
%
%   Exemple :
%      extractdata(avgpool(dlarray(reshape(1:16, 4, 4), 'SS'), 2))
%
%   Voir aussi MAXPOOL, AVERAGEPOOLING2DLAYER.
    y = matlibre_dl_agregation_publique('moyenne', x, fenetre, varargin);
end
