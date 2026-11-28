function primitive = symint(e, variable)
%SYMINT Primitive d'une expression, quand une règle exacte s'applique.
%   P = SYMINT(E, NOM) rend une primitive de E par rapport à la variable
%   NOM. Les règles reconnues :
%      - ce qui ne dépend pas de NOM : c*x ;
%      - les sommes, différences, et produits ou quotients par une
%        constante ;
%      - (a*x+b)^n, et 1/(a*x+b), qui donne log(a*x+b)/a ;
%      - c^(a*x+b), une base constante ;
%      - sin, cos, exp, sinh, cosh et log d'un argument affine a*x+b,
%        divisés par a ;
%      - exp(-a*x^2 + b*x + c), a > 0 : la gaussienne, par la fonction
%        d'erreur après avoir complété le carré ;
%      - c/(polynôme de degré 1 ou 2) : logarithme ou arc tangente.
%
%   Les règles de la composition ne valent que pour un argument affine :
%   la primitive de exp(-x^2) n'est pas exp(-x^2), ni celle de sin(x^2)
%   -cos(x^2). Quand aucune règle ne s'applique, SYMINT le dit par une
%   erreur au lieu de rendre une primitive fausse.
%
%   Exemple :
%      x = sym('x');
%      primitive = symint(x, 'x');
%      symeval(symdiff(primitive, 'x'), {'x'}, {3})     % 3 : deriver annule integrer
%      symeval(primitive, {'x'}, {2})                   % 2 : l'aire sous x de 0 a 2
%
%   Voir aussi SYMDIFF, SYMSIMPLIFY, SYMSTR.
    e = matlibre_sym_arbre(e);
    x = matlibre_sym_variable(variable);
    if ~depend(e, variable)
        primitive = symsimplify(symmul(e, x));
        return
    end
    operateur = e{1};
    switch operateur
        case 'var'
            primitive = symdiv(sympow(e, symnum(2)), symnum(2));
        case '+'
            primitive = symadd(symint(e{2}, variable), symint(e{3}, variable));
        case '-'
            primitive = symsub(symint(e{2}, variable), symint(e{3}, variable));
        case '*'
            if ~depend(e{2}, variable)
                primitive = symmul(e{2}, symint(e{3}, variable));
            elseif ~depend(e{3}, variable)
                primitive = symmul(e{3}, symint(e{2}, variable));
            else
                nonFait(e);
            end
        case '/'
            if ~depend(e{3}, variable)
                primitive = symdiv(symint(e{2}, variable), e{3});
            elseif ~depend(e{2}, variable)
                primitive = symmul(e{2}, inverseDePolynome(e{3}, variable, e));
            else
                nonFait(e);
            end
        case '^'
            base = e{2};
            exposant = e{3};
            if ~depend(exposant, variable)
                [a, ~, lineaire] = affine(base, variable);
                if ~lineaire
                    nonFait(e);
                end
                n = exposant;
                if strcmp(n{1}, 'num') && n{2} == -1
                    primitive = symdiv(symfun('log', base), symnum(a));
                else
                    suivant = symadd(n, symnum(1));
                    primitive = symdiv(sympow(base, suivant), symmul(suivant, symnum(a)));
                end
            elseif ~depend(base, variable)
                % c^(a*x+b) = exp((a*x+b)*log(c))
                [a, ~, lineaire] = affine(exposant, variable);
                if ~lineaire
                    nonFait(e);
                end
                primitive = symdiv(e, symmul(symnum(a), symfun('log', base)));
            else
                nonFait(e);
            end
        case {'sin', 'cos', 'exp', 'sinh', 'cosh', 'log'}
            argument = e{2};
            [a, ~, lineaire] = affine(argument, variable);
            if lineaire
                switch operateur
                    case 'sin',  exterieure = symmul(symnum(-1), symfun('cos', argument));
                    case 'cos',  exterieure = symfun('sin', argument);
                    case 'exp',  exterieure = e;
                    case 'sinh', exterieure = symfun('cosh', argument);
                    case 'cosh', exterieure = symfun('sinh', argument);
                    case 'log'
                        exterieure = symsub(symmul(argument, e), argument);
                end
                primitive = symdiv(exterieure, symnum(a));
            elseif strcmp(operateur, 'exp')
                primitive = gaussienne(argument, variable, e);
            else
                nonFait(e);
            end
        otherwise
            nonFait(e);
    end
    primitive = symsimplify(primitive);
