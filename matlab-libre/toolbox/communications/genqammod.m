function y = genqammod(x, constellation)
%GENQAMMOD Modulation sur une constellation quelconque.
%   Y = GENQAMMOD(X,CONST) rend CONST(X+1) : X porte les indices, à partir
%   de zéro, des points de la constellation. C'est la forme générale dont
%   QAMMOD, PSKMOD et PAMMOD sont des cas particuliers, et elle permet les
%   constellations irrégulières — APSK, en croix, ou optimisées.
%
%   Exemple :
%      c = [1, 1i, -1, -1i];
%      genqammod([0 1 2 3], c)   % [1 1i -1 -1i]
%
%   Voir aussi GENQAMDEMOD, QAMMOD, MODNORM.
    constellation = constellation(:);
    x = double(x);
    M = numel(constellation);
    if any(x(:) < 0) || any(x(:) > M - 1) || any(x(:) ~= round(x(:)))
        error('comm:genqammod:BadSymbol', ...
              'Les symboles doivent être des entiers entre 0 et %d.', M - 1);
    end
    y = constellation(x + 1);
    y = reshape(y, size(x));
end
