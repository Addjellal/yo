function [x, valeur] = fminimax(fonctions, x0)
%FMINIMAX Minimise le maximum d'un ensemble de fonctions.
%   X = FMINIMAX(F,X0) où F(x) rend un vecteur : on minimise max(F(x)).
%   C'est le critère du pire cas : on ne cherche pas la meilleure moyenne
%   mais la plus petite des plus grandes valeurs, ce qui protège du
%   critère le plus mal servi.
%
%   [X,VAL] = FMINIMAX(...) rend en outre la valeur atteinte par ce
%   maximum.
%
%   Exemple :
%      % Deux droites qui se croisent : le maximum est le plus bas là
%      % où elles se coupent, en x = 1.
%      f = @(x) [x - 1; 1 - x];
%      x = fminimax(f, 0)             % 1
%
%   Voir aussi FMINCON, FGOALATTAIN, FMINSEARCH, LSQNONLIN.
    if ~isa(fonctions, 'function_handle')
        error('optim:fminimax:PoigneeAttendue', ...
              ['FMINIMAX attend une seule poignee rendant un vecteur, non ' ...
               'une liste de fonctions : ecrivez @(x) [f1(x); f2(x)].']);
    end
    objectif = @(v) max(fonctions(v));
    x = fminsearch(objectif, x0);
    valeur = max(fonctions(x));
end
