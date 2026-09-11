function d = matlibre_symmat_taille(arbre)
%MATLIBRE_SYMMAT_TAILLE Taille d'une expression matricielle symbolique.
%   D = MATLIBRE_SYMMAT_TAILLE(ARBRE) rend [lignes colonnes]. Les tailles
%   sont vérifiées en chemin : une somme de formats différents ou un
%   produit dont les dimensions intérieures ne concordent pas est refusé
%   à la construction, et non à l'expansion — c'est là que l'erreur est
%   encore lisible.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_symmat_taille({'mat', 'A', [2 3]})   % [2 3]
%
%   Voir aussi SYMMATRIX, SYMMATRIX2SYM.
    switch arbre{1}
        case 'mat'
            d = arbre{3};
        case 'const'
            d = size(arbre{2});
        case {'+', '-', '.*', './'}
            g = matlibre_symmat_taille(arbre{2});
            h = matlibre_symmat_taille(arbre{3});
            if isequal(g, [1 1]), d = h; return; end
            if isequal(h, [1 1]), d = g; return; end
            if ~isequal(g, h)
                error('symbolic:symmatrix:Dimensions', ...
                      'Formats incompatibles : %dx%d et %dx%d.', g(1), g(2), h(1), h(2));
            end
            d = g;
        case '*'
            g = matlibre_symmat_taille(arbre{2});
            h = matlibre_symmat_taille(arbre{3});
            if isequal(g, [1 1]), d = h; return; end
            if isequal(h, [1 1]), d = g; return; end
            if g(2) ~= h(1)
                error('symbolic:symmatrix:Dimensions', ...
                      'Produit impossible : %dx%d par %dx%d.', g(1), g(2), h(1), h(2));
            end
            d = [g(1) h(2)];
        case 'trans'
            d = fliplr(matlibre_symmat_taille(arbre{2}));
        case 'neg'
            d = matlibre_symmat_taille(arbre{2});
        case 'inv'
            d = carree(arbre{2}, 'INV');
        case 'pow'
            d = carree(arbre{2}, 'la puissance');
        case {'det', 'trace'}
            carree(arbre{2}, upper(arbre{1}));
            d = [1 1];
        case 'kron'
            g = matlibre_symmat_taille(arbre{2});
            h = matlibre_symmat_taille(arbre{3});
            d = [g(1) * h(1), g(2) * h(2)];
        otherwise
            error('symbolic:symmatrix:Operateur', ...
                  'Opérateur matriciel inconnu « %s ».', arbre{1});
    end
end

function d = carree(sousArbre, quoi)
    d = matlibre_symmat_taille(sousArbre);
    if d(1) ~= d(2)
        error('symbolic:symmatrix:Carree', ...
              '%s demande une matrice carrée ; celle-ci est %dx%d.', ...
              quoi, d(1), d(2));
    end
end
