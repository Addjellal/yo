function r = partfrac(f, variable)
%PARTFRAC Décomposition en éléments simples.
%   PARTFRAC(F) réécrit une fraction rationnelle comme une somme de
%   termes dont les dénominateurs sont les facteurs du dénominateur de F.
%   PARTFRAC(F,X) nomme la variable.
%
%   Le principe tient à ce qu'un quotient de polynômes se décompose de
%   façon unique : à chaque racine du dénominateur correspond un terme
%   dont le dénominateur est cette racine seule. Les coefficients sont
%   les résidus, que RESIDUE calcule.
%
%   L'intérêt n'est pas l'apparence : sous cette forme, l'intégrale et la
%   transformée de Laplace inverse se lisent terme à terme, alors qu'elles
%   ne se lisent pas sur le quotient entier.
%
%   Ce qui est traité : les pôles réels, simples ou multiples. Les pôles
%   complexes donnent des termes à coefficients complexes plutôt que les
%   formes quadratiques réelles que MATLAB préfère, et l'aide le dit
%   plutôt que de le taire.
%
%   Exemple :
%      syms x
%      d = partfrac(1 / (x^2 - 3*x + 2));
%      abs(double(subs(d, x, 5)) - 1/12) < 1e-12   % meme valeur qu'avant
%
%   Voir aussi RESIDUE, NUMDEN, SIMPLIFY, FACTOR, COLLECT.
    f = sym(f);
    if nargin < 2 || isempty(variable)
        variable = matlibre_sym_defaut(f);
    end
    nom = matlibre_sym_nom(variable);
    [numerateur, denominateur] = numden(f);
    b = matlibre_sym_coefficients(matlibre_sym_developper(numerateur.arbre), nom);
    a = matlibre_sym_coefficients(matlibre_sym_developper(denominateur.arbre), nom);
    if numel(a) < 2
        % Pas de dénominateur en x : il n'y a rien à décomposer.
        r = sym(matlibre_sym_reduire(f.arbre));
        return
    end
    [residus, poles, entiere] = residue(b, a);

    arbre = [];
    if ~isempty(entiere) && any(entiere ~= 0)
        arbre = matlibre_sym_polynome(entiere, nom);
    end
    % Les pôles égaux se suivent : le k-ième d'une série donne une
    % puissance k du dénominateur, et c'est RESIDUE qui les range ainsi.
    multiplicite = 1;
    for k = 1:numel(poles)
        if k > 1 && abs(poles(k) - poles(k - 1)) < 1e-9 * max(1, abs(poles(k)))
            multiplicite = multiplicite + 1;
        else
            multiplicite = 1;
        end
        terme = matlibre_sym_terme_simple(residus(k), poles(k), multiplicite, nom);
        if isempty(terme)
            continue
        end
        if isempty(arbre)
            arbre = terme;
        else
            arbre = symadd(arbre, terme);
        end
    end
    if isempty(arbre)
        arbre = symnum(0);
    end
    r = sym(arbre);
end
