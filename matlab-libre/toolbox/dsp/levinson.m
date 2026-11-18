function [a, e, k] = levinson(r, p)
%LEVINSON Récursion de Levinson-Durbin.
%   A = LEVINSON(R,P) résout le système de Toeplitz hermitien
%      toeplitz(R(1:P)) * A(2:P+1).' = -R(2:P+1).'
%   en O(P²) opérations, et rend le polynôme de prédiction
%   A = [1 A(2) ... A(P+1)] d'ordre P, R étant une autocorrélation
%   (réelle ou complexe). P vaut par défaut numel(R) - 1.
%   [A,E] = LEVINSON(R,P) rend aussi la variance de l'erreur de
%   prédiction d'ordre P, et [A,E,K] les P coefficients de réflexion, en
%   colonne.
%   Si R est une matrice, chacune de ses colonnes est une autocorrélation :
%   A a alors une ligne par colonne, E et K une colonne par colonne.
%
%   La récursion monte d'un ordre à la fois : le coefficient de réflexion
%   K(m) mesure ce que l'ordre m apporte, et l'erreur se multiplie à
%   chaque pas par 1 - |K(m)|². Tant que |K(m)| < 1, le filtre 1/A est
%   stable : c'est la garantie de la méthode d'autocorrélation.
%
%   Exemple :
%      % AR(2) de coefficients 0.75 et -0.5, autocorrélation exacte.
%      r = [16 8 -2] / 9;              % gamma(0), gamma(1), gamma(2)
%      [a, e] = levinson(r, 2)          % a = [1 -0.75 0.5], e = 1
%
%   Voir aussi LPC, RLEVINSON, TOEPLITZ, ARYULE.
    if isvector(r)
        r = r(:);
    end
    if nargin < 2 || isempty(p)
        p = size(r, 1) - 1;
    end
    if ~isscalar(p) || p < 0 || p ~= fix(p) || p > size(r, 1) - 1
        error('signal:levinson:Ordre', ...
              'L''ordre est un entier entre 0 et numel(R) - 1.');
    end
    nColonnes = size(r, 2);
    a = zeros(nColonnes, p + 1);
    e = zeros(nColonnes, 1);
    k = zeros(p, nColonnes);
    for c = 1:nColonnes
        [a(c, :), e(c), k(:, c)] = uneColonne(r(:, c).', p);
    end
end

function [a, e, k] = uneColonne(r, p)
    a = [1, zeros(1, p)];
    k = zeros(p, 1);
    e = r(1);
    for m = 1:p
        acc = r(m + 1) + sum(a(2:m) .* r(m:-1:2));
        reflexion = -acc / e;
        k(m) = reflexion;
        precedent = a;
        a(2:m) = precedent(2:m) + reflexion * conj(precedent(m:-1:2));
        a(m + 1) = reflexion;
        e = e * (1 - abs(reflexion) ^ 2);
    end
    if isreal(r)
        e = real(e);
    end
end
