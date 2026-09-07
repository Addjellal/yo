function y = papillonHadamard(x)
%PAPILLONHADAMARD Transformée de Hadamard rapide, ordre naturel.
%   Chaque étage remplace un couple (a,b) par (a+b, a-b) : c'est la
%   construction de Sylvester appliquée en place, en N log2 N additions.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      x = (1:8)';
%      y = papillonHadamard(x);
%      abs(y(1) - sum(x)) < 1e-12  % le premier coefficient est la somme
%      max(abs(papillonHadamard(y) / 8 - x)) < 1e-12   % involutive au facteur N
%
%   Voir aussi FWHT, IFWHT, RANGERWALSH.
    y = double(x);
    N = size(y, 1);
    pas = 1;
    while pas < N
        for debut = 1:2*pas:N
            for k = debut:debut + pas - 1
                a = y(k, :);
                b = y(k + pas, :);
                y(k, :) = a + b;
                y(k + pas, :) = a - b;
            end
        end
        pas = pas * 2;
    end
end
