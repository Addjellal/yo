function y = dsigmf(x, params)
%DSIGMF Différence de deux sigmoïdes.
%   Y = DSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) - sigmf(X,[A2 C2]).
    y = sigmf(x, params(1:2)) - sigmf(x, params(3:4));
end
