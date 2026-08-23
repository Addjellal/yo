function tf = islinphase(b, a)
%ISLINPHASE Le filtre est-il à phase linéaire ?
%   Un RIF est à phase linéaire si ses coefficients sont symétriques ou
%   antisymétriques. Un RII ne l'est qu'avec un dénominateur trivial.
    if nargin < 2, a = 1; end
    a = double(a(:)).';
    b = double(b(:)).';
    if numel(a) > 1 && any(a(2:end) ~= 0)
        tf = false;
        return
    end
    b = b / a(1);
    tolerance = 1e-10 * max(1, max(abs(b)));
    tf = all(abs(b - fliplr(b)) <= tolerance) || all(abs(b + fliplr(b)) <= tolerance);
end
