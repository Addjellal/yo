function y = gaussmf(x, p)
%GAUSSMF Fonction d'appartenance gaussienne de paramètres [sigma centre].
%   Y = GAUSSMF(X,[SIGMA CENTRE]) rend exp(-(X-CENTRE)^2/(2*SIGMA^2)),
%   c'est-à-dire une cloche valant un au centre et décroissant
%   symétriquement.
%
%   L'ordre des paramètres est celui de la logique floue, largeur d'abord
%   et centre ensuite — l'inverse de l'usage en probabilité, et une source
%   d'erreur classique. La fonction n'est pas normalisée : c'est un degré
%   d'appartenance, dont le maximum vaut un, non une densité dont
%   l'intégrale vaudrait un.
%
%   Son intérêt sur la fonction triangulaire est d'être partout dérivable,
%   ce qui rend la surface de commande lisse et permet d'ajuster les
%   paramètres par descente de gradient, comme le fait ANFIS. Elle ne
%   s'annule jamais tout à fait : toutes les règles restent actives, avec
%   des poids infimes loin du centre.
%
%   Exemple :
%      gaussmf([25 30 35], [5 30])
%
%   Voir aussi GBELLMF, SIGMF, TRIMF, TRAPMF, EVALFIS.
    sigma = p(1);
    centre = p(2);
    y = exp(-((x - centre) .^ 2) / (2 * sigma ^ 2));
end
