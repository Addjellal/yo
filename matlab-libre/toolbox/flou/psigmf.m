function y = psigmf(x, params)
%PSIGMF Produit de deux sigmoïdes.
%   Y = PSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) .* sigmf(X,[A2 C2]).
%
%   Exemple :
%      y = psigmf([0 5 10], [2 2 -2 8]);
%      all(y >= 0 & y <= 1)        % 1
    y = sigmf(x, params(1:2)) .* sigmf(x, params(3:4));
end
