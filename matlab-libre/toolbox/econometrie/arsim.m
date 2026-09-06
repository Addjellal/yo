function y = arsim(phi, n, sigma, constante)
%ARSIM Simulation d'un processus autorégressif.
%   Y = ARSIM(PHI,N) simule N points d'un processus autorégressif
%   d'ordre NUMEL(PHI), de bruit blanc réduit et sans constante :
%   y(k) = PHI(1)*y(k-1) + … + PHI(p)*y(k-p) + e(k).
%   Y = ARSIM(PHI,N,SIGMA,CONSTANTE) impose l'écart type du bruit et le
%   terme constant.
%
%   Le processus démarre de zéro, les valeurs antérieures à l'instant un
%   étant prises nulles. Il n'est donc pas stationnaire au début : il faut
%   écarter les premiers points — quelques dizaines suffisent pour un
%   processus bien à l'intérieur du domaine de stabilité — avant de s'en
%   servir comme d'un échantillon stationnaire.
%
%   La stabilité tient aux racines de 1 - PHI(1)z - … - PHI(p)z^p : toutes
%   hors du cercle unité, la série oscille autour de CONSTANTE/(1-somme
%   des PHI) ; une racine sur le cercle, et c'est une marche aléatoire,
%   dont la variance croît sans borne.
%
%   Exemple :
%      rng(1);
%      y = arsim(0.5, 200);
%
%   Voir aussi AR, ARYULE, HURST, LAGMATRIX.
    if nargin < 3, sigma = 1; end
    if nargin < 4, constante = 0; end
    p = numel(phi);
    y = zeros(n, 1);
    bruit = sigma * randn(n, 1);
    for k = 1:n
        acc = constante + bruit(k);
        for j = 1:p
            if k - j >= 1
                acc = acc + phi(j) * y(k - j);
            end
        end
        y(k) = acc;
    end
end
