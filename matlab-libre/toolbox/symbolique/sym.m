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
            if (isnumeric(valeur) || islogical(valeur)) && ~isscalar(valeur)
                % Un tableau numérique devient un tableau de SYM, élément
                % par élément, comme sym([1 2; 3 4]) dans MATLAB.
                obj = repmat(sym(0), size(valeur));
                for k = 1:numel(valeur)
                    obj(k) = sym(valeur(k));
                end
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
            elseif (isnumeric(valeur) || islogical(valeur)) && isscalar(valeur)
                obj.arbre = {'num', double(valeur)};
            else
                error('symbolic:sym:Valeur', ...
                      'SYM prend un nom, un nombre ou un arbre d''expression.');
            end
        end

        % Les opérations élément par élément : un scalaire s'étend à la
        % taille de l'autre opérande, deux tableaux doivent être de même
        % taille.
        function r = plus(a, b),    r = operer(@symadd, a, b);  end
        function r = minus(a, b),   r = operer(@symsub, a, b);  end
        function r = times(a, b),   r = operer(@symmul, a, b);  end
        function r = rdivide(a, b), r = operer(@symdiv, a, b);  end
        function r = ldivide(a, b), r = operer(@symdiv, b, a);  end
        function r = power(a, b),   r = operer(@sympow, a, b);  end

        function r = uminus(a)
            r = operer(@symmul, -1, a);
        end

        function r = uplus(a)
            r = a;
        end

        function r = mtimes(a, b)
        %MTIMES Produit matriciel ; par un scalaire, produit élément par élément.
            if isscalar(a) || isscalar(b)
                r = operer(@symmul, a, b);
                return
            end
            if ~ismatrix(a) || ~ismatrix(b) || size(a, 2) ~= size(b, 1)
                error('MATLAB:innerdim', ...
                      'Incorrect dimensions for matrix multiplication.');
            end
            r = repmat(sym(0), size(a, 1), size(b, 2));
            for i = 1:size(a, 1)
                for j = 1:size(b, 2)
                    somme = symnum(0);
                    for k = 1:size(a, 2)
                        somme = symadd(somme, symmul(arbreDe(a, i + (k - 1) * size(a, 1)), ...
                                                      arbreDe(b, k + (j - 1) * size(b, 1))));
                    end
                    r(i, j) = sym(symsimplify(somme));
                end
            end
        end

        function r = mrdivide(a, b)
            if ~isscalar(b)
                error('symbolic:mrdivide:Matrice', ...
                      ['La division à droite par une matrice SYM n''est pas faite ; ', ...
                       'seule la division par un scalaire l''est.']);
            end
            r = rdivide(a, b);
        end

        function r = mpower(a, b)
            if ~isscalar(a) || ~isscalar(b)
                error('symbolic:mpower:Matrice', ...
                      ['La puissance matricielle d''un SYM n''est pas faite ; ', ...
                       'employez .^ pour la puissance élément par élément.']);
            end
            r = power(a, b);
        end

        function r = eq(a, b)
            % Une égalité symbolique est une équation : SOLVE la résout.
            r = operer(@(u, v) {'-', u, v}, a, b);
        end

        function r = sin(a),   r = matlibre_sym_appliquer('sin', a);   end
        function r = cos(a),   r = matlibre_sym_appliquer('cos', a);   end
        function r = tan(a),   r = matlibre_sym_appliquer('tan', a);   end
        function r = exp(a),   r = matlibre_sym_appliquer('exp', a);   end
        function r = log(a),   r = matlibre_sym_appliquer('log', a);   end
        function r = sqrt(a),  r = matlibre_sym_appliquer('sqrt', a);  end
        function r = sinh(a),  r = matlibre_sym_appliquer('sinh', a);  end
        function r = cosh(a),  r = matlibre_sym_appliquer('cosh', a);  end
        function r = tanh(a),  r = matlibre_sym_appliquer('tanh', a);  end
        function r = asin(a),  r = matlibre_sym_appliquer('asin', a);  end
        function r = acos(a),  r = matlibre_sym_appliquer('acos', a);  end
        function r = atan(a),  r = matlibre_sym_appliquer('atan', a);  end
        function r = abs(a),   r = matlibre_sym_appliquer('abs', a);   end
        function r = log2(a),  r = matlibre_sym_appliquer('log2', a);  end
        function r = log10(a), r = matlibre_sym_appliquer('log10', a); end
        function r = erf(a),   r = matlibre_sym_appliquer('erf', a);   end
        function r = erfc(a),  r = matlibre_sym_appliquer('erfc', a);  end
        function r = sign(a),  r = matlibre_sym_appliquer('sign', a);  end

        function texte = char(a)
        %CHAR Le texte de l'expression ; '[a, b; c, d]' pour un tableau.
            if isscalar(a)
                texte = symstr(a.arbre);
                return
            end
            lignes = cell(1, size(a, 1));
            for i = 1:size(a, 1)
                elements = cell(1, size(a, 2));
                for j = 1:size(a, 2)
                    elements{j} = symstr(arbreDe(a, i + (j - 1) * size(a, 1)));
                end
                lignes{i} = strjoin(elements, ', ');
            end
            texte = ['[' strjoin(lignes, '; ') ']'];
        end

        function texte = string(a)
            texte = strings(size(a));
            for k = 1:numel(a)
                texte(k) = string(symstr(arbreDe(a, k)));
            end
        end

        function disp(a)
        %DISP Un scalaire sur une ligne ; un vecteur colonne un élément par
        %   ligne, alignés à droite ; une matrice une ligne entre crochets
        %   par ligne, les colonnes alignées.
            if isscalar(a)
                fprintf('%s\n', symstr(a.arbre));
                return
            end
            if isempty(a)
                fprintf('Empty sym: %d-by-%d\n', size(a, 1), size(a, 2));
                return
            end
            textes = cell(size(a));
            for k = 1:numel(a)
                textes{k} = symstr(arbreDe(a, k));
            end
            if size(a, 2) == 1
                largeur = max(cellfun(@numel, textes));
                for i = 1:numel(textes)
                    fprintf(' %*s\n', largeur, textes{i});
                end
                return
            end
            largeurs = max(cellfun(@numel, textes), [], 1);
            for i = 1:size(a, 1)
                morceaux = cell(1, size(a, 2));
                for j = 1:size(a, 2)
                    morceaux{j} = sprintf('%*s', largeurs(j), textes{i, j});
                end
                fprintf('[%s]\n', strjoin(morceaux, ', '));
            end
        end

        function r = double(a)
            r = zeros(size(a));
            for k = 1:numel(a)
                r(k) = symeval(arbreDe(a, k));
            end
        end

        function r = isnumeric(a)   %#ok<MANU>
            r = false;
        end

        function d = diff(f, varargin)
        %DIFF Dérivée d'une expression symbolique.
        %   DIFF(F) dérive par rapport à la variable la plus proche de x.
        %   DIFF(F,X) nomme la variable, DIFF(F,X,N) dérive N fois. Un
        %   tableau est dérivé élément par élément.
            if ~isscalar(f)
                d = parElement(f, @(e) diff(e, varargin{:}));
                return
            end
            variable = [];
            ordre = [];
            if numel(varargin) >= 1, variable = varargin{1}; end
            if numel(varargin) >= 2, ordre = varargin{2}; end
            if isempty(variable)
                variable = matlibre_sym_defaut(f);
            end
            if isempty(ordre)
                if isnumeric(variable)
                    % DIFF(F,N) : l'ordre passé à la place de la variable.
                    ordre = round(variable);
                    variable = matlibre_sym_defaut(f);
                else
                    ordre = 1;
                end
            end
            nom = matlibre_sym_nom(variable);
            arbre = f.arbre;
            for k = 1:ordre
                arbre = symdiff(arbre, nom);
            end
            d = sym(matlibre_sym_reduire(arbre));
        end

        function r = int(f, varargin)
        %INT Primitive ou intégrale définie d'une expression symbolique.
        %   INT(F) et INT(F,X) rendent une primitive ; INT(F,A,B) et
        %   INT(F,X,A,B) l'intégrale entre A et B, par la primitive. Une
        %   borne infinie est atteinte par passage à la limite.
        %
        %   Une intégrale définie entre bornes numériques est recoupée par
        %   INTEGRAL : une primitive discontinue sur l'intervalle — 1/x^2
        %   entre -1 et 1 — donnerait sans cela un nombre faux, et INT le
        %   refuse au lieu de le rendre.
            if ~isscalar(f)
                r = parElement(f, @(e) int(e, varargin{:}));
                return
            end
            switch numel(varargin)
                case 0
                    variable = matlibre_sym_defaut(f);
                    bornes = {};
                case 1
                    variable = varargin{1};
                    bornes = {};
                case 2
                    variable = matlibre_sym_defaut(f);
                    bornes = varargin;
                case 3
                    variable = varargin{1};
                    bornes = varargin(2:3);
                otherwise
                    error('MATLAB:TooManyInputs', 'Too many input arguments.');
            end
            if isempty(variable)
                variable = matlibre_sym_defaut(f);
            end
            nom = matlibre_sym_nom(variable);
            primitive = symint(f.arbre, nom);
            if isempty(bornes)
                r = sym(matlibre_sym_reduire(primitive));
                return
            end
            valeurs = cell(1, 2);
            for k = 1:2
                borne = matlibre_sym_arbre(bornes{k});
                if strcmp(borne{1}, 'num') && isinf(borne{2})
                    valeurs{k} = symnum(matlibre_sym_limite(primitive, nom, borne{2}, 'both'));
                else
                    valeurs{k} = symsubs(primitive, nom, borne);
                end
            end
            arbre = matlibre_sym_reduire(symsub(valeurs{2}, valeurs{1}));
            if isempty(matlibre_sym_noms(arbre))
                % Plus aucune variable : atan(1) - atan(0) est un nombre.
                arbre = symnum(symeval(arbre));
            end
            r = sym(arbre);
            verifierIntegrale(f.arbre, nom, bornes, r);
        end

        function r = subs(f, ancienne, nouvelle)
        %SUBS Substitution dans une expression symbolique.
        %   SUBS(F,X,V) remplace la variable X par V, nombre ou
        %   expression. X et V peuvent être des cellules de même
        %   longueur : les substitutions se font alors ensemble. Un
        %   tableau numérique V donne un tableau de résultats, un par
        %   valeur.
            if nargin < 3
                error('MATLAB:minrhs', 'Not enough input arguments.');
            end
            if ~isscalar(f)
                r = parElement(f, @(e) subs(e, ancienne, nouvelle));
                return
            end
            if ~iscell(ancienne) && (isnumeric(nouvelle) || isa(nouvelle, 'sym')) && ...
                    ~isscalar(nouvelle)
                r = repmat(sym(0), size(nouvelle));
                for k = 1:numel(nouvelle)
                    r(k) = subs(f, ancienne, nouvelle(k));
                end
                return
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
            r = sym(matlibre_sym_reduire(arbre));
        end

        function r = simplify(f)
        %SIMPLIFY Simplification d'une expression symbolique.
        %   Les cas triviaux — zéro, un, constantes réunies — sont
        %   réduits, et les termes semblables regroupés quand
        %   l'expression est polynomiale en une variable.
            if ~isscalar(f)
                r = parElement(f, @simplify);
                return
            end
            r = sym(matlibre_sym_reduire(f.arbre));
        end

        function r = expand(f)
        %EXPAND Développement d'une expression symbolique.
        %   Les produits sont distribués sur les sommes, et les
        %   puissances entières positives développées.
            if ~isscalar(f)
                r = parElement(f, @expand);
                return
            end
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

        function r = factor(f, variable)
        %FACTOR Factorisation d'un polynôme symbolique.
        %   FACTOR(F) écrit F comme un produit : le contenu entier, les
        %   facteurs (x - r) de ses racines rationnelles, et ce qui
        %   reste. FACTOR(F,X) nomme la variable.
        %
        %   Les racines rationnelles sont trouvées exactement, par le
        %   théorème qui porte leur nom : si p/q est racine d'un
        %   polynôme entier, p divise le terme constant et q le
        %   coefficient dominant. L'ensemble à essayer est donc fini, et
        %   une racine non trouvée n'existe pas.
        %
        %   Ce qui reste après les avoir divisées n'est pas
        %   nécessairement irréductible : x^4 + 1 n'a aucune racine
        %   rationnelle et se factorise pourtant sur les rationnels. Le
        %   trouver demanderait autre chose, et FACTOR le laisse tel
        %   quel plutôt que de prétendre avoir fini.
        %
        %   Le produit des facteurs rendus vaut toujours F : c'est ce
        %   qu'on peut vérifier, et c'est ce que les tests vérifient.
            if nargin < 2 || isempty(variable)
                variable = matlibre_sym_defaut(f);
            end
            nom = matlibre_sym_nom(variable);
            coefficients = matlibre_sym_coefficients(...
                matlibre_sym_developper(f.arbre), nom);
            [contenu, racines, reste] = matlibre_sym_facteurs(coefficients);
            % Une racine p/q donne le facteur entier (q*x - p), non
            % (x - 0.333...) : le q sort du contenu, ce qui garde des
            % coefficients entiers partout et rend la factorisation
            % lisible autant qu'exacte.
            facteurs = {};
            for k = 1:numel(racines)
                [p, q] = matlibre_sym_fraction(racines(k));
                if q ~= 1
                    contenu = contenu / q;
                end
                if q == 1
                    gaucheFacteur = {'var', nom};
                else
                    gaucheFacteur = symmul(symnum(q), {'var', nom});
                end
                if p == 0
                    facteurs{end + 1} = gaucheFacteur;   %#ok<AGROW>
                elseif p > 0
                    facteurs{end + 1} = symsub(gaucheFacteur, symnum(p));   %#ok<AGROW>
                else
                    facteurs{end + 1} = symadd(gaucheFacteur, symnum(-p));  %#ok<AGROW>
                end
            end
            % Ce qui reste apres les racines, quand c'est un nombre, va
            % dans le contenu : sans cela on ecrirait « 1/6*(3x-1)*(2x-1)*6 »
            % la ou « (3x-1)*(2x-1) » dit la meme chose.
            if numel(reste) == 1
                contenu = contenu * reste;
                reste = 1;
            end
            contenu = arrondirProche(contenu);
            % Le contenu ne s'ecrit que s'il vaut autre chose qu'un : un
            % facteur un n'apporte rien et alourdit la lecture.
            arbre = [];
            if contenu ~= 1
                arbre = symnum(contenu);
            end
            for k = 1:numel(facteurs)
                if isempty(arbre)
                    arbre = facteurs{k};
                else
                    arbre = symmul(arbre, facteurs{k});
                end
            end
            if numel(reste) > 1
                facteur = matlibre_sym_polynome(reste, nom);
                if isempty(arbre)
                    arbre = facteur;
                else
                    arbre = symmul(arbre, facteur);
                end
            end
            if isempty(arbre)
                arbre = symnum(contenu);
            end
            r = sym(arbre);
        end

        function racines = solve(equation, variable)
        %SOLVE Résolution d'une équation polynomiale.
        %   SOLVE(F) résout F = 0 ; SOLVE(F,X) nomme l'inconnue. Les
        %   racines sont rendues en colonne de SYM, comme dans MATLAB,
        %   triées ; une racine multiple apparaît autant de fois que sa
        %   multiplicité.
            if nargin < 2 || isempty(variable)
                variable = matlibre_sym_defaut(equation);
            end
            nom = matlibre_sym_nom(variable);
            coefficients = matlibre_sym_coefficients(equation.arbre, nom);
            if numel(coefficients) < 2
                error('symbolic:solve:Constante', ...
                      'L''équation ne dépend pas de %s.', nom);
            end
            % Les racines rationnelles d'un polynôme entier sont trouvées
            % exactement — le théorème des racines rationnelles, comme pour
            % FACTOR — : 4 est racine de x^3 - 15x - 4, non 3.9999999999999982.
            % Le reste, dégonflé de ces racines, va à ROOTS.
            [~, exactes, reste] = matlibre_sym_facteurs(coefficients);
            if numel(reste) > 1
                autres = roots(reste);
            else
                autres = zeros(0, 1);
            end
            % Les racines quasi réelles le sont : l'arrondi ne doit pas
            % faire croire à une partie imaginaire.
            proches = abs(imag(autres)) < 1e-10 * max(abs(autres), 1);
            autres(proches) = real(autres(proches));
            valeurs = sort([exactes(:); autres(:)]);
            racines = repmat(sym(0), numel(valeurs), 1);
            for k = 1:numel(valeurs)
                racines(k) = sym(valeurs(k));
            end
        end
    end
