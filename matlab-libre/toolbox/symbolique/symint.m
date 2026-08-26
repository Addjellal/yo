function primitive = symint(e, variable)
%SYMINT Primitive des formes polynomiales et élémentaires.
%   Reconnaît les constantes, x^n, sin, cos, exp et les sommes.
    operateur = e{1};
    switch operateur
        case 'num'
            primitive = symmul(e, symvar(variable));
        case 'var'
            if strcmp(e{2}, variable)
                primitive = symdiv(sympow(e, symnum(2)), symnum(2));
            else
                primitive = symmul(e, symvar(variable));
            end
        case '+'
            primitive = symadd(symint(e{2}, variable), symint(e{3}, variable));
        case '-'
            primitive = symsub(symint(e{2}, variable), symint(e{3}, variable));
        case '*'
            if strcmp(e{2}{1}, 'num')
                primitive = symmul(e{2}, symint(e{3}, variable));
            elseif strcmp(e{3}{1}, 'num')
                primitive = symmul(e{3}, symint(e{2}, variable));
            else
                error('symbolic:symint:unsupported', ...
                      'Only products by a constant are integrated.');
            end
        case '^'
            if strcmp(e{2}{1}, 'var') && strcmp(e{2}{2}, variable) && strcmp(e{3}{1}, 'num')
                n = e{3}{2};
                if n == -1
                    primitive = symfun('log', e{2});
                else
                    primitive = symdiv(sympow(e{2}, symnum(n + 1)), symnum(n + 1));
                end
            else
                error('symbolic:symint:unsupported', 'Unsupported power.');
            end
        case 'sin'
            primitive = symmul(symnum(-1), symfun('cos', e{2}));
        case 'cos'
            primitive = symfun('sin', e{2});
        case 'exp'
            primitive = e;
        otherwise
            error('symbolic:symint:unsupported', 'Unsupported form ''%s''.', operateur);
    end
    primitive = symsimplify(primitive);
end
