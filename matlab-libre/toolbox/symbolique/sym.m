classdef sym
%SYM Expression symbolique.
%   X = SYM('x') crée la variable symbolique x.
%   A = SYM(3) crée la constante 3.
%   Les opérateurs ordinaires construisent alors des expressions :
%   X^2 + 3*X - 1 en est une, et DIFF, INT, SUBS, SIMPLIFY et SOLVE les
%   manipulent.
%
%   Un calcul symbolique diffère d'un calcul numérique en ce qu'il garde
%   la forme : la dérivée de sin(x) est cos(x), non une suite de valeurs.
%   C'est ce qui permet de simplifier, de résoudre, ou de relire.
%
%   L'expression est un arbre — opérateur puis sous-expressions — rangé
%   dans la propriété « arbre » ; les fonctions SYMADD, SYMDIFF et leurs
%   voisines travaillent directement dessus, quand on préfère l'arbre à
%   l'objet.
%
%   Exemple :
%      x = sym('x');
%      f = x ^ 3 - 2 * x;
%      diff(f)                        % 3*x^2 - 2
%      double(subs(f, x, 2))          % 4
%      solve(x ^ 2 - 4)               % -2 et 2
%
%   Voir aussi SYMS, DIFF, INT, SUBS, SIMPLIFY, SOLVE, DOUBLE.
    properties
        arbre = {'num', 0}
    end

    methods
        function obj = sym(valeur)
            if nargin < 1
                obj.arbre = {'num', 0};
                return
            end
            if isa(valeur, 'sym')
                obj.arbre = valeur.arbre;
            elseif iscell(valeur)
                obj.arbre = valeur;
            elseif ischar(valeur) || isstring(valeur)
                texte = char(valeur);
                nombre = str2double(texte);
                if ~isnan(nombre) && ~isempty(regexp(texte, '^[-+]?[0-9.eE+-]+$', 'once'))
                    obj.arbre = {'num', nombre};
                else
                    obj.arbre = {'var', texte};
                end
            elseif isnumeric(valeur) && isscalar(valeur)
                obj.arbre = {'num', double(valeur)};
            else
                error('symbolic:sym:Valeur', ...
                      'SYM prend un nom, un nombre ou un arbre d''expression.');
            end
        end

        function r = plus(a, b)
            r = sym(symsimplify(symadd(matlibre_sym_arbre(a), matlibre_sym_arbre(b))));
        end

        function r = minus(a, b)
            r = sym(symsimplify(symsub(matlibre_sym_arbre(a), matlibre_sym_arbre(b))));
        end

        function r = uminus(a)
            r = sym(symsimplify(symmul(symnum(-1), matlibre_sym_arbre(a))));
        end

        function r = uplus(a)
            r = sym(matlibre_sym_arbre(a));
        end

        function r = times(a, b)
            r = sym(symsimplify(symmul(matlibre_sym_arbre(a), matlibre_sym_arbre(b))));
        end

        function r = mtimes(a, b)
            r = times(a, b);
        end

        function r = rdivide(a, b)
            r = sym(symsimplify(symdiv(matlibre_sym_arbre(a), matlibre_sym_arbre(b))));
        end

        function r = mrdivide(a, b)
            r = rdivide(a, b);
        end

        function r = ldivide(a, b)
            r = rdivide(b, a);
        end

        function r = power(a, b)
            r = sym(symsimplify(sympow(matlibre_sym_arbre(a), matlibre_sym_arbre(b))));
        end

        function r = mpower(a, b)
            r = power(a, b);
        end

        function r = eq(a, b)
            % Une égalité symbolique est une équation : SOLVE la résout.
            r = sym(symsub(matlibre_sym_arbre(a), matlibre_sym_arbre(b)));
        end

        function r = sin(a),  r = matlibre_sym_appliquer('sin', a);  end
        function r = cos(a),  r = matlibre_sym_appliquer('cos', a);  end
        function r = tan(a),  r = matlibre_sym_appliquer('tan', a);  end
        function r = exp(a),  r = matlibre_sym_appliquer('exp', a);  end
        function r = log(a),  r = matlibre_sym_appliquer('log', a);  end
        function r = sqrt(a), r = matlibre_sym_appliquer('sqrt', a); end

        function texte = char(a)
            texte = symstr(a.arbre);
        end

        function texte = string(a)
            texte = string(symstr(a.arbre));
        end

        function disp(a)
            fprintf('%s\n', symstr(a.arbre));
        end

        function r = double(a)
            r = symeval(a.arbre);
        end

        function r = isnumeric(a)   %#ok<MANU>
            r = false;
        end

        function d = diff(f, variable, ordre)
        %DIFF Dérivée d'une expression symbolique.
        %   DIFF(F) dérive par rapport à la variable la plus proche de x.
        %   DIFF(F,X) nomme la variable, DIFF(F,X,N) dérive N fois.
            if nargin < 2 || isempty(variable)
                variable = matlibre_sym_defaut(f);
            end
            nom = matlibre_sym_nom(variable);
            if nargin < 3 || isempty(ordre)
                if isnumeric(variable)
                    % DIFF(F,N) : l'ordre passé à la place de la variable.
                    ordre = round(variable);
                    nom = matlibre_sym_defaut(f);
                else
                    ordre = 1;
                end
            end
            arbre = f.arbre;
            for k = 1:ordre
                arbre = symdiff(arbre, nom);
            end
            d = sym(matlibre_sym_reduire(arbre));
        end

        function r = int(f, variable, bas, haut)
        %INT Primitive ou intégrale définie d'une expression symbolique.
        %   INT(F) et INT(F,X) rendent une primitive ; INT(F,A,B) et
        %   INT(F,X,A,B) l'intégrale entre A et B, par la primitive.
            if nargin < 2 || isempty(variable)
                variable = matlibre_sym_defaut(f);
            end
            if nargin == 3
                error('symbolic:int:Bornes', ...
                      'Une intégrale définie demande les deux bornes.');
            end
            if nargin >= 4
                nom = matlibre_sym_nom(variable);
            elseif isnumeric(variable) || isa(variable, 'sym')
                nom = matlibre_sym_nom(variable);
            else
                nom = matlibre_sym_nom(variable);
            end
            primitive = symint(f.arbre, nom);
            if nargin < 4
                r = sym(matlibre_sym_reduire(primitive));
                return
            end
            enHaut = symsubs(primitive, nom, matlibre_sym_arbre(haut));
            enBas = symsubs(primitive, nom, matlibre_sym_arbre(bas));
            r = sym(matlibre_sym_reduire(symsub(enHaut, enBas)));
        end

        function r = subs(f, ancienne, nouvelle)
        %SUBS Substitution dans une expression symbolique.
        %   SUBS(F,X,V) remplace la variable X par V, nombre ou
        %   expression. X et V peuvent être des cellules de même
        %   longueur : les substitutions se font alors ensemble.
            if nargin < 3
                error('MATLAB:minrhs', 'Not enough input arguments.');
            end
            if ~iscell(ancienne)
                ancienne = {ancienne};
                nouvelle = {nouvelle};
            end
            arbre = f.arbre;
            for k = 1:numel(ancienne)
                arbre = symsubs(arbre, matlibre_sym_nom(ancienne{k}), ...
                                matlibre_sym_arbre(nouvelle{k}));
            end
            r = sym(arbre);
        end

        function r = simplify(f)
        %SIMPLIFY Simplification d'une expression symbolique.
        %   Les cas triviaux — zéro, un, constantes réunies — sont
        %   réduits, et les termes semblables regroupés quand
        %   l'expression est polynomiale en une variable.
            r = sym(matlibre_sym_reduire(f.arbre));
        end

        function r = expand(f)
        %EXPAND Développement d'une expression symbolique.
        %   Les produits sont distribués sur les sommes, et les
        %   puissances entières positives développées.
            r = sym(matlibre_sym_reduire(matlibre_sym_developper(f.arbre)));
        end

        function coefficients = sym2poly(f, variable)
        %SYM2POLY Coefficients d'une expression polynomiale.
        %   Les coefficients sont rendus par puissances décroissantes,
        %   comme POLYVAL les attend.
            if nargin < 2 || isempty(variable)
                variable = matlibre_sym_defaut(f);
            end
            coefficients = matlibre_sym_coefficients(f.arbre, matlibre_sym_nom(variable));
        end

        function racines = solve(equation, variable)
        %SOLVE Résolution d'une équation polynomiale.
        %   SOLVE(F) résout F = 0 ; SOLVE(F,X) nomme l'inconnue.
            if nargin < 2 || isempty(variable)
                variable = matlibre_sym_defaut(equation);
            end
            nom = matlibre_sym_nom(variable);
            coefficients = matlibre_sym_coefficients(equation.arbre, nom);
            if numel(coefficients) < 2
                error('symbolic:solve:Constante', ...
                      'L''équation ne dépend pas de %s.', nom);
            end
            valeurs = roots(coefficients);
            % Les racines quasi réelles le sont : l'arrondi ne doit pas
            % faire croire à une partie imaginaire.
            proches = abs(imag(valeurs)) < 1e-10 * max(abs(valeurs), 1);
            valeurs(proches) = real(valeurs(proches));
            valeurs = sort(valeurs);
            racines = cell(numel(valeurs), 1);
            for k = 1:numel(valeurs)
                racines{k} = sym(valeurs(k));
            end
            if numel(racines) == 1
                racines = racines{1};
            end
        end
    end
end
