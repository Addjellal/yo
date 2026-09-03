function b = polyscale(a, facteur)
%POLYSCALE Déplace les racines d'un polynôme vers l'origine.
%   B = POLYSCALE(A,ALPHA) rend le polynôme dont les racines sont celles
%   de A multipliées par ALPHA. C'est le changement de variable z -> z/ALPHA :
%   B(k) = A(k) * ALPHA^(n-k+1).
%
%   Avec 0 < ALPHA < 1, les racines rentrent vers l'origine — c'est ainsi
%   qu'on stabilise un filtre dont un pôle a débordé du cercle unité, ou
%   qu'on élargit les formants d'un modèle de parole.
%
%   Exemple :
%      a = poly([0.9, -0.95]);
%      max(abs(roots(polyscale(a, 0.5))))     % 0.475
%
%   Voir aussi POLYSTAB, ROOTS, POLY, LPC.
    a = double(a(:)).';
    n = numel(a) - 1;
    if n < 0
        b = a;
        return;
    end
    puissances = facteur .^ (0:n);
    b = a .* puissances;
end
