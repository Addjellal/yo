function produit = symprod(f, variable, bas, haut)
%SYMPROD Produit d'une expression symbolique sur un intervalle d'entiers.
%   P = SYMPROD(F,K,A,B) multiplie F pour K allant de A à B, bornes
%   comprises. Comme SYMSUM, le calcul est terme à terme.
%   P = SYMPROD(F,A,B) sous-entend la variable.
%
%   Exemple :
%      syms k
%      double(symprod(k, k, 1, 6))    % 720 : la factorielle de six
%
%   Voir aussi SYMSUM, PROD, FACTORIAL.
    if nargin == 3
        haut = bas;
        bas = variable;
        variable = matlibre_sym_defaut(f);
    end
    if nargin < 3
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    nom = matlibre_sym_nom(variable);
    bas = round(matlibre_sym_valeur(bas));
    haut = round(matlibre_sym_valeur(haut));
    if ~isfinite(bas) || ~isfinite(haut)
        error('symbolic:symprod:Bornes', ...
              'MatLibre multiplie terme à terme : les bornes doivent être finies.');
    end
    arbre = matlibre_sym_arbre(f);
    total = 1;
    for k = bas:haut
        total = total * symeval(symsubs(arbre, nom, symnum(k)));
    end
    produit = sym(total);
end
