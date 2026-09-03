classdef optimvar
%OPTIMVAR Variable d'un problème d'optimisation.
%   X = OPTIMVAR('x') crée une variable scalaire nommée x.
%   X = OPTIMVAR('x',N) crée un vecteur de N variables.
%   X = OPTIMVAR('x',N,'LowerBound',0,'UpperBound',10) les borne.
%   X = OPTIMVAR('x',N,'Type','integer') les rend entières.
%
%   Une variable ne porte aucune valeur : elle sert à écrire le problème.
%   Les opérateurs +, -, * et SUM fabriquent des expressions, et les
%   comparaisons des contraintes. C'est l'écriture « par problème » de
%   MATLAB, où l'on décrit ce qu'on veut au lieu d'assembler des
%   matrices.
%
%   Exemple :
%      x = optimvar('x', 2, 'LowerBound', 0);
%      prob = optimproblem('Objective', -x(1) - 2*x(2));
%      prob.Constraints.c = x(1) + x(2) <= 4;
%      sol = solve(prob);
%
%   Voir aussi OPTIMPROBLEM, OPTIMEXPR, SOLVE, PROB2STRUCT, LINPROG.
    properties
        Name = ''
        Size = [1 1]
        LowerBound = -Inf
        UpperBound = Inf
        Type = 'continuous'
        % Les composantes retenues, quand la variable a été indexée.
        Indices = []
    end
    methods
        function v = optimvar(nom, varargin)
            if nargin == 0
                return
            end
            v.Name = char(nom);
            if ~isvarname(v.Name)
                error('optim:optimvar:Nom', ...
                      'Le nom d''une variable doit être un nom valide.');
            end
            dimensions = [];
            k = 1;
            while k <= numel(varargin)
                a = varargin{k};
                if isnumeric(a)
                    dimensions(end + 1) = round(a);   %#ok<AGROW>
                    k = k + 1;
                    continue
                end
                if k + 1 > numel(varargin)
                    error('optim:optimvar:Paire', 'Option sans valeur.');
                end
                switch lower(char(a))
                    case 'lowerbound', v.LowerBound = double(varargin{k+1});
                    case 'upperbound', v.UpperBound = double(varargin{k+1});
                    case 'type',       v.Type = lower(char(varargin{k+1}));
                    otherwise
                        error('optim:optimvar:Option', ...
                              'Option inconnue : %s.', char(a));
                end
                k = k + 2;
            end
            if isempty(dimensions)
                v.Size = [1 1];
            elseif numel(dimensions) == 1
                v.Size = [dimensions 1];
            else
                v.Size = dimensions(1:2);
            end
            n = prod(v.Size);
            v.LowerBound = etendreBorne(v.LowerBound, n);
            v.UpperBound = etendreBorne(v.UpperBound, n);
            v.Indices = (1:n).';
        end

        function n = numel(v)
            n = numel(v.Indices);
        end

        function s = size(v, dimension)
            s = v.Size;
            if nargin > 1
                if dimension <= numel(s)
                    s = s(dimension);
                else
                    s = 1;
                end
            end
        end

        function e = plus(a, b),   e = plus(optimexpr.depuis(a), b); end
        function e = minus(a, b),  e = minus(optimexpr.depuis(a), b); end
        function e = uminus(a),    e = uminus(optimexpr.depuis(a)); end
        function e = mtimes(a, b), e = mtimes(depuisSelon(a), depuisSelon(b)); end
        function e = times(a, b),  e = times(depuisSelon(a), depuisSelon(b)); end
        function e = mrdivide(a, b), e = mrdivide(optimexpr.depuis(a), b); end
        function e = rdivide(a, b),  e = rdivide(optimexpr.depuis(a), b); end
        function c = le(a, b),     c = le(optimexpr.depuis(a), b); end
        function c = ge(a, b),     c = ge(optimexpr.depuis(a), b); end
        function c = eq(a, b),     c = eq(optimexpr.depuis(a), b); end

        function e = sum(v, varargin)
            e = optimexpr.depuis(v);
        end

        function varargout = subsref(v, s)
            if strcmp(s(1).type, '()')
                % Indexer une variable donne une expression qui ne porte
                % que les composantes choisies.
                indices = s(1).subs;
                if numel(indices) ~= 1
                    error('optim:optimvar:Indice', ...
                          'Une variable s''indexe par un seul indice.');
                end
                choix = indices{1};
                if ischar(choix) && strcmp(choix, ':')
                    choix = 1:prod(v.Size);
                end
                e = optimexpr();
                coefficients = zeros(prod(v.Size), 1);
                coefficients(choix) = 1;
                e.Lineaire.(v.Name) = coefficients;
                e.Variables.(v.Name) = struct('Name', v.Name, 'Size', v.Size, ...
                                              'LowerBound', v.LowerBound, ...
                                              'UpperBound', v.UpperBound, ...
                                              'Type', v.Type);
                if numel(s) > 1
                    e = subsref(e, s(2:end));
                end
                varargout{1} = e;
                return
            end
            [varargout{1:nargout}] = builtin('subsref', v, s);
        end
    end
end

function e = depuisSelon(a)
    if isnumeric(a)
        e = a;
    else
        e = optimexpr.depuis(a);
    end
end

function b = etendreBorne(b, n)
    b = double(b);
    if isscalar(b)
        b = repmat(b, n, 1);
    else
        b = b(:);
    end
end
