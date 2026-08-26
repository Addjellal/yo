function x = idwt(approximation, detail, nom)
%IDWT Reconstruction à partir de l'approximation et du détail.
%   X = IDWT(A,D,NOM) inverse DWT. Le banc étant orthogonal et
%   l'extension périodique, l'inverse est l'adjoint de l'analyse : on
%   redistribue chaque coefficient sur les positions que la corrélation
%   avait lues.
%
%   Exemple :
%      [a, d] = dwt(1:8, 'db2');
%      max(abs(idwt(a, d, 'db2') - (1:8)))   % nul à l'arrondi près
    if nargin < 3
        nom = 'haar';
    end
    [~, ~, Lo_R, Hi_R] = wfilters(nom);
    m = numel(approximation);
    n = 2 * m;
    f = numel(Lo_R);
    x = zeros(1, n);
    for k = 1:m
        for j = 1:f
            indice = mod(2 * k - 2 + j - 1, n) + 1;
            x(indice) = x(indice) + Lo_R(j) * approximation(k) + Hi_R(j) * detail(k);
        end
    end
end
