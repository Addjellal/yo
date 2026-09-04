function y = softmax(x)
%SOFTMAX Normalisation exponentielle, colonne par colonne.
%   Y = SOFTMAX(X) rend, pour chaque colonne, les exponentielles
%   normalisées à somme un : c'est la sortie d'un classifieur, lue comme
%   une loi de probabilité sur les classes.
%
%   Le maximum de la colonne est retranché avant l'exponentielle. Cela ne
%   change rien au résultat — le facteur commun se simplifie — mais
%   empêche le débordement dès que les scores dépassent quelques
%   centaines.
%
%   X peut être un DLARRAY : l'opération est alors dérivable, et sa
%   dérivée s'obtient sans qu'on ait à l'écrire.
%
%   Exemple :
%      softmax([0; log(3)])      % 0.25 ; 0.75
%
%   Voir aussi SIGMOID, RELU, CROSSENTROPY, SOFTMAXLAYER.
    v = x - max(x, [], 1);
    e = exp(v);
    y = e ./ sum(e, 1);
end
