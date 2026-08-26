classdef categorical
%CATEGORICAL Tableau de valeurs prises dans un ensemble fini de catégories.
%   C = CATEGORICAL(A) transforme un tableau de textes, un tableau
%   numérique ou un tableau logique en catégories, triées par ordre
%   croissant. C = CATEGORICAL(A,ENSEMBLE) impose la liste des catégories,
%   et C = CATEGORICAL(A,ENSEMBLE,NOMS) leur donne d'autres noms.
%   CATEGORICAL(...,'Ordinal',true) rend les catégories ordonnées : les
%   comparaisons < <= > >= deviennent alors licites.
%
%   Les valeurs absentes de l'ensemble sont indéfinies : leur code vaut 0 et
%   elles s'affichent « <undefined> ».
%
%   Exemple :
%      c = categorical({'petit','grand','petit'})
%      categories(c)        % {'grand';'petit'}
%      countcats(c)         % [1 2]
%
%   Voir aussi CATEGORIES, ISCATEGORY, ADDCATS, REMOVECATS, MERGECATS,
%   RENAMECATS, REORDERCATS, SETCATS, COUNTCATS, ISUNDEFINED.
    properties
        Codes = []          % indices dans Noms ; 0 = indéfini
        Noms = {}           % noms des catégories, dans l'ordre
        Ordinal = false
        Protected = false
    end
    methods
        function c = categorical(a, ensemble, noms, varargin)
            if nargin == 0, return, end
            ordinal = false;
            protege = false;
            reste = varargin;
            k = 1;
            while k + 1 <= numel(reste)
                switch lower(char(reste{k}))
                    case 'ordinal',   ordinal = logical(reste{k + 1});
                    case 'protected', protege = logical(reste{k + 1});
                end
                k = k + 2;
            end
            if isa(a, 'categorical')
                c = a; c.Ordinal = ordinal; return
            end
            valeurs = categorical.enTextes(a);
            if nargin >= 2 && ~isempty(ensemble)
                liste = categorical.enTextes(ensemble);
                liste = liste(:)';
            else
                liste = categorical.trierUniques(valeurs);
            end
            if nargin >= 3 && ~isempty(noms)
                affiches = categorical.enTextes(noms);
                affiches = affiches(:)';
                if numel(affiches) ~= numel(liste)
                    error('MATLAB:categorical:CatNamesSizeMismatch', ...
                          'The number of category names must match the number of values.');
                end
            else
                affiches = liste;
            end
            % Des noms répétés fusionnent les catégories correspondantes.
            [uniques, ~, ou] = categorical.uniqueOrdonne(affiches);
            codes = zeros(size(valeurs));
            for i = 1:numel(valeurs)
                j = find(strcmp(valeurs{i}, liste), 1);
                if ~isempty(j) && ~isempty(valeurs{i})
                    codes(i) = ou(j);
                end
            end
            c.Codes = reshape(codes, size(valeurs));
            c.Noms = uniques;
            c.Ordinal = ordinal;
            c.Protected = protege || ordinal;
        end

        % --- catégories -------------------------------------------------------
        function n = categories(c), n = c.Noms(:); end
        function r = iscategory(c, nom)
            liste = categorical.enTextes(nom);
            r = false(size(liste));
            for k = 1:numel(liste)
                r(k) = any(strcmp(liste{k}, c.Noms));
            end
            if isscalar(r), r = r(1); end
        end
        function c = addcats(c, nouvelles, ~)
            liste = categorical.enTextes(nouvelles);
            for k = 1:numel(liste)
                if ~any(strcmp(liste{k}, c.Noms))
                    c.Noms{end + 1} = liste{k};
                end
            end
        end
        function c = removecats(c, aRetirer)
            if nargin < 2
                garde = false(1, numel(c.Noms));
                for k = 1:numel(c.Noms), garde(k) = any(c.Codes(:) == k); end
            else
                liste = categorical.enTextes(aRetirer);
                garde = true(1, numel(c.Noms));
                for k = 1:numel(c.Noms)
                    if any(strcmp(c.Noms{k}, liste)), garde(k) = false; end
                end
            end
            c = categorical.reindexer(c, garde);
        end
        function c = mergecats(c, anciennes, nouvelle)
            liste = categorical.enTextes(anciennes);
            if nargin < 3, nouvelle = liste{1}; else, nouvelle = char(nouvelle); end
            cible = find(strcmp(nouvelle, c.Noms), 1);
            if isempty(cible)
                cible = find(strcmp(liste{1}, c.Noms), 1);
                c.Noms{cible} = nouvelle;
            end
            for k = 1:numel(liste)
                j = find(strcmp(liste{k}, c.Noms), 1);
                if ~isempty(j) && j ~= cible
                    c.Codes(c.Codes == j) = cible;
                    c.Noms{j} = '';
                end
            end
            garde = ~strcmp(c.Noms, '');
            c = categorical.reindexer(c, garde);
        end
        function c = renamecats(c, a, b)
            if nargin == 2
                nouveaux = categorical.enTextes(a);
                if numel(nouveaux) ~= numel(c.Noms)
                    error('MATLAB:categorical:renamecats:WrongNumNames', ...
                          'The number of new names must match the number of categories.');
                end
                c.Noms = nouveaux(:)';
            else
                anciens = categorical.enTextes(a);
                nouveaux = categorical.enTextes(b);
                for k = 1:numel(anciens)
                    j = find(strcmp(anciens{k}, c.Noms), 1);
                    if isempty(j)
                        error('MATLAB:categorical:renamecats:UnrecognizedCategory', ...
                              'Unrecognized category ''%s''.', anciens{k});
                    end
                    c.Noms{j} = nouveaux{min(k, numel(nouveaux))};
                end
            end
        end
        function c = reordercats(c, ordre)
            if nargin < 2
                [~, perm] = sort(c.Noms);
            else
                liste = categorical.enTextes(ordre);
                perm = zeros(1, numel(liste));
                for k = 1:numel(liste)
                    perm(k) = find(strcmp(liste{k}, c.Noms), 1);
                end
            end
            table_ = zeros(1, numel(c.Noms));
            for k = 1:numel(perm), table_(perm(k)) = k; end
            codes = c.Codes;
            nouveaux = codes;
            for k = 1:numel(codes)
                if codes(k) > 0, nouveaux(k) = table_(codes(k)); end
            end
            c.Codes = nouveaux;
            c.Noms = c.Noms(perm);
        end
        function c = setcats(c, ensemble)
            liste = categorical.enTextes(ensemble);
            liste = liste(:)';
            anciens = cellstr(c);
            codes = zeros(size(c.Codes));
            for k = 1:numel(codes)
                j = find(strcmp(anciens{k}, liste), 1);
                if ~isempty(j), codes(k) = j; end
            end
            c.Codes = codes;
            c.Noms = liste;
        end
        function n = countcats(c, dim)
            if nargin < 2, dim = 1; end
            if isvector(c.Codes)
                n = zeros(1, numel(c.Noms));
                for k = 1:numel(c.Noms), n(k) = sum(c.Codes(:) == k); end
                if iscolumn(c.Codes), n = n(:); end
            else
                if dim == 1
                    n = zeros(numel(c.Noms), size(c.Codes, 2));
                    for j = 1:size(c.Codes, 2)
                        for k = 1:numel(c.Noms)
                            n(k, j) = sum(c.Codes(:, j) == k);
                        end
                    end
                else
                    n = zeros(size(c.Codes, 1), numel(c.Noms));
                    for i = 1:size(c.Codes, 1)
                        for k = 1:numel(c.Noms)
                            n(i, k) = sum(c.Codes(i, :) == k);
                        end
                    end
                end
            end
        end
        function r = isundefined(c), r = (c.Codes == 0); end
        function r = isordinal(c), r = c.Ordinal; end
        function r = isprotected(c), r = c.Protected; end

        % --- comparaisons ------------------------------------------------------
        function r = eq(a, b), r = categorical.comparer(a, b, '=='); end
        function r = ne(a, b), r = ~categorical.comparer(a, b, '=='); end
        function r = lt(a, b), r = categorical.comparer(a, b, '<'); end
        function r = le(a, b), r = categorical.comparer(a, b, '<='); end
        function r = gt(a, b), r = categorical.comparer(a, b, '>'); end
        function r = ge(a, b), r = categorical.comparer(a, b, '>='); end
        function r = isequal(a, b)
            r = isequal(cellstr(categorical(a)), cellstr(categorical(b)));
        end
        function [r, i] = sort(c, varargin)
            cle = c.Codes;
            cle(cle == 0) = numel(c.Noms) + 1;    % les indéfinis en dernier
            [~, i] = sort(cle, varargin{:});
            r = categorical.avec(c.Codes(i), c.Noms, c.Ordinal);
        end
        function [r, i, j] = unique(c)
            [u, i, j] = unique(c.Codes);
            r = categorical.avec(u, c.Noms, c.Ordinal);
        end
        function r = ismember(a, b)
            ta = cellstr(categorical(a));
            if isa(b, 'categorical'), tb = cellstr(b); else, tb = categorical.enTextes(b); end
            r = ismember(ta, tb);
        end

        % --- taille et forme ---------------------------------------------------
        function n = numel(c), n = numel(c.Codes); end
        function s = size(c, dim)
            if nargin > 1, s = size(c.Codes, dim); else, s = size(c.Codes); end
        end
        function n = length(c), n = length(c.Codes); end
        function r = isempty(c), r = isempty(c.Codes); end
        function r = isscalar(c), r = isscalar(c.Codes); end
        function r = isvector(c), r = isvector(c.Codes); end
        function r = transpose(c), r = categorical.avec(c.Codes.', c.Noms, c.Ordinal); end
        function r = ctranspose(c), r = categorical.avec(c.Codes', c.Noms, c.Ordinal); end
        function r = reshape(c, varargin)
            r = categorical.avec(reshape(c.Codes, varargin{:}), c.Noms, c.Ordinal);
        end
        function e = end(c, k, n)
            if n == 1, e = numel(c.Codes); else, e = size(c.Codes, k); end
        end
        function r = horzcat(varargin), r = categorical.assembler(varargin, 2); end
        function r = vertcat(varargin), r = categorical.assembler(varargin, 1); end

        % --- indexation ---------------------------------------------------------
        function varargout = subsref(c, s)
            switch s(1).type
                case '()'
                    ind = s(1).subs;
                    r = categorical.avec(c.Codes(ind{:}), c.Noms, c.Ordinal);
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'Codes',     r = c.Codes;
                        case 'Noms',      r = c.Noms;
                        case 'Ordinal',   r = c.Ordinal;
                        case 'Protected', r = c.Protected;
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                a = s(2).subs;
                                r = feval(nom, c, a{:});
                                s(2) = [];
                            else
                                r = feval(nom, c);
                            end
                    end
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:categorical:badSubscript', ...
                          'Brace indexing is not supported for categorical.');
            end
        end
        function c = subsasgn(c, s, valeur)
            switch s(1).type
                case '()'
                    ind = s(1).subs;
                    textes = categorical.enTextes(valeur);
                    codes = zeros(size(textes));
                    for k = 1:numel(textes)
                        j = find(strcmp(textes{k}, c.Noms), 1);
                        if isempty(j)
                            if c.Protected
                                error('MATLAB:categorical:ProtectedForCombination', ...
                                      ['Cannot add categories to a protected categorical ' ...
                                       'array.']);
                            end
                            c.Noms{end + 1} = textes{k};
                            j = numel(c.Noms);
                        end
                        codes(k) = j;
                    end
                    if isscalar(codes)
                        c.Codes(ind{:}) = codes;
                    else
                        c.Codes(ind{:}) = reshape(codes, [], 1);
                    end
                case '.'
                    c.(s(1).subs) = valeur;
                otherwise
                    error('MATLAB:categorical:badSubscript', ...
                          'Unsupported assignment for categorical.');
            end
        end

        % --- conversions ---------------------------------------------------------
        function t = cellstr(c)
            t = cell(size(c.Codes));
            for k = 1:numel(c.Codes)
                if c.Codes(k) == 0
                    t{k} = '<undefined>';
                else
                    t{k} = c.Noms{c.Codes(k)};
                end
            end
        end
        function s = string(c), s = string(cellstr(c)); end
        function t = char(c)
            liste = cellstr(c);
            t = '';
            for k = 1:numel(liste)
                if k == 1, t = liste{k}; else, t = strvcat(t, liste{k}); end %#ok<VCAT>
            end
        end
        function d = double(c)
            d = double(c.Codes);
            d(c.Codes == 0) = NaN;
        end
        function disp(c)
            if isempty(c.Codes), fprintf('  0x0 categorical\n'); return, end
            liste = cellstr(c);
            [nl, nc] = size(c.Codes);
            largeur = 0;
            for k = 1:numel(liste), largeur = max(largeur, numel(liste{k})); end
            for i = 1:nl
                ligne = '';
                for j = 1:nc
                    ligne = [ligne '     ' sprintf('%-*s', largeur, liste{i + (j - 1) * nl})]; %#ok<AGROW>
                end
                fprintf('%s\n', deblank(ligne));
            end
        end
        function r = summary(c)
            noms = c.Noms;
            n = countcats(c);
            if nargout > 0
                r = struct();
                for k = 1:numel(noms)
                    r.(matlab.lang.makeValidName(noms{k})) = n(k);
                end
                return
            end
            for k = 1:numel(noms)
                fprintf('     %-20s %d\n', noms{k}, n(k));
            end
            nd = sum(c.Codes(:) == 0);
            if nd > 0, fprintf('     %-20s %d\n', '<undefined>', nd); end
        end
    end

    methods (Static)
        function c = avec(codes, noms, ordinal)
            c = categorical();
            c.Codes = codes; c.Noms = noms;
            if nargin > 2, c.Ordinal = ordinal; c.Protected = ordinal; end
        end

        function t = enTextes(a)
            if isa(a, 'categorical')
                t = cellstr(a);
            elseif iscell(a)
                t = cell(size(a));
                for k = 1:numel(a)
                    if ischar(a{k}), t{k} = a{k};
                    elseif isstring(a{k}), t{k} = char(a{k});
                    else, t{k} = categorical.nombreEnTexte(a{k});
                    end
                end
            elseif isstring(a)
                t = cellstr(a);
            elseif ischar(a)
                if size(a, 1) > 1
                    t = cell(size(a, 1), 1);
                    for k = 1:size(a, 1), t{k} = strtrim(a(k, :)); end
                else
                    t = {a};
                end
            elseif islogical(a)
                t = cell(size(a));
                for k = 1:numel(a)
                    if a(k), t{k} = 'true'; else, t{k} = 'false'; end
                end
            else
                t = cell(size(a));
                for k = 1:numel(a), t{k} = categorical.nombreEnTexte(a(k)); end
            end
        end

        function s = nombreEnTexte(x)
            if isnan(x)
                s = '';
            elseif x == fix(x) && abs(x) < 1e15
                s = sprintf('%d', x);
            else
                s = sprintf('%.15g', x);
            end
        end

        function u = trierUniques(textes)
            v = textes(:)';
            v = v(~strcmp(v, ''));
            u = {};
            for k = 1:numel(v)
                if ~any(strcmp(v{k}, u)), u{end + 1} = v{k}; end %#ok<AGROW>
            end
            if ~isempty(u), u = sort(u); end
        end

        function [u, i, ou] = uniqueOrdonne(noms)
            u = {}; i = []; ou = zeros(1, numel(noms));
            for k = 1:numel(noms)
                j = find(strcmp(noms{k}, u), 1);
                if isempty(j)
                    u{end + 1} = noms{k}; %#ok<AGROW>
                    i(end + 1) = k;       %#ok<AGROW>
                    j = numel(u);
                end
                ou(k) = j;
            end
        end

        function c = reindexer(c, garde)
            table_ = zeros(1, numel(c.Noms));
            n = 0;
            for k = 1:numel(c.Noms)
                if garde(k), n = n + 1; table_(k) = n; end
            end
            codes = c.Codes;
            for k = 1:numel(codes)
                if codes(k) > 0, codes(k) = table_(codes(k)); end
            end
            c.Codes = codes;
            c.Noms = c.Noms(logical(garde));
        end

        function r = comparer(a, b, op)
            ca = categorical(a); cb = categorical(b);
            if any(strcmp(op, {'<', '<=', '>', '>='}))
                ordinal = (isa(a, 'categorical') && a.Ordinal) || ...
                          (isa(b, 'categorical') && b.Ordinal);
                if ~ordinal
                    error('MATLAB:categorical:NotOrdinal', ...
                          ['Relational comparison is not allowed for categorical arrays ' ...
                           'that are not ordinal.']);
                end
                if isa(a, 'categorical'), noms = a.Noms; else, noms = cb.Noms; end
                ia = categorical.rang(ca, noms);
                ib = categorical.rang(cb, noms);
                switch op
                    case '<',  r = ia <  ib;
                    case '<=', r = ia <= ib;
                    case '>',  r = ia >  ib;
                    case '>=', r = ia >= ib;
                end
                return
            end
            ta = cellstr(ca); tb = cellstr(cb);
            if numel(ta) == 1
                r = strcmp(ta{1}, tb) & ~strcmp(tb, '<undefined>');
            elseif numel(tb) == 1
                r = strcmp(tb{1}, ta) & ~strcmp(ta, '<undefined>');
            else
                r = strcmp(ta, tb) & ~strcmp(ta, '<undefined>');
            end
        end

        function v = rang(c, noms)
            t = cellstr(c);
            v = nan(size(t));
            for k = 1:numel(t)
                j = find(strcmp(t{k}, noms), 1);
                if ~isempty(j), v(k) = j; end
            end
        end

        function r = assembler(liste, dim)
            noms = {};
            for k = 1:numel(liste)
                c = categorical(liste{k});
                for j = 1:numel(c.Noms)
                    if ~any(strcmp(c.Noms{j}, noms)), noms{end + 1} = c.Noms{j}; end %#ok<AGROW>
                end
            end
            ordinal = false;
            for k = 1:numel(liste)
                if isa(liste{k}, 'categorical') && liste{k}.Ordinal, ordinal = true; end
            end
            codes = [];
            for k = 1:numel(liste)
                c = categorical(liste{k});
                bloc = zeros(size(c.Codes));
                for j = 1:numel(c.Codes)
                    if c.Codes(j) > 0
                        bloc(j) = find(strcmp(c.Noms{c.Codes(j)}, noms), 1);
                    end
                end
                if dim == 1, codes = [codes; bloc]; else, codes = [codes, bloc]; end %#ok<AGROW>
            end
            r = categorical.avec(codes, noms, ordinal);
        end
    end
end
