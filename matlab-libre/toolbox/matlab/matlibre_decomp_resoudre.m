function x = matlibre_decomp_resoudre(d, b)
%MATLIBRE_DECOMP_RESOUDRE Substitution dans une factorisation gardée.
%   Chaque type se résout par ses propres substitutions : deux
%   triangulaires pour LU et Cholesky, une projection puis une
%   triangulaire pour QR.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      d = decomposition([4 1; 1 3]);
%      norm(matlibre_decomp_resoudre(d, [1; 2]) - [4 1; 1 3] \ [1; 2]) < 1e-12
%
%   Voir aussi DECOMPOSITION, MLDIVIDE.
    f = d.Facteurs;
    switch f.type
        case 'chol'
            % A = R'*R : une descente puis une remontee.
            x = f.R \ (f.R' \ b);
        case 'ldl'
            x = f.P * (f.L' \ (f.D \ (f.L \ (f.P' * b))));
        case 'qr'
            % Les moindres carres : Q'*b projette, R remonte.
            x = f.R \ (f.Q' * b);
        otherwise
            x = f.U \ (f.L \ (f.P * b));
    end
end
