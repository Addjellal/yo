function serie = taylor(f, varargin)
%TAYLOR Développement de Taylor d'une expression symbolique.
%   T = TAYLOR(F) développe F autour de zéro jusqu'au degré cinq.
%   T = TAYLOR(F,X) nomme la variable, TAYLOR(F,X,A) choisit le point.
%   TAYLOR(...,'Order',N) fixe l'ordre : le développement va jusqu'au
%   degré N-1, comme dans MATLAB (N vaut 6 par défaut).
%   TAYLOR(...,'ExpansionPoint',A) donne le point par son nom.
%   TAYLOR(F,X,A,N), avec l'ordre en quatrième position, est accepté.
%
%   Les coefficients viennent des dérivées successives évaluées au
%   point : c'est la définition, non une table.
%
%   Exemple :
%      syms x
%      pretty(taylor(exp(x), x, 0, 'Order', 4))   % 1 + x + x^2/2 + x^3/6
%      pretty(taylor(sin(x), x, 0, 6))
%
%   Voir aussi DIFF, SUBS, SIMPLIFY, LIMIT.
    variable = [];
    point = 0;
    ordre = 6;
    positionnels = {};
    k = 1;
    while k <= numel(varargin)
        argument = varargin{k};
        if (ischar(argument) || isstring(argument)) && ...
                any(strcmpi(char(argument), {'Order', 'ExpansionPoint', 'OrderMode'}))
            if k == numel(varargin)
                error('symbolic:taylor:Option', 'Option %s requires a value.', ...
                      char(argument));
            end
            switch lower(char(argument))
                case 'order'
                    ordre = double(varargin{k + 1});
                case 'expansionpoint'
                    point = varargin{k + 1};
                case 'ordermode'
                    if ~strcmpi(char(varargin{k + 1}), 'absolute')
                        error('symbolic:taylor:OrderMode', ...
                              'Only OrderMode ''absolute'' is supported.');
                    end
            end
            k = k + 2;
        else
            positionnels{end + 1} = argument; %#ok<AGROW>
            k = k + 1;
        end
    end
    if numel(positionnels) >= 1, variable = positionnels{1}; end
    if numel(positionnels) >= 2 && ~isempty(positionnels{2}), point = positionnels{2}; end
    if numel(positionnels) >= 3 && ~isempty(positionnels{3}), ordre = positionnels{3}; end
    if numel(positionnels) > 3
        error('MATLAB:TooManyInputs', 'Too many input arguments.');
    end
    if isempty(variable)
        variable = matlibre_sym_defaut(f);
    end
    nom = matlibre_sym_nom(variable);
    ordre = round(ordre);
    if ordre < 1
        error('symbolic:taylor:Ordre', 'At least one term is required.');
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
