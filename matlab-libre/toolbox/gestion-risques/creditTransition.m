function [P, etats] = creditTransition(notations)
%CREDITTRANSITION Matrice de transition estimée sur des trajectoires.
%   [P,ETATS] = CREDITTRANSITION(N) où N a une ligne par émetteur et une
%   colonne par date : N(i,t) est la notation de l'émetteur i à la date t.
%   P(a,b) est la proportion des passages de l'état a vers l'état b, et
%   ETATS donne les états dans l'ordre des lignes et des colonnes.
%
%   Les notations peuvent être des nombres, des chaînes ou des
%   catégories : les états sont alors les valeurs distinctes, rangées
%   dans l'ordre où UNIQUE les met.
%
%   Chaque ligne somme à un, sauf celle d'un état d'où l'on n'est jamais
%   parti — un état absorbant observé une seule fois, par exemple — qui
%   reste nulle. C'est la propriété qui valide l'estimation : une matrice
%   de transition est stochastique par ligne.
%
%   L'estimateur est celui du maximum de vraisemblance pour une chaîne de
%   Markov d'ordre un : compter les passages et diviser. Il suppose donc
%   que la probabilité de transition ne dépend que de l'état courant, ce
%   que les notations réelles démentent — une note récemment dégradée se
%   dégrade plus souvent qu'une note stable de même niveau.
%
%   Exemple :
%      trajectoires = [1 1 2; 2 2 3; 1 2 2];
%      [P, etats] = creditTransition(trajectoires);
%      sum(P, 2)                       % un par ligne visitee
%
%   Voir aussi DRAWDOWNSERIES, PORTVRISK.
    if iscell(notations) || isstring(notations) || iscategorical(notations)
        plates = cellstr(notations);
        etats = unique(plates(:));
        indices = zeros(size(notations));
        for k = 1:numel(plates)
            indices(k) = find(strcmp(etats, plates{k}), 1);
        end
    else
        etats = unique(notations(:));
        indices = zeros(size(notations));
        for k = 1:numel(notations)
            indices(k) = find(etats == notations(k), 1);
        end
    end
    k = numel(etats);
    compte = zeros(k, k);
    for i = 1:size(indices, 1)
        for t = 1:size(indices, 2) - 1
            compte(indices(i, t), indices(i, t + 1)) = ...
                compte(indices(i, t), indices(i, t + 1)) + 1;
        end
    end
    P = zeros(k, k);
    for i = 1:k
        total = sum(compte(i, :));
        if total > 0
            P(i, :) = compte(i, :) / total;
        end
    end
end
