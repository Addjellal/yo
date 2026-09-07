function [V, D] = eigs(A, k, choix)
%EIGS Quelques valeurs propres seulement.
%   D = EIGS(A) rend les six valeurs propres de plus grand module.
%   D = EIGS(A,K) en rend K. D = EIGS(A,K,CHOIX) précise lesquelles :
%      'largestabs'   plus grand module (défaut)
%      'smallestabs'  plus petit module
%      'largestreal'  plus grande partie réelle
%      'smallestreal' plus petite partie réelle
%   [V,D] = EIGS(...) rend les vecteurs propres en colonnes et les valeurs
%   propres sur la diagonale de D.
%
%   MATLAB emploie ici une méthode de Krylov, qui ne demande que des
%   produits matrice-vecteur et convient donc aux très grandes matrices
%   creuses. MatLibre calcule la décomposition complète et en retient ce
%   qui est demandé : le résultat est le même, mais le coût est celui de
%   EIG. Sur une matrice de quelques milliers de lignes, cela reste
%   praticable ; au-delà, c'est la limite à connaître.
%
%   Le tri par module est celui qui compte pour la stabilité : la
%   dynamique d'un système discret est gouvernée par sa valeur propre de
%   plus grand module, et c'est elle qu'on demande d'abord.
%
%   Exemple :
%      A = diag([1 2 3 10]);
%      eigs(A, 2)'                         % 10 3
%      eigs(A, 2, 'smallestabs')'          % 1 2
%      [V, D] = eigs(A, 1);
%      norm(A * V - V * D) < 1e-12
%
%   Voir aussi EIG, SVDS, NORMEST, CONDEST.
    A = double(A);
    n = size(A, 1);
    if nargin < 2 || isempty(k), k = min(6, n); end
    if nargin < 3 || isempty(choix), choix = 'largestabs'; end
    k = min(round(k), n);
    [vecteurs, valeurs] = eig(A);
    lambda = diag(valeurs);
    switch lower(char(choix))
        case 'largestabs',   [~, ordre] = sort(abs(lambda), 'descend');
        case 'smallestabs',  [~, ordre] = sort(abs(lambda), 'ascend');
        case 'largestreal',  [~, ordre] = sort(real(lambda), 'descend');
        case 'smallestreal', [~, ordre] = sort(real(lambda), 'ascend');
        otherwise
            error('MATLAB:eigs:UnknownOption', 'Choix inconnu : %s.', char(choix));
    end
    ordre = ordre(1:k);
    if nargout <= 1
        V = lambda(ordre);
    else
        V = vecteurs(:, ordre);
        D = diag(lambda(ordre));
    end
end
