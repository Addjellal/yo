function vq = matlibre_plaque_mince(x, y, v, xq, yq)
%MATLIBRE_PLAQUE_MINCE Interpolation lisse par plaque mince.
%   VQ = MATLIBRE_PLAQUE_MINCE(X,Y,V,XQ,YQ) construit la surface qui passe
%   par tous les points et minimise l'énergie de flexion d'une plaque
%   mince — l'intégrale du carré des dérivées secondes.
%
%   La solution s'écrit comme une somme de fonctions radiales r²log(r),
%   plus un plan. Les coefficients sortent d'un système linéaire, avec
%   trois conditions d'orthogonalité qui empêchent la partie radiale
%   d'absorber le plan.
%
%   Contrairement à l'interpolation par triangles, la surface obtenue est
%   lisse partout, et elle s'étend hors de l'enveloppe des données.
%
%   Exemple :
%      [x, y] = meshgrid(0:0.5:1, 0:0.5:1);
%      z = 2 * x - 3 * y;
%      abs(matlibre_plaque_mince(x(:), y(:), z(:), 0.3, 0.7) - (0.6 - 2.1)) < 1e-8
%
%   Voir aussi GRIDDATA, MATLIBRE_GRILLE_LINEAIRE.
    n = numel(x);
    distances = matlibre_noyau_plaque(x, y, x, y);
    A = [distances, ones(n, 1), x, y; ...
         [ones(1, n); x.'; y.'], zeros(3, 3)];
    b = [v; zeros(3, 1)];
    solution = pinv(A) * b;
    poids = solution(1:n);
    plan = solution((n + 1):(n + 3));
    noyau = matlibre_noyau_plaque(x, y, xq, yq);
    vq = noyau * poids + plan(1) + plan(2) * xq + plan(3) * yq;
end