end

function oui = depend(e, variable)
%DEPEND Vrai si l'expression contient la variable.
    oui = any(strcmp(matlibre_sym_noms(e), variable));
end

function [a, b, lineaire] = affine(e, variable)
%AFFINE Reconnaît a*x + b, a non nul et numérique.
    a = 0;
    b = 0;
    lineaire = false;
    c = coefficientsOuVide(e, variable);
    if numel(c) == 2 && c(1) ~= 0
        a = c(1);
        b = c(2);
        lineaire = true;
    end
end

function c = coefficientsOuVide(e, variable)
%COEFFICIENTSOUVIDE Les coefficients numériques d'un polynôme en x, ou [].
    try
        c = matlibre_sym_coefficients(e, variable);
        if ~isnumeric(c) || ~all(isfinite(c))
            c = [];
        end
    catch
        c = [];
    end
end

function primitive = gaussienne(argument, variable, e)
%GAUSSIENNE exp(alpha*x^2 + beta*x + gamma), alpha < 0, par la fonction
%   d'erreur : on complète le carré,
%      alpha*x^2 + beta*x + gamma = alpha*(x + beta/(2*alpha))^2 + delta,
%   et  integrale exp(-s*u^2) du = sqrt(pi)/(2*sqrt(s)) * erf(sqrt(s)*u).
    c = coefficientsOuVide(argument, variable);
    if numel(c) ~= 3 || ~(c(1) < 0)
        nonFait(e);
    end
    alpha = c(1);
    beta = c(2);
    gamma = c(3);
    s = -alpha;
    decalage = beta / (2 * alpha);
    delta = gamma - beta ^ 2 / (4 * alpha);
    x = matlibre_sym_variable(variable);
    u = symadd(x, symnum(decalage));
    facteur = exp(delta) * sqrt(pi) / (2 * sqrt(s));
    primitive = symmul(symnum(facteur), symfun('erf', symmul(symnum(sqrt(s)), u)));
end

function primitive = inverseDePolynome(denominateur, variable, e)
%INVERSEDEPOLYNOME Primitive de 1/(a*x + b) ou de 1/(a*x^2 + b*x + c).
    c = coefficientsOuVide(denominateur, variable);
    x = matlibre_sym_variable(variable);
    switch numel(c)
        case 2
            primitive = symdiv(symfun('log', denominateur), symnum(c(1)));
        case 3
            a = c(1);
            b = c(2);
            d = c(3);
            discriminant = b ^ 2 - 4 * a * d;
            if discriminant < 0
                % 2/sqrt(-D) * atan((2*a*x + b)/sqrt(-D))
                r = sqrt(-discriminant);
                interieur = symdiv(symadd(symmul(symnum(2 * a), x), symnum(b)), symnum(r));
                primitive = symmul(symnum(2 / r), symfun('atan', interieur));
            elseif discriminant > 0
                % Deux racines réelles x1 < x2 : 1/(a(x-x1)(x-x2)) se
                % décompose en éléments simples, qui donnent deux logarithmes.
                r = sqrt(discriminant);
                x1 = (-b - r) / (2 * a);
                x2 = (-b + r) / (2 * a);
                k = 1 / (a * (x1 - x2));
                primitive = symmul(symnum(k), ...
                    symsub(symfun('log', symfun('abs', symsub(x, symnum(x1)))), ...
                           symfun('log', symfun('abs', symsub(x, symnum(x2))))));
            else
                % Racine double : 1/(a(x - x0)^2) a pour primitive
                % -1/(a(x - x0)).
                x0 = -b / (2 * a);
                primitive = symdiv(symnum(-1 / a), symsub(x, symnum(x0)));
            end
        otherwise
            nonFait(e);
    end
end

function nonFait(e)
    error('symbolic:symint:unsupported', ...
          ['INT knows no exact antiderivative of %s; ', ...
           'INTEGRAL integrates it numerically between two bounds.'], symstr(e));
end
