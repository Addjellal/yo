function y = qammod(x, M)
%QAMMOD Modulation d'amplitude en quadrature à M états (M carré).
%   La constellation est celle de la documentation : grille carrée
%   centrée, d'espacement 2.
    cote = sqrt(M);
    if abs(cote - round(cote)) > 1e-9
        error('comm:qammod:notSquare', 'M must be a perfect square.');
    end
    cote = round(cote);
    i = mod(x, cote);
    q = floor(x / cote);
    y = (2 * i - cote + 1) + 1i * (2 * q - cote + 1);
end
