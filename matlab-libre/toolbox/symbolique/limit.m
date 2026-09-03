function valeur = limit(f, variable, point, direction)
%LIMIT Limite d'une expression symbolique.
%   L = LIMIT(F,X,A) rend la limite de F quand X tend vers A.
%   L = LIMIT(F,X,A,'left') ou 'right' prend la limite d'un seul côté.
%   L = LIMIT(F) et LIMIT(F,A) sous-entendent la variable.
%
%   La limite est cherchée numériquement, en s'approchant du point par
%   pas géométriquement décroissants, puis en accélérant la convergence
%   par extrapolation de Richardson. Une substitution directe suffit
%   quand elle donne un résultat fini : c'est le cas courant.
%
%   Comptez une dizaine de chiffres exacts sur les limites usuelles ; la
%   méthode est numérique, non formelle, et ne prouve rien.
%
%   Exemple :
%      syms x
%      double(limit(sin(x) / x, x, 0))   % 1
%      double(limit((1 + 1/x) ^ x, x, Inf))   % environ e
%
%   Voir aussi TAYLOR, DIFF, SUBS, DOUBLE.
    if nargin < 2
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargin == 2
        point = variable;
        variable = matlibre_sym_defaut(f);
    end
    if nargin < 4, direction = 'both'; end
    nom = matlibre_sym_nom(variable);
    arbre = matlibre_sym_arbre(f);
    cible = double(matlibre_sym_valeur(point));
    direction = lower(char(direction));
    % Substitution directe : si elle donne un nombre fini, c'est fini.
    if isfinite(cible)
        try
            directe = symeval(symsubs(arbre, nom, symnum(cible)));
            if isfinite(directe)
                valeur = sym(directe);
                return
            end
        catch
            % La substitution ne passe pas : on approche.
        end
    end
    valeur = sym(matlibre_sym_limite(arbre, nom, cible, direction));
end
