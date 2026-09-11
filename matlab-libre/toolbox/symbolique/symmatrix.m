classdef symmatrix
%SYMMATRIX Matrice symbolique, manipulée comme un tout.
%   A = SYMMATRIX('A',[M N]) crée une matrice symbolique MxN nommée A.
%   A = SYMMATRIX(V) fait d'une matrice numérique ou symbolique une
%   constante matricielle.
%
%   Les opérations ordinaires — somme, produit, transposition, inverse,
%   déterminant, trace, puissance, produit de Kronecker — s'écrivent
%   sans développer les éléments : « A*B + C » reste « A*B + C ». C'est
%   ce qui distingue SYMMATRIX de SYM : on raisonne sur la matrice, non
%   sur ses coefficients, et une identité matricielle reste lisible.
%
%   SYMMATRIX2SYM développe l'expression en une matrice de SYM, où la
%   matrice nommée A donne les éléments A1_1, A1_2, ...
%
%   Les tailles sont vérifiées à la construction : une somme de formats
%   différents ou un produit mal accordé est refusé tout de suite.
%
%   Exemple :
%      A = symmatrix('A', [2 2]);
%      B = symmatrix('B', [2 2]);
%      char(A * B + A)                 % 'A*B + A'
%      size(A * B)                     % [2 2]
%      S = symmatrix2sym(A);
%      char(S(2, 1))                   % 'A2_1'
%
%   Voir aussi SYM, SYMMATRIX2SYM, SYMS, INV, DET, KRON.
    properties
        arbre = {'const', []}
    end

    methods
        function obj = symmatrix(valeur, dimensions)
            if nargin == 0
                return
            end
            if isa(valeur, 'symmatrix')
                obj.arbre = valeur.arbre;
                return
            end
            if iscell(valeur)
                obj.arbre = valeur;
                matlibre_symmat_taille(obj.arbre);
                return
            end
            if ischar(valeur) || isstring(valeur)
                if nargin < 2
                    dimensions = [1 1];
                end
                dimensions = double(dimensions);
                if numel(dimensions) == 1
                    dimensions = [dimensions dimensions];
                end
                if numel(dimensions) ~= 2 || any(dimensions < 0) || ...
                   any(dimensions ~= round(dimensions))
                    error('symbolic:symmatrix:Taille', ...
                          'La taille d''une matrice symbolique est [M N], entiers positifs.');
                end
                obj.arbre = {'mat', char(valeur), dimensions};
                return
            end
            if isnumeric(valeur) || islogical(valeur) || isa(valeur, 'sym')
                if isnumeric(valeur) || islogical(valeur)
                    valeur = double(valeur);
                end
                obj.arbre = {'const', valeur};
                return
            end
            error('symbolic:symmatrix:Valeur', ...
                  'SYMMATRIX prend un nom et une taille, ou une matrice.');
        end

        function r = plus(a, b),   r = composer('+', a, b);   end
        function r = minus(a, b),  r = composer('-', a, b);   end
        function r = mtimes(a, b), r = composer('*', a, b);   end
        function r = times(a, b),  r = composer('.*', a, b);  end
        function r = rdivide(a, b), r = composer('./', a, b); end

        function r = uminus(a)
            r = symmatrix({'neg', a.arbre});
        end

        function r = uplus(a), r = a; end

        function r = transpose(a)
            r = symmatrix({'trans', a.arbre});
        end

        function r = ctranspose(a)
            r = symmatrix({'trans', a.arbre});
        end

        function r = inv(a)
            r = symmatrix({'inv', a.arbre});
        end

        function r = det(a)
            r = symmatrix({'det', a.arbre});
        end

        function r = trace(a)
            r = symmatrix({'trace', a.arbre});
        end

        function r = kron(a, b)
            r = composer('kron', a, b);
        end

        function r = mpower(a, n)
            if ~isnumeric(n) || ~isscalar(n) || n ~= round(n)
                error('symbolic:symmatrix:Puissance', ...
                      'La puissance d''une matrice symbolique est un entier.');
            end
            r = symmatrix({'pow', a.arbre, double(n)});
        end

        function d = size(a, dimension)
            d = matlibre_symmat_taille(a.arbre);
            if nargin > 1
                d = d(dimension);
            end
        end

        function n = numel(a)
            d = matlibre_symmat_taille(a.arbre);
            n = d(1) * d(2);
        end

        function t = isempty(a)
            t = numel(a) == 0;
        end

        function texte = char(a)
            texte = matlibre_symmat_ecrire(a.arbre, 0);
        end

        function texte = string(a)
            texte = string(char(a));
        end

        function disp(a)
            d = size(a);
            fprintf('%s   (%dx%d)\n', char(a), d(1), d(2));
        end

        function M = symmatrix2sym(a)
        %SYMMATRIX2SYM Développe l'expression en matrice de SYM.
            M = matlibre_symmat_etendre(a.arbre);
        end

        function M = sym(a)
        %SYM Même chose que SYMMATRIX2SYM.
            M = matlibre_symmat_etendre(a.arbre);
        end
    end
end

function r = composer(operateur, a, b)
    r = symmatrix({operateur, versArbre(a), versArbre(b)});
end

function arbre = versArbre(v)
    if isa(v, 'symmatrix')
        arbre = v.arbre;
    else
        arbre = symmatrix(v).arbre;
    end
end
