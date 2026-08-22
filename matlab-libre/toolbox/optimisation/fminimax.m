function [x, valeur] = fminimax(fonctions, x0)
%FMINIMAX Minimise le maximum d'un ensemble de fonctions.
%   X = FMINIMAX(F,X0) où F(x) rend un vecteur : on minimise max(F(x)).
    objectif = @(v) max(fonctions(v));
    x = fminsearch(objectif, x0);
    valeur = max(fonctions(x));
end