end

function r = operer(fonction, a, b)
%OPERER Une opération entre deux opérandes, élément par élément.
    na = numel(a);
    nb = numel(b);
    if na == 1 && nb == 1
        r = sym(symsimplify(fonction(arbreDe(a, 1), arbreDe(b, 1))));
        return
    end
    if na == 1
        forme = size(b);
    elseif nb == 1 || isequal(size(a), size(b))
        forme = size(a);
    else
        error('MATLAB:sizeDimensionsMustMatch', ...
              'Arrays have incompatible sizes for this operation.');
    end
    r = repmat(sym(0), forme);
    for k = 1:prod(forme)
        r(k) = sym(symsimplify(fonction(arbreDe(a, min(k, na)), arbreDe(b, min(k, nb)))));
    end
end

function e = arbreDe(a, k)
%ARBREDE L'arbre du k-ième élément d'un SYM ou d'un tableau numérique.
    if isa(a, 'sym')
        element = a(k);
        e = element.arbre;
    else
        e = matlibre_sym_arbre(a(k));
    end
end

function r = parElement(f, fonction)
%PARELEMENT Une fonction appliquée à chaque élément d'un tableau de SYM.
    r = repmat(sym(0), size(f));
    for k = 1:numel(f)
        r(k) = fonction(f(k));
    end
