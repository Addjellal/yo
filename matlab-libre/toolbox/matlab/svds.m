function [U, S, V] = svds(A, k, choix)
%SVDS Quelques valeurs singulières seulement.
%   S = SVDS(A) rend les six plus grandes valeurs singulières.
%   S = SVDS(A,K) en rend K. S = SVDS(A,K,'smallest') rend les K plus
%   petites.
%   [U,S,V] = SVDS(...) rend la décomposition tronquée : A est approchée
%   par U*S*V', et c'est la meilleure approximation de rang K au sens de
%   la norme de Frobenius comme de la norme spectrale — c'est le théorème
%   d'Eckart-Young.
%
%   Comme EIGS, MATLAB emploie une méthode de Krylov et MatLibre la
%   décomposition complète tronquée : même résultat, coût de SVD.
%
%   La troncature est le fondement de l'analyse en composantes
%   principales et de la compression : garder les K premières valeurs
%   singulières, c'est garder la part d'énergie qu'elles portent, et
%   l'erreur commise est exactement la valeur singulière suivante.
%
%   Exemple :
%      A = magic(4);
%      svds(A, 2)'                         % les deux plus grandes
%      [U, S, V] = svds(A, 1);
%      s = svd(A);
%      abs(norm(A - U * S * V') - s(2)) < 1e-10   % Eckart-Young
%
%   Voir aussi SVD, EIGS, PCA, RANK, NORMEST.
    A = double(A);
    if nargin < 2 || isempty(k), k = min(6, min(size(A))); end
    [Utout, Stout, Vtout] = svd(A, 'econ');
    s = diag(Stout);
    k = min(round(k), numel(s));
    if nargin >= 3 && ~isempty(choix) && ...
       any(strcmpi(char(choix), {'smallest', 'smallestreal'}))
        indices = numel(s) - k + 1:numel(s);
        indices = fliplr(indices);
    else
        indices = 1:k;
    end
    if nargout <= 1
        U = s(indices);
    else
        U = Utout(:, indices);
        S = diag(s(indices));
        V = Vtout(:, indices);
    end
end
