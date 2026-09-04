function [y, indices, tailleEntree] = maxpool(x, fenetre, varargin)
%MAXPOOL Agrégation par le maximum.
%   Y = MAXPOOL(X,FENETRE) ne garde, de chaque fenêtre, que la plus grande
%   valeur. La sortie est plus petite, et surtout elle ne change pas quand
%   le motif se déplace de moins d'une fenêtre : c'est ce qui donne à un
%   réseau convolutif sa tolérance aux petits décalages.
%
%   [Y,I,T] = MAXPOOL(...) rend aussi les positions retenues et la taille
%   de l'entrée, de quoi défaire l'agrégation.
%
%   Options et valeurs par défaut :
%     'Stride'       la taille de la fenêtre
%     'Padding'      0, ou 'same'
%     'DataFormat'   le format, quand X n'en porte pas
%
%   Le remplissage vaut moins l'infini : une case ajoutée ne peut pas
%   l'emporter sur une vraie valeur.
%
%   Exemple :
%      extractdata(maxpool(dlarray(reshape(1:16, 4, 4), 'SS'), 2))
%
%   Voir aussi AVGPOOL, MAXPOOLING2DLAYER, DLCONV.
    [y, indices, tailleEntree] = matlibre_dl_agregation_publique('max', x, fenetre, varargin);
end
