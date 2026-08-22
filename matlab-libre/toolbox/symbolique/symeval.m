function v = symeval(e, variables, valeurs)
%SYMEVAL Évaluation numérique d'une expression.
%   V = SYMEVAL(E,{'x','y'},[1 2]) remplace puis calcule.
    if nargin >= 3
        for k = 1:numel(variables)
            e = symsubs(e, variables{k}, valeurs(k));
        end
    end
    operateur = e{1};
    switch operateur
        case 'num'
            v = e{2};
        case 'var'
            error('symbolic:symeval:freeVariable', ...
                  'Variable ''%s'' has no value.', e{2});
        case '+', v = symeval(e{2}) + symeval(e{3});
        case '-', v = symeval(e{2}) - symeval(e{3});
        case '*', v = symeval(e{2}) * symeval(e{3});
        case '/', v = symeval(e{2}) / symeval(e{3});
        case '^', v = symeval(e{2}) ^ symeval(e{3});
        case 'sin', v = sin(symeval(e{2}));
        case 'cos', v = cos(symeval(e{2}));
        case 'tan', v = tan(symeval(e{2}));
        case 'exp', v = exp(symeval(e{2}));
        case 'log', v = log(symeval(e{2}));
        case 'sqrt', v = sqrt(symeval(e{2}));
        otherwise
            error('symbolic:symeval:unknown', 'Unknown operator ''%s''.', operateur);
    end
end
