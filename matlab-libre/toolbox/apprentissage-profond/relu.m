function y = relu(x)
%RELU Redresseur linéaire : max(0,x).
%   Y = RELU(X) rend max(X,0) terme à terme, pour un tableau ordinaire ou
%   un DLARRAY.
%
%   Sa dérivée vaut 0 ou 1 : le gradient traverse une unité active sans
%   être atténué, là où la sigmoïde le multiplie par au plus 0,25 à chaque
%   couche. C'est la raison pour laquelle les réseaux profonds
%   s'entraînent avec le redresseur et non avec la sigmoïde.
%
%   Le prix est l'unité morte : une unité dont l'entrée reste négative
%   rend zéro, donc un gradient nul, donc ne se corrige plus jamais.
%   LEAKYRELULAYER laisse passer une petite pente négative pour cela.
%
%   Exemple :
%      relu([-2 -1 0 1 2])
%
%   Voir aussi RELULAYER, LEAKYRELU, SIGMOID, SOFTMAX.
    y = max(x, 0);
end
