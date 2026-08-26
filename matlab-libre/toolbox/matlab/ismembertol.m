function tf = ismembertol(a, s, tol)
%ISMEMBERTOL Appartenance à un ensemble, à une tolérance près.
    if nargin < 3
        tol = 1e-6;
    end
    echelle = max([abs(a(:)); abs(s(:)); 1]);
    tf = false(size(a));
    for k = 1:numel(a)
        tf(k) = any(abs(s(:) - a(k)) <= tol * echelle);
    end
end
