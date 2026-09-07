function K = noyauSvm(A, B, options)
%NOYAUSVM Matrice de noyau entre deux jeux de points.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = lireOptionsSvm('KernelFunction', 'linear');
%      K = noyauSvm([1 0; 0 1], [1 0; 0 1], o);
%      max(max(abs(K - K'))) < 1e-12          % un noyau est symetrique
    switch options.KernelFunction
        case 'linear'
            K = (A * B.') / options.KernelScale ^ 2;
        case 'rbf'
            distances = repmat(sum(A .^ 2, 2), 1, size(B, 1)) + ...
                        repmat(sum(B .^ 2, 2).', size(A, 1), 1) - 2 * (A * B.');
            K = exp(-max(distances, 0) / (2 * options.KernelScale ^ 2));
        case 'polynomial'
            K = (1 + (A * B.') / options.KernelScale ^ 2) .^ options.PolynomialOrder;
        otherwise
            error('stats:fitcsvm:Noyau', ...
                  'Noyau inconnu : %s.', options.KernelFunction);
    end
end
