function L = ichol(A, options)
%ICHOL Factorisation de Cholesky incomplète.
%   L = ICHOL(A) rend une matrice triangulaire inférieure telle que L*L'
%   approche A, en ne remplissant que les positions déjà non nulles de A.
%   A doit être symétrique définie positive.
%   L = ICHOL(A,OPTIONS) accepte les champs 'type' ('nofill' seul est
%   traité), 'diagcomp' et 'shape'.
%
%   Le mot « incomplète » désigne ce qu'on abandonne : la factorisation
%   exacte crée des coefficients là où A n'en avait pas — le remplissage —
%   et sur une grande matrice creuse ce remplissage est ce qui coûte tout.
%   On l'interdit, et la factorisation n'est plus exacte : L*L' ne vaut
%   plus A, seulement quelque chose de proche.
%
%   Cette approximation ne sert pas à résoudre, elle sert à
%   préconditionner : PCG appliqué à A avec le préconditionneur L*L'
%   converge en bien moins d'itérations, parce que le conditionnement
%   de L\A/L' est bien meilleur que celui de A.
%
%   L'option 'diagcomp' ajoute ALPHA*DIAG(A) avant de factoriser. Elle
%   sert quand la factorisation échoue sur une racine négative : décaler
%   la diagonale rend la matrice plus dominante, donc factorisable.
%
%   Exemple :
%      n = 30;
%      A = full(spdiags([-ones(n,1), 2*ones(n,1), -ones(n,1)], -1:1, n, n));
%      L = ichol(A);
%      istril(L)                                % 1 : elle est triangulaire
%      b = ones(n, 1);
%      [~, ~, ~, sans] = pcg(A, b, 1e-10, 200);
%      [~, ~, ~, avec] = pcg(A, b, 1e-10, 200, L * L');
%      avec <= sans                             % le preconditionneur aide
%
%   Voir aussi ILU, CHOL, PCG, MLDIVIDE.
    A = full(double(A));
    n = size(A, 1);
    if size(A, 2) ~= n
        error('MATLAB:ichol:NotSquare', 'La matrice doit être carrée.');
    end
    alpha = 0;
    if nargin >= 2 && isstruct(options) && isfield(options, 'diagcomp')
        alpha = double(options.diagcomp);
    end
    if alpha ~= 0
        A = A + alpha * diag(diag(A));
    end
    motif = A ~= 0;
    L = zeros(n);
    for j = 1:n
        somme = A(j, j) - L(j, 1:j-1) * L(j, 1:j-1)';
        if somme <= 0
            error('MATLAB:ichol:NotPositiveDefinite', ...
                  ['La factorisation incomplète a rencontré une racine ' ...
                   'négative en colonne %d. Essayez l''option diagcomp.'], j);
        end
        L(j, j) = sqrt(somme);
        for i = j+1:n
            if ~motif(i, j)
                continue   % pas de remplissage : c'est tout le principe
            end
            L(i, j) = (A(i, j) - L(i, 1:j-1) * L(j, 1:j-1)') / L(j, j);
        end
    end
end
