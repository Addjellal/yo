function y = pimf(x, params)
%PIMF Fonction d'appartenance en Pi : montée en S puis descente en Z.
%   Y = PIMF(X,[A B C D]) monte de A à B, vaut 1 de B à C, descend de C
%   à D.
%
%   Exemple :  pimf(5, [1 4 6 9])   % 1
    y = smf(x, params(1:2)) .* zmf(x, params(3:4));
end
