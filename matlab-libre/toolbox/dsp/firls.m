function b = firls(n, f, m)
%FIRLS Filtre RIF à phase linéaire, au sens des moindres carrés.
%   B = FIRLS(N,F,M) approche le gabarit défini par les couples (F,M),
%   F étant normalisé entre 0 et 1.
    N = n + 1;
    grille = linspace(0, 1, 512);
    cible = interp1(f, m, grille, 'linear', 'extrap');
    k = (0:n) - n/2;
    A = zeros(numel(grille), N);
    for i = 1:numel(grille)
        A(i, :) = cos(pi * grille(i) * k);
    end
    b = (A \ cible(:)).';
end
