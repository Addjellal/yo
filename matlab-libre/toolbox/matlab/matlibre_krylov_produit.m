function y = matlibre_krylov_produit(A, v)
%MATLIBRE_KRYLOV_PRODUIT Le produit A*v, que A soit une matrice ou une poignée.
%   Les méthodes de Krylov ne demandent jamais la matrice, seulement son
%   action sur un vecteur : c'est ce qui leur permet de résoudre un système
%   dont la matrice ne tiendrait pas en mémoire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_krylov_produit(@(v) 2 * v, [1; 2])     % [2; 4]
%      matlibre_krylov_produit(eye(2), [1; 2])         % [1; 2]
%
%   Voir aussi PCG, BICG, GMRES.
    if isa(A, 'function_handle')
        y = A(v);
        y = y(:);
    else
        y = A * v;
    end
end
