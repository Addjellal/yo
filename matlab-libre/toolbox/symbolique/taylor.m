function serie = taylor(f, variable, point, ordre)
%TAYLOR Développement de Taylor d'une expression symbolique.
%   T = TAYLOR(F) développe F autour de zéro jusqu'au degré cinq.
%   T = TAYLOR(F,X) nomme la variable, TAYLOR(F,X,A) choisit le point,
%   TAYLOR(F,X,A,N) le nombre de termes — le développement va alors
%   jusqu'au degré N-1, comme dans MATLAB.
%
%   Les coefficients viennent des dérivées successives évaluées au
%   point : c'est la définition, non une table.
%
%   Exemple :
%      syms x
%      pretty(taylor(exp(x), x, 0, 4))   % 1 + x + x^2/2 + x^3/6
%      pretty(taylor(sin(x), x, 0, 6))
%
%   Voir aussi DIFF, SUBS, SIMPLIFY, LIMIT.
    if nargin < 2 || isempty(variable)
        variable = matlibre_sym_defaut(f);
    end
    if nargin < 3 || isempty(point), point = 0; end
    if nargin < 4 || isempty(ordre), ordre = 6; end
    nom = matlibre_sym_nom(variable);
    ordre = round(ordre);
    if ordre < 1
        error('symbolic:taylor:Ordre', 'Il faut au moins un terme.');
    end
    arbrePoint = matlibre_sym_arbre(point);
    derivee = matlibre_sym_arbre(f);
    coefficients = zeros(1, ordre);
    factorielle = 1;
    for k = 0:(ordre - 1)
        if k > 0
            factorielle = factorielle * k;
            derivee = symdiff(derivee, nom);
        end
        valeur = symsubs(derivee, nom, arbrePoint);
        coefficients(k + 1) = symeval(valeur) / factorielle;
    end
    % Le développement s'écrit en puissances de (x - a).
    if strcmp(arbrePoint{1}, 'num') && arbrePoint{2} == 0
        serie = sym(matlibre_sym_polynome(fliplr(coefficients), nom));
        return
    end
    arbre = symnum(0);
    for k = 0:(ordre - 1)
        if coefficients(k + 1) == 0
            continue
        end
        base = symsub({'var', nom}, arbrePoint);
        if k == 0
            terme = symnum(coefficients(1));
        elseif k == 1
            terme = symmul(symnum(coefficients(2)), base);
        else
            terme = symmul(symnum(coefficients(k + 1)), sympow(base, symnum(k)));
        end
        arbre = symadd(arbre, terme);
    end
    serie = sym(symsimplify(arbre));
end
