function arbre = matlibre_sym_reecrire(arbre, cible)
%MATLIBRE_SYM_REECRIRE Remplace les fonctions d'un arbre par des équivalents.
%   Descend l'arbre et applique, à chaque nœud, l'identité qui exprime la
%   fonction rencontrée à l'aide de la cible demandée. Les identités sont
%   celles d'Euler et leurs conséquences, qui valent pour tout argument
%   complexe et pas seulement pour les réels.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      a = matlibre_sym_reecrire({'sin', {'var','x'}}, 'exp');
%      ~isempty(strfind(char(sym(a)), 'exp'))
%
%   Voir aussi REWRITE, SIMPLIFY.
    if numel(arbre) < 2 || any(strcmp(arbre{1}, {'num', 'var'}))
        return
    end
    for k = 2:numel(arbre)
        arbre{k} = matlibre_sym_reecrire(arbre{k}, cible);
    end
    u = [];
    if numel(arbre) == 2, u = arbre{2}; end
    switch cible
        case 'exp'
            % Les identites d'Euler : sin(u) = (e^{iu} - e^{-iu}) / 2i,
            % cos(u) = (e^{iu} + e^{-iu}) / 2.
            i1 = symnum(1i);
            switch arbre{1}
                case 'sin'
                    arbre = symdiv(symsub({'exp', symmul(i1, u)}, ...
                                          {'exp', symmul(symnum(-1i), u)}), ...
                                   symnum(2i));
                case 'cos'
                    arbre = symdiv(symadd({'exp', symmul(i1, u)}, ...
                                          {'exp', symmul(symnum(-1i), u)}), ...
                                   symnum(2));
                case 'tan'
                    arbre = symdiv(matlibre_sym_reecrire({'sin', u}, 'exp'), ...
                                   matlibre_sym_reecrire({'cos', u}, 'exp'));
                case 'sinh'
                    arbre = symdiv(symsub({'exp', u}, {'exp', symmul(symnum(-1), u)}), ...
                                   symnum(2));
                case 'cosh'
                    arbre = symdiv(symadd({'exp', u}, {'exp', symmul(symnum(-1), u)}), ...
                                   symnum(2));
                case 'tanh'
                    arbre = symdiv(matlibre_sym_reecrire({'sinh', u}, 'exp'), ...
                                   matlibre_sym_reecrire({'cosh', u}, 'exp'));
            end
        case 'sincos'
            if strcmp(arbre{1}, 'tan')
                arbre = symdiv({'sin', u}, {'cos', u});
            elseif strcmp(arbre{1}, 'tanh')
                arbre = symdiv({'sinh', u}, {'cosh', u});
            end
        case 'tan'
            % L'arc moitie : sin(u) = 2t/(1+t^2) et cos(u) = (1-t^2)/(1+t^2)
            % avec t = tan(u/2). C'est la substitution de Weierstrass, qui
            % rend rationnelle toute fraction trigonometrique.
            t = {'tan', symdiv(u, symnum(2))};
            carre = sympow(t, symnum(2));
            switch arbre{1}
                case 'sin'
                    arbre = symdiv(symmul(symnum(2), t), symadd(symnum(1), carre));
                case 'cos'
                    arbre = symdiv(symsub(symnum(1), carre), symadd(symnum(1), carre));
            end
        case 'log'
            un = symnum(1);
            switch arbre{1}
                case 'asin'
                    arbre = symmul(symnum(-1i), ...
                                   {'log', symadd(symmul(symnum(1i), u), ...
                                                  {'sqrt', symsub(un, sympow(u, symnum(2)))})});
                case 'atan'
                    arbre = symmul(symdiv(symnum(1i), symnum(2)), ...
                                   {'log', symdiv(symsub(un, symmul(symnum(1i), u)), ...
                                                  symadd(un, symmul(symnum(1i), u)))});
            end
        case 'sqrt'
            if strcmp(arbre{1}, '^') && strcmp(arbre{3}{1}, 'num') && arbre{3}{2} == 0.5
                arbre = {'sqrt', arbre{2}};
            end
    end
end
