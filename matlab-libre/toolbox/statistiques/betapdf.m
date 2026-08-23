function y = betapdf(x, a, b)
%BETAPDF Densité de la loi bêta.
%   Y = BETAPDF(X,A,B) = x^(a-1)*(1-x)^(b-1)/B(a,b) sur [0,1], nulle
%   ailleurs.
%
%   Exemple :  betapdf(0.5, 1, 1)   % 1 : la loi uniforme
    x = double(x);
    y = zeros(size(x));
    dedans = x >= 0 & x <= 1;
    y(dedans) = exp((a - 1) .* log(max(x(dedans), realmin)) + ...
                    (b - 1) .* log(max(1 - x(dedans), realmin)) - betaln(a, b));
    % Les bornes demandent un traitement à part quand l'exposant s'annule.
    if a == 1, y(x == 0) = exp(-betaln(a, b)); end
    if b == 1, y(x == 1) = exp(-betaln(a, b)); end
end
