function y = sigmoid(x)
%SIGMOID Sigmoïde logistique 1/(1+exp(-x)).
%   Y = SIGMOID(X) rend 1./(1+exp(-X)) terme à terme, pour un tableau
%   ordinaire ou un DLARRAY. La sortie est dans ]0,1[ et se lit donc comme
%   une probabilité, ce qui en fait la sortie naturelle d'une décision
%   binaire.
%
%   Sa dérivée vaut y(1-y), au plus 0,25 en zéro et pratiquement nulle
%   dès que |X| dépasse 5. D'où l'évanouissement du gradient : dans une
%   pile profonde de sigmoïdes, le gradient est multiplié par un facteur
%   inférieur à un quart à chaque couche et n'atteint plus les premières.
%
%   Exemple :
%      sigmoid([-2 0 2])
%
%   Voir aussi SIGMOIDLAYER, SOFTMAX, RELU, TANH.
    y = 1 ./ (1 + exp(-x));
end
