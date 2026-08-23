function y = zmf(x, params)
%ZMF Fonction d'appartenance en Z : décroît de 1 à 0.
%   Y = ZMF(X,[A B]) vaut 1 avant A, 0 après B, avec deux arcs de
%   parabole raccordés au milieu — la courbe est donc dérivable.
%
%   Exemple :  zmf(0, [2 8])   % 1
    a = params(1);
    b = params(2);
    x = double(x);
    y = zeros(size(x));
    y(x <= a) = 1;
    milieu = (a + b) / 2;
    premier = x > a & x <= milieu;
    second = x > milieu & x < b;
    y(premier) = 1 - 2 * ((x(premier) - a) / (b - a)).^2;
    y(second) = 2 * ((x(second) - b) / (b - a)).^2;
end
