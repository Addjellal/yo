function type = matlibre_decomp_choisir(A)
%MATLIBRE_DECOMP_CHOISIR Choisit la factorisation la mieux adaptée.
%   Cholesky si la matrice est symétrique définie positive — il coûte
%   moitié moins que LU —, LDL si elle est symétrique sans être définie,
%   QR si elle n'est pas carrée, LU sinon.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_decomp_choisir([4 1; 1 3])       % 'chol'
%      matlibre_decomp_choisir([1 2; 3 4])       % 'lu'
%
%   Voir aussi DECOMPOSITION, CHOL, LU, QR, LDL.
    if size(A, 1) ~= size(A, 2)
        type = 'qr';
        return
    end
    if isempty(A) || max(max(abs(A - A'))) > 1e-12 * max(1, max(abs(A(:))))
        type = 'lu';
        return
    end
    [~, echec] = chol(A);
    if echec == 0
        type = 'chol';
    else
        type = 'ldl';
    end
end
