function d = symdiff(e, variable)
%SYMDIFF Dérivée symbolique d'une expression.
%   D = SYMDIFF(E,'x') applique les règles usuelles : somme, produit,
%   quotient, puissance et composition des fonctions élémentaires.
%
%   Exemple :
%      x = sym('x');
%      symstr(symsimplify(symdiff(sympow(x, symnum(2)), 'x')))     % la derivee de x au carre
%
%   Voir aussi SYMINT, SYMSIMPLIFY, SYMSTR.
    e = matlibre_sym_arbre(e);
    operateur = e{1};
    switch operateur
        case 'num'
            d = symnum(0);
        case 'var'
            if strcmp(e{2}, variable)
                d = symnum(1);
            else
                d = symnum(0);
            end
        case '+'
            d = symadd(symdiff(e{2}, variable), symdiff(e{3}, variable));
        case '-'
            d = symsub(symdiff(e{2}, variable), symdiff(e{3}, variable));
        case '*'
            d = symadd(symmul(symdiff(e{2}, variable), e{3}), ...
                       symmul(e{2}, symdiff(e{3}, variable)));
        case '/'
            numerateur = symsub(symmul(symdiff(e{2}, variable), e{3}), ...
                                symmul(e{2}, symdiff(e{3}, variable)));
            d = symdiv(numerateur, sympow(e{3}, symnum(2)));
        case '^'
            if strcmp(e{3}{1}, 'num')
                n = e{3}{2};
                d = symmul(symmul(symnum(n), sympow(e{2}, symnum(n - 1))), ...
                           symdiff(e{2}, variable));
            else
                % (u^v)' = u^v (v' ln u + v u'/u)
                terme1 = symmul(symdiff(e{3}, variable), symfun('log', e{2}));
                terme2 = symdiv(symmul(e{3}, symdiff(e{2}, variable)), e{2});
                d = symmul(e, symadd(terme1, terme2));
            end
        case 'sin'
            d = symmul(symfun('cos', e{2}), symdiff(e{2}, variable));
        case 'cos'
            d = symmul(symmul(symnum(-1), symfun('sin', e{2})), symdiff(e{2}, variable));
        case 'tan'
            d = symdiv(symdiff(e{2}, variable), sympow(symfun('cos', e{2}), symnum(2)));
        case 'exp'
            d = symmul(e, symdiff(e{2}, variable));
        case 'log'
            d = symdiv(symdiff(e{2}, variable), e{2});
        case 'sqrt'
            d = symdiv(symdiff(e{2}, variable), symmul(symnum(2), e));
        % Les hyperboliques et les fonctions reciproques, par la chaine :
        % chacune derive en une expression de son argument, multipliee par
        % la derivee de cet argument.
        case 'sinh'
            d = symmul({'cosh', e{2}}, symdiff(e{2}, variable));
        case 'cosh'
            d = symmul({'sinh', e{2}}, symdiff(e{2}, variable));
        case 'tanh'
            % 1 - tanh(u)^2
            d = symmul(symsub(symnum(1), sympow({'tanh', e{2}}, symnum(2))), ...
                       symdiff(e{2}, variable));
        case 'asin'
            d = symdiv(symdiff(e{2}, variable), ...
                       {'sqrt', symsub(symnum(1), sympow(e{2}, symnum(2)))});
        case 'acos'
            % Le signe va au numerateur : « -1/sqrt(...) » se lit, là où
            % « -1*1/sqrt(...) » fait deviner ce qui multiplie quoi.
            d = symdiv(symmul(symnum(-1), symdiff(e{2}, variable)), ...
                       {'sqrt', symsub(symnum(1), sympow(e{2}, symnum(2)))});
        case 'atan'
            d = symdiv(symdiff(e{2}, variable), ...
                       symadd(symnum(1), sympow(e{2}, symnum(2))));
        case 'log2'
            d = symdiv(symdiff(e{2}, variable), symmul(e{2}, {'log', symnum(2)}));
        case 'log10'
            d = symdiv(symdiff(e{2}, variable), symmul(e{2}, {'log', symnum(10)}));
        otherwise
            error('symbolic:symdiff:unknown', 'Unknown operator ''%s''.', operateur);
    end
    d = symsimplify(d);
end
