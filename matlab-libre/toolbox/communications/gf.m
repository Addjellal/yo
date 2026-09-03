classdef gf
%GF Tableau d'éléments d'un corps de Galois.
%   X = GF(V) range les valeurs V dans GF(2) : chacune vaut zéro ou un.
%   X = GF(V,M) les range dans GF(2^M), les valeurs allant de 0 à 2^M-1.
%   X = GF(V,M,PRIM) emploie le polynôme primitif PRIM, donné comme
%   entier — sa forme binaire, poids fort en tête —, au lieu du défaut
%   de GFPRIMDF.
%
%   Les opérations ordinaires s'appliquent : +, -, .*, ./, .^, * et ^ y
%   travaillent dans le corps. L'addition y est le ou exclusif, si bien
%   qu'ajouter deux fois la même chose ne change rien ; la
%   multiplication passe par les logarithmes discrets.
%
%   Un tableau de corps ne se mélange pas à un autre d'ordre différent :
%   l'opération est refusée plutôt que faite dans le mauvais corps.
%
%   Exemple :
%      a = gf([1 2 3], 3);
%      a + a                          % tous nuls : la caractéristique
%                                     % vaut deux
%      a .* a                         % les carrés dans GF(8)
%      a ./ a                         % que des uns
%
%   Voir aussi GFTABLE, GFPRIMDF, BCHENC, RSENC, GFADD.
    properties
        x = 0
        m = 1
        prim_poly = 3
    end

    methods
        function obj = gf(v, m, prim)
            if nargin < 1, v = 0; end
            if nargin < 2 || isempty(m), m = 1; end
            obj.m = round(m);
            if obj.m < 1 || obj.m > 16
                error('comm:gf:Degre', ...
                      'L''extension doit aller de un à seize.');
            end
            if nargin < 3 || isempty(prim)
                obj.prim_poly = matlibre_gf_primitif(obj.m);
            else
                obj.prim_poly = round(double(prim));
            end
            v = round(double(v));
            if any(v(:) < 0) || any(v(:) >= 2 ^ obj.m)
                error('comm:gf:Valeur', ...
                      'Les valeurs doivent aller de 0 à %d.', 2 ^ obj.m - 1);
            end
            obj.x = v;
        end

        function r = plus(a, b)
            [a, b, m, prim] = matlibre_gf_paire(a, b);
            r = gf(bitxor(a, b), m, prim);
        end

        function r = minus(a, b)
            % Dans un corps de caractéristique deux, soustraire est
            % ajouter : le signe n'existe pas.
            r = plus(a, b);
        end

        function r = uminus(a)
            r = a;
        end

        function r = times(a, b)
            [a, b, m, prim] = matlibre_gf_paire(a, b);
            r = gf(matlibre_gf_mul(a, b, m, prim), m, prim);
        end

        function r = mtimes(a, b)
            if isscalarLike(a) || isscalarLike(b)
                r = times(a, b);
                return
            end
            [ga, gb, m, prim] = matlibre_gf_paire(a, b);
            if size(ga, 2) ~= size(gb, 1)
                error('comm:gf:Dimensions', ...
                      'Les dimensions intérieures doivent concorder.');
            end
            produit = zeros(size(ga, 1), size(gb, 2));
            for i = 1:size(ga, 1)
                for j = 1:size(gb, 2)
                    termes = matlibre_gf_mul(ga(i, :), gb(:, j).', m, prim);
                    accumulateur = 0;
                    for k = 1:numel(termes)
                        accumulateur = bitxor(accumulateur, termes(k));
                    end
                    produit(i, j) = accumulateur;
                end
            end
            r = gf(produit, m, prim);
        end

        function r = rdivide(a, b)
            [a, b, m, prim] = matlibre_gf_paire(a, b);
            r = gf(matlibre_gf_div(a, b, m, prim), m, prim);
        end

        function r = ldivide(a, b)
            r = rdivide(b, a);
        end

        function r = mrdivide(a, b)
            r = rdivide(a, b);
        end

        function r = power(a, n)
            if isa(n, 'gf')
                error('comm:gf:Exposant', ...
                      'L''exposant est un entier ordinaire, non un élément du corps.');
            end
            valeurs = matlibre_gf_valeurs(a);
            [valeurs, n] = matlibre_gf_etendre(valeurs, round(double(n)));
            r = gf(matlibre_gf_pow(valeurs, n, a.m, a.prim_poly), a.m, a.prim_poly);
        end

        function r = mpower(a, n)
            if numel(a.x) == 1
                r = power(a, n);
                return
            end
            n = round(double(n));
            if n < 0
                error('comm:gf:Puissance', ...
                      'Une puissance de matrice doit être positive.');
            end
            r = gf(eye(size(a.x, 1)) ~= 0, a.m, a.prim_poly);
            r = gf(double(eye(size(a.x, 1))), a.m, a.prim_poly);
            for k = 1:n
                r = r * a;
            end
        end

        function r = eq(a, b)
            [a, b] = matlibre_gf_paire(a, b);
            r = a == b;
        end

        function r = ne(a, b)
            r = ~eq(a, b);
        end

        function r = double(a)
            r = double(a.x);
        end

        function r = transpose(a)
            r = gf(a.x.', a.m, a.prim_poly);
        end

        function r = ctranspose(a)
            r = transpose(a);
        end

        function r = horzcat(varargin)
            [valeurs, m, prim] = matlibre_gf_concat(varargin, 2);
            r = gf(valeurs, m, prim);
        end

        function r = vertcat(varargin)
            [valeurs, m, prim] = matlibre_gf_concat(varargin, 1);
            r = gf(valeurs, m, prim);
        end

        function varargout = size(a, varargin)
            if nargout <= 1
                varargout{1} = size(a.x, varargin{:});
            else
                [varargout{1:nargout}] = size(a.x, varargin{:});
            end
        end

        function n = numel(a)
            n = numel(a.x);
        end

        function n = length(a)
            n = length(a.x);
        end

        function t = isempty(a)
            t = isempty(a.x);
        end

        function r = log(a)
            % Logarithme discret : l'exposant de l'élément primitif.
            valeurs = a.x;
            if any(valeurs(:) == 0)
                error('comm:gf:Log', 'Le logarithme de zéro n''existe pas.');
            end
            table = matlibre_gf_journal(a.m, a.prim_poly);
            r = table(valeurs + 1);
            r = reshape(r, size(valeurs));
        end

        function varargout = subsref(a, s)
            switch s(1).type
                case '()'
                    indices = s(1).subs;
                    varargout{1} = gf(a.x(indices{:}), a.m, a.prim_poly);
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'x',         varargout{1} = a.x;
                        case 'm',         varargout{1} = a.m;
                        case 'prim_poly', varargout{1} = a.prim_poly;
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                arguments_ = s(2).subs;
                                varargout{1} = feval(nom, a, arguments_{:});
                                return
                            end
                            varargout{1} = feval(nom, a);
                    end
                otherwise
                    error('comm:gf:Indexation', ...
                          'L''indexation par accolades n''a pas de sens ici.');
            end
        end

        function a = subsasgn(a, s, valeur)
            switch s(1).type
                case '()'
                    if isa(valeur, 'gf')
                        if valeur.m ~= a.m
                            error('comm:gf:Corps', ...
                                  'Les deux tableaux ne sont pas du même corps.');
                        end
                        valeur = valeur.x;
                    end
                    indices = s(1).subs;
                    a.x(indices{:}) = valeur;
                case '.'
                    a.(s(1).subs) = valeur;
                otherwise
                    error('comm:gf:Indexation', ...
                          'L''indexation par accolades n''a pas de sens ici.');
            end
        end

        function disp(a)
            fprintf('  tableau GF(2^%d), polynôme primitif %d\n', a.m, a.prim_poly);
            disp(a.x);
        end
    end
end

function t = isscalarLike(v)
    if isa(v, 'gf')
        t = numel(v.x) == 1;
    else
        t = numel(v) == 1;
    end
end
