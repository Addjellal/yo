function somme = symsum(f, variable, bas, haut)
%SYMSUM Somme d'une expression symbolique sur un intervalle d'entiers.
%   S = SYMSUM(F,K,A,B) additionne F pour K allant de A à B, bornes
%   comprises. A et B doivent être des entiers finis : la somme est
%   calculée terme à terme, non par une formule fermée.
%   S = SYMSUM(F,A,B) sous-entend la variable.
%
%   Exemple :
%      syms k
%      double(symsum(k, k, 1, 100))   % 5050
%      double(symsum(1 / k ^ 2, k, 1, 1000))   % environ pi^2/6
%
%   Voir aussi SYMPROD, INT, SUBS, SUM.
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
        error('symbolic:symsum:Bornes', ...
              'MatLibre somme terme à terme : les bornes doivent être finies.');
    end
    arbre = matlibre_sym_arbre(f);
    total = 0;
    for k = bas:haut
        total = total + symeval(symsubs(arbre, nom, symnum(k)));
    end
    somme = sym(total);
end
