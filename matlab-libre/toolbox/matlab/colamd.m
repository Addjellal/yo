function p = colamd(A)
%COLAMD Renumérotation des colonnes par degré minimal.
%   P = COLAMD(A) rend une permutation des colonnes qui réduit le
%   remplissage de la factorisation LU de A(:,P), sans supposer A
%   symétrique ni carrée.
%
%   L'ordre est celui du degré minimal appliqué au graphe de A'*A, dont la
%   structure est exactement celle qui gouverne le remplissage de la
%   factorisation par colonnes. On ne forme pas A'*A pour ses valeurs,
%   seulement pour son motif.
%
%   Exemple :
%      A = [1 1 1; 1 0 0; 1 0 0; 0 1 0];
%      p = colamd(A);
%      isequal(sort(p), 1:3)                    % 1 : c'est une permutation
%
%   Voir aussi SYMAMD, SYMRCM, LU, QR.
    A = full(double(A ~= 0));
    motif = (A' * A) ~= 0;
    p = matlibre_degre_minimal(motif);
end
