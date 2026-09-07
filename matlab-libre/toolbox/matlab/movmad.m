function y = movmad(x, k, varargin)
%MOVMAD Écart absolu médian glissant.
%   Y = MOVMAD(X,K) rend, pour chaque point, l'écart absolu médian sur une
%   fenêtre de K points centrée sur lui. Aux bords, la fenêtre se réduit à
%   ce qui existe.
%   Y = MOVMAD(X,[AVANT APRES]) donne une fenêtre asymétrique : AVANT
%   points en arrière et APRES en avant.
%   Y = MOVMAD(...,'Endpoints','discard') n'écrit que les points dont la
%   fenêtre est entière ; la série rendue est alors plus courte.
%
%   L'écart absolu médian est à l'écart type ce que la médiane est à la
%   moyenne : il ne bouge pas quand une valeur isolée s'éloigne. Son point
%   de rupture est de cinquante pour cent — il faut fausser la moitié des
%   données pour le fausser — là où une seule valeur suffit à emporter
%   l'écart type.
%
%   Il vaut 0,6745 fois l'écart type sur des données gaussiennes ; c'est
%   l'inverse de ce facteur, 1,4826, qui sert à le convertir quand on veut
%   comparer les deux.
%
%   Exemple :
%      movmad([1 1 1 10 1 1 1], 3)     % la valeur aberrante ne perturbe
%                                      % que trois points
%      movmad(1:10, 3)                 % 1 partout au centre
%
%   Voir aussi MOVMEAN, MOVMEDIAN, MOVSTD, MAD, ISOUTLIER.
    y = matlibre_glissant(x, k, varargin, @(v) median(abs(v - median(v))));
end
