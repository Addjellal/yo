function [y, correspondance] = gray2bin(x, modulation, M)
%GRAY2BIN Numérotation de Gray vers numérotation binaire.
%   Y = GRAY2BIN(X,MODULATION,M) est la réciproque de BIN2GRAY.
%
%   [Y,MAP] = GRAY2BIN(...) rend aussi la table complète.
%
%   Exemple :
%      gray2bin(bin2gray(0:7, 'psk', 8), 'psk', 8)   % 0:7
%
%   Voir aussi BIN2GRAY.
    directe = tableGray(modulation, M);
    correspondance = zeros(1, M);
    correspondance(directe + 1) = 0:M-1;
    x = double(x);
    if any(x(:) < 0) || any(x(:) > M - 1) || any(x(:) ~= round(x(:)))
        error('comm:gray2bin:BadSymbol', ...
              'Les symboles doivent être des entiers entre 0 et %d.', M - 1);
    end
    y = reshape(correspondance(x + 1), size(x));
end