end

function verifierIntegrale(arbre, nom, bornes, resultat)
%VERIFIERINTEGRALE Recoupe une intégrale définie par INTEGRAL.
%   Le contrôle ne vaut que pour un intégrande sans autre variable et des
%   bornes numériques. Un désaccord — primitive discontinue sur
%   l'intervalle, intégrale divergente — est une erreur : rendre le
%   nombre tiré de la primitive serait rendre un résultat faux.
    autres = setdiff(unique(matlibre_sym_noms(arbre)), {nom});
    if ~isempty(autres)
        return
    end
    try
        a = double(matlibre_sym_valeur(bornes{1}));
        b = double(matlibre_sym_valeur(bornes{2}));
        valeur = double(resultat);
    catch
        return
    end
    if ~isfinite(valeur) || isnan(a) || isnan(b) || a == b
        return
    end
    f = @(t) arrayfun(@(u) symeval(symsubs(arbre, nom, symnum(u))), t);
    etat = warning('off', 'all');
    try
        numerique = integral(f, a, b, 'RelTol', 1e-8, 'AbsTol', 1e-12);
    catch
        numerique = NaN;
    end
    warning(etat);
    if ~(abs(numerique - valeur) <= 1e-6 * max(1, abs(valeur)))
        error('symbolic:int:Verification', ...
              ['INT : la primitive donne %.15g, l''intégration numérique %.15g. ', ...
               'L''intégrande a sans doute une singularité sur l''intervalle, ', ...
               'ou l''intégrale diverge.'], valeur, numerique);
    end
end

function v = arrondirProche(x)
% Les divisions successives laissent un residu d'arrondi : un contenu qui
% vaut 2 a 1e-16 pres doit s'ecrire 2, non 1.9999999999999998.
    if abs(x - round(x)) < 1e-9 * max(1, abs(x))
        v = round(x);
    else
        v = x;
    end
end
