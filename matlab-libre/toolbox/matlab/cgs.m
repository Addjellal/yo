function [x, drapeau, residu, iterations, residus] = cgs(A, b, tolerance, maxIterations, M1, M2, x0)
%CGS Résolution itérative par méthode de Krylov.
%   X = CGS(A,B) résout A*X = B. X = CGS(A,B,TOL,MAXIT) impose la
%   tolérance relative — 1e-6 par défaut — et le nombre maximal
%   d'itérations. X = CGS(A,B,TOL,MAXIT,M1,M2,X0) ajoute un
%   préconditionneur et un point de départ. A peut être une poignée de
%   fonction rendant A*x.
%
%   [X,DRAPEAU,RES,K,RESIDUS] = CGS(...) rend le drapeau de sortie, le
%   résidu relatif, le nombre d'itérations et leur historique.
%
%   Contrairement à PCG, la matrice n'a pas à être définie positive : ces
%   méthodes valent pour un système quelconque. Le prix est la garantie —
%   le gradient conjugué converge de façon monotone en norme A, celles-ci
%   peuvent stagner ou osciller.
%
%   Exemple :
%      A = [4 1 0; 1 3 1; 0 1 2];
%      b = [1; 2; 3];
%      x = cgs(A, b, 1e-10, 50);
%      norm(A * x - b) / norm(b) < 1e-9
%
%   Voir aussi PCG, GMRES, MINRES, BICG, MLDIVIDE.
    M = [];
    if nargin >= 5 && ~isempty(M1), M = M1; end
    if nargin >= 6 && ~isempty(M2)
        if isempty(M), M = M2; else, M = M * M2; end
    end
    if nargin < 7, x0 = []; end
    if nargin < 4, maxIterations = []; end
    if nargin < 3, tolerance = []; end
    [x, drapeau, residu, iterations, residus] = ...
        matlibre_krylov('cgs', A, b, tolerance, maxIterations, M, x0);
end
