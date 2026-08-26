function [y, correspondance] = bin2gray(x, modulation, M)
%BIN2GRAY Numérotation binaire vers numérotation de Gray.
%   Y = BIN2GRAY(X,MODULATION,M) renumérote les symboles pour que deux
%   points voisins de la constellation ne diffèrent que d'un bit.
%   MODULATION vaut 'psk', 'dpsk', 'pam', 'fsk' ou 'qam'.
%
%   Pour les constellations à une dimension, la transformation est
%   Y = bitxor(X, floor(X/2)). Pour 'qam', elle s'applique séparément aux
%   deux coordonnées de la constellation carrée.
%
%   [Y,MAP] = BIN2GRAY(...) rend aussi la table complète.
%
%   Exemple :
%      bin2gray(0:7, 'psk', 8)   % [0 1 3 2 6 7 5 4]
%
%   Voir aussi GRAY2BIN, PAMMOD, QAMMOD.
    correspondance = tableGray(modulation, M);
    x = double(x);
    if any(x(:) < 0) || any(x(:) > M - 1) || any(x(:) ~= round(x(:)))
        error('comm:bin2gray:BadSymbol', ...
              'Les symboles doivent être des entiers entre 0 et %d.', M - 1);
    end
    y = reshape(correspondance(x + 1), size(x));
end
