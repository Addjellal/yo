function [C, L] = wavedec(x, niveaux, nom)
%WAVEDEC Décomposition multiniveaux en ondelettes.
%   [C,L] = WAVEDEC(X,N,NOM) empile les coefficients : approximation de
%   niveau N, puis détails du niveau N au niveau 1. L donne les longueurs.
    if nargin < 3
        nom = 'haar';
    end
    x = x(:).';
    C = [];
    L = [];
    courant = x;
    details = {};
    for k = 1:niveaux
        [a, d] = dwt(courant, nom);
        details{k} = d;
        courant = a;
    end
    C = courant;
    L = numel(courant);
    for k = niveaux:-1:1
        C = [C, details{k}];
        L = [L, numel(details{k})];
    end
    L = [L, numel(x)];
end
