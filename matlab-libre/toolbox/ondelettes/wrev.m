function y = wrev(x)
%WREV Renverse l'ordre des éléments d'un vecteur.
%   Y = WREV(X) renverse l'ordre des éléments de X, en conservant son
%   orientation, et convertit en double.
%
%   Le renversement n'est pas un utilitaire de confort : c'est l'opération
%   qui relie les quatre filtres d'un banc à reconstruction parfaite. Le
%   filtre de synthèse est le filtre d'analyse renversé, et le filtre
%   passe-haut s'obtient du passe-bas par renversement suivi d'une
%   alternance de signes — c'est la construction en miroir en quadrature.
%
%   Renverser un filtre revient aussi à passer de la convolution à la
%   corrélation : conv(x, wrev(f)) est la corrélation de x avec f.
%
%   Exemple :
%      wrev([1 2 3 4])
%
%   Voir aussi FLIPLR, FLIPUD, WCONV1, ORTHFILT.
    x = double(x);
    if isrow(x)
        y = fliplr(x);
    else
        y = flipud(x);
    end
end
