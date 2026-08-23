function t = firtype(b)
%FIRTYPE Type d'un filtre RIF à phase linéaire, de 1 à 4.
%   Type 1 : symétrique, longueur impaire.  Type 2 : symétrique, paire.
%   Type 3 : antisymétrique, impaire.       Type 4 : antisymétrique, paire.
    b = double(b(:)).';
    tolerance = 1e-10 * max(1, max(abs(b)));
    symetrique = all(abs(b - fliplr(b)) <= tolerance);
    antisymetrique = all(abs(b + fliplr(b)) <= tolerance);
    if ~symetrique && ~antisymetrique
        error('signal:firtype:NotLinearPhase', ...
              'Le filtre n''est pas à phase linéaire.');
    end
    impair = mod(numel(b), 2) == 1;
    if symetrique
        t = 1 + ~impair;
    else
        t = 3 + ~impair;
    end
end
