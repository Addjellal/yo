function [x, drapeau, residu, iterations, residus] = pcg(A, b, tolerance, maxIterations, M1, M2, x0)
%PCG Gradient conjugué préconditionné.
%   X = PCG(A,B) résout A*X = B pour une matrice symétrique définie
%   positive. X = PCG(A,B,TOL,MAXIT) impose la tolérance relative — 1e-6
%   par défaut — et le nombre maximal d'itérations.
%   X = PCG(A,B,TOL,MAXIT,M1,M2,X0) donne un préconditionneur M1*M2 et un
%   point de départ. A peut aussi être une poignée de fonction rendant
%   A*x.
%
%   [X,DRAPEAU,RES,K,RESIDUS] = PCG(...) rend le drapeau de sortie — 0 si
%   la tolérance est atteinte, 1 si le nombre d'itérations est épuisé —,
%   le résidu relatif final, le nombre d'itérations et l'historique.
%
%   La méthode construit une suite de directions conjuguées : chaque
%   direction est orthogonale aux précédentes au sens du produit scalaire
%   défini par A. C'est cette orthogonalité qui garantit la convergence en
%   au plus N itérations en arithmétique exacte, et qui fait qu'aucune
%   direction n'est jamais reprise.
%
%   Le nombre d'itérations utile est gouverné par le conditionnement :
%   l'erreur décroît d'un facteur (sqrt(k)-1)/(sqrt(k)+1) par itération,
%   où k est le conditionnement. C'est toute la raison d'être du
%   préconditionneur, qui vise à rapprocher M de A pour rendre k petit.
%
%   La symétrie n'est pas vérifiée : appliqué à une matrice qui ne l'est
%   pas, l'algorithme ne converge simplement pas. BICG et GMRES existent
%   pour ce cas.
%
%   Exemple :
%      % La matrice du laplacien discret : symetrique, definie positive.
%      n = 20;
%      A = full(spdiags([-ones(n,1), 2*ones(n,1), -ones(n,1)], -1:1, n, n));
%      b = ones(n, 1);
%      [x, drapeau, residu, k] = pcg(A, b, 1e-10, 100);
%      drapeau                             % 0 : la tolerance est atteinte
%      norm(A * x - b) / norm(b) < 1e-9
%
%   Voir aussi BICG, CGS, MINRES, GMRES, MLDIVIDE.
    M = [];
    if nargin >= 5 && ~isempty(M1), M = M1; end
    if nargin >= 6 && ~isempty(M2)
        if isempty(M), M = M2; else, M = M * M2; end
    end
    if nargin < 7, x0 = []; end
    if nargin < 4, maxIterations = []; end
    if nargin < 3, tolerance = []; end
    [x, drapeau, residu, iterations, residus] = ...
        matlibre_krylov('pcg', A, b, tolerance, maxIterations, M, x0);
end
