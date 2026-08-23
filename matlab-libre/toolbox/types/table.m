classdef table
%TABLE Tableau de données à colonnes nommées et hétérogènes.
%   T = TABLE(V1,V2,...) range chaque variable dans une colonne. Toutes les
%   variables doivent avoir le même nombre de lignes.
%   T = TABLE(...,'VariableNames',NOMS) nomme les colonnes,
%   T = TABLE(...,'RowNames',NOMS) nomme les lignes.
%
%   Indexation :
%      T(lignes,variables)   sous-table
%      T{lignes,variables}   contenu extrait et concaténé
%      T.Nom                 une variable entière
%      T.Properties          métadonnées (VariableNames, RowNames, ...)
%
%   Exemple :
%      t = table([1;2;3], {'a';'b';'c'}, 'VariableNames', {'n','lettre'});
%      height(t)      % 3
%      t.n            % [1;2;3]
%      t(2,:)         % deuxième ligne
%
%   Voir aussi ARRAY2TABLE, CELL2TABLE, STRUCT2TABLE, TABLE2ARRAY, HEAD,
%   TAIL, SORTROWS, VARFUN, GROUPSUMMARY, INNERJOIN, OUTERJOIN, TIMETABLE.
    properties
        Donnees = {}
        NomsVariables = {}
        NomsLignes = {}
        NomsDimensions = {'Row', 'Variables'}
        UnitesVariables = {}
        DescriptionsVariables = {}
        Description = ''
        UserData = []
    end
    methods
        function t = table(varargin)
            if nargin == 0, return, end
            noms = {}; lignes = {}; unites = {}; descriptions = {};
            donnees = {}; nomsAuto = {};
            k = 1;
            while k <= numel(varargin)
                a = varargin{k};
                if (ischar(a) || isstring(a)) && k < numel(varargin) && ...
                        any(strcmpi(char(a), {'VariableNames', 'RowNames', 'VariableUnits', ...
                                              'VariableDescriptions', 'DimensionNames'}))
                    valeur = varargin{k + 1};
                    switch lower(char(a))
                        case 'variablenames',        noms = table.enCellules(valeur);
                        case 'rownames',             lignes = table.enCellules(valeur);
                        case 'variableunits',        unites = table.enCellules(valeur);
                        case 'variabledescriptions', descriptions = table.enCellules(valeur);
                        case 'dimensionnames',       t.NomsDimensions = table.enCellules(valeur);
                    end
                    k = k + 2;
                else
                    donnees{end + 1} = a; %#ok<AGROW>
                    nomsAuto{end + 1} = sprintf('Var%d', numel(donnees)); %#ok<AGROW>
                    k = k + 1;
                end
            end
            n = -1;
            for i = 1:numel(donnees)
                h = table.hauteurDe(donnees{i});
                if n < 0
                    n = h;
                elseif h ~= n
                    error('MATLAB:table:UnequalVarLengths', ...
                          'All variables must have the same number of rows.');
                end
            end
            t.Donnees = donnees;
            if isempty(noms), t.NomsVariables = nomsAuto; else, t.NomsVariables = noms(:)'; end
            if numel(t.NomsVariables) ~= numel(donnees)
                error('MATLAB:table:IncorrectNumberOfVarNames', ...
                      'The number of variable names must match the number of variables.');
            end
            t.NomsLignes = lignes(:)';
            t.UnitesVariables = unites(:)';
            t.DescriptionsVariables = descriptions(:)';
        end

        % --- dimensions ---------------------------------------------------------
        function n = height(t)
            if isempty(t.Donnees), n = 0; else, n = table.hauteurDe(t.Donnees{1}); end
        end
        function n = width(t), n = numel(t.Donnees); end
        function s = size(t, dim)
            s = [height(t), width(t)];
            if nargin > 1, s = s(dim); end
        end
        function n = numel(t), n = height(t) * width(t); end
        function n = length(t), n = max(size(t)); end
        function n = ndims(~), n = 2; end
        function r = isempty(t), r = (height(t) == 0) || (width(t) == 0); end
        function e = end(t, k, n)
            if n == 1, e = numel(t);
            elseif k == 1, e = height(t);
            else, e = width(t);
            end
        end
        function n = numArgumentsFromSubscript(~, ~, ~), n = 1; end

        % --- indexation -----------------------------------------------------------
        function varargout = subsref(t, s)
            switch s(1).type
                case '()'
                    r = table.extraire(t, s(1).subs, false);
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '{}'
                    r = table.extraire(t, s(1).subs, true);
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    if strcmp(nom, 'Properties')
                        r = proprietes(t);
                        if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                        varargout{1} = r;
                        return
                    end
                    j = table.indexVariable(t, nom, false);
                    if ~isempty(j)
                        r = t.Donnees{j};
                        if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                        varargout{1} = r;
                        return
                    end
                    if any(strcmp(nom, {'Donnees', 'NomsVariables', 'NomsLignes', ...
                                        'NomsDimensions', 'UnitesVariables', ...
                                        'DescriptionsVariables', 'Description', 'UserData'}))
                        r = t.(nom);
                        if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                        varargout{1} = r;
                        return
                    end
                    if numel(s) > 1 && strcmp(s(2).type, '()')
                        a = s(2).subs;
                        r = feval(nom, t, a{:});
                        s(2) = [];
                    else
                        r = feval(nom, t);
                    end
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
            end
        end

        function t = subsasgn(t, s, valeur)
            switch s(1).type
                case '.'
                    nom = s(1).subs;
                    if strcmp(nom, 'Properties')
                        t = table.poserPropriete(t, s(2:end), valeur);
                        return
                    end
                    if any(strcmp(nom, {'Donnees', 'NomsVariables', 'NomsLignes', ...
                                        'NomsDimensions', 'UnitesVariables', ...
                                        'DescriptionsVariables', 'Description', 'UserData'}))
                        t.(nom) = valeur;
                        return
                    end
                    j = table.indexVariable(t, nom, false);
                    if numel(s) > 1
                        if isempty(j)
                            error('MATLAB:table:UnrecognizedVarName', ...
                                  'Unrecognized variable name ''%s''.', nom);
                        end
                        t.Donnees{j} = assignerReste(t.Donnees{j}, s(2:end), valeur);
                        return
                    end
                    if isempty(valeur) && isnumeric(valeur) && ~isempty(j)
                        t = removevars(t, nom);
                        return
                    end
                    if isempty(j)
                        t.Donnees{end + 1} = valeur;
                        t.NomsVariables{end + 1} = nom;
                    else
                        t.Donnees{j} = valeur;
                    end
                case {'()', '{}'}
                    t = table.affecter(t, s(1).subs, valeur, strcmp(s(1).type, '{}'));
                otherwise
                    error('MATLAB:table:badSubscript', 'Unsupported assignment for table.');
            end
        end

        function p = proprietes(t)
            p = struct('VariableNames', {t.NomsVariables}, ...
                       'RowNames', {t.NomsLignes}, ...
                       'DimensionNames', {t.NomsDimensions}, ...
                       'VariableUnits', {t.UnitesVariables}, ...
                       'VariableDescriptions', {t.DescriptionsVariables}, ...
                       'Description', t.Description, ...
                       'UserData', t.UserData);
        end

        % --- manipulation de variables ---------------------------------------------
        function t = addvars(t, varargin)
            noms = {}; apres = ''; avant = '';
            valeurs = {};
            k = 1;
            while k <= numel(varargin)
                a = varargin{k};
                if (ischar(a) || isstring(a)) && k < numel(varargin) && ...
                        any(strcmpi(char(a), {'NewVariableNames', 'After', 'Before'}))
                    switch lower(char(a))
                        case 'newvariablenames', noms = table.enCellules(varargin{k + 1});
                        case 'after',            apres = varargin{k + 1};
                        case 'before',           avant = varargin{k + 1};
                    end
                    k = k + 2;
                else
                    valeurs{end + 1} = a; %#ok<AGROW>
                    k = k + 1;
                end
            end
            for i = 1:numel(valeurs)
                if i <= numel(noms)
                    nom = noms{i};
                else
                    nom = sprintf('Var%d', width(t) + 1);
                end
                position = width(t) + 1;
                if ~isempty(apres)
                    position = table.indexVariable(t, apres, true) + 1;
                elseif ~isempty(avant)
                    position = table.indexVariable(t, avant, true);
                end
                t.Donnees = [t.Donnees(1:position - 1), {valeurs{i}}, t.Donnees(position:end)];
                t.NomsVariables = [t.NomsVariables(1:position - 1), {nom}, ...
                                   t.NomsVariables(position:end)];
                apres = nom; avant = '';
            end
        end
        function t = removevars(t, vars)
            j = table.indicesVariables(t, vars);
            garde = true(1, width(t));
            garde(j) = false;
            t.Donnees = t.Donnees(garde);
            t.NomsVariables = t.NomsVariables(garde);
            if ~isempty(t.UnitesVariables), t.UnitesVariables = t.UnitesVariables(garde); end
            if ~isempty(t.DescriptionsVariables)
                t.DescriptionsVariables = t.DescriptionsVariables(garde);
            end
        end
        function t = movevars(t, vars, ou, cible)
            j = table.indicesVariables(t, vars);
            donnees = t.Donnees(j); noms = t.NomsVariables(j);
            garde = true(1, width(t)); garde(j) = false;
            t.Donnees = t.Donnees(garde); t.NomsVariables = t.NomsVariables(garde);
            position = table.indexVariable(t, cible, true);
            if strcmpi(ou, 'after'), position = position + 1; end
            t.Donnees = [t.Donnees(1:position - 1), donnees, t.Donnees(position:end)];
            t.NomsVariables = [t.NomsVariables(1:position - 1), noms, ...
                               t.NomsVariables(position:end)];
        end
        function t = renamevars(t, anciens, nouveaux)
            a = table.enCellules(anciens); b = table.enCellules(nouveaux);
            for k = 1:numel(a)
                j = table.indexVariable(t, a{k}, true);
                t.NomsVariables{j} = b{min(k, numel(b))};
            end
        end
        function t = convertvars(t, vars, fonction)
            j = table.indicesVariables(t, vars);
            for k = j
                if ischar(fonction) || isstring(fonction)
                    t.Donnees{k} = feval(char(fonction), t.Donnees{k});
                else
                    t.Donnees{k} = fonction(t.Donnees{k});
                end
            end
        end

        % --- opérations sur les lignes ----------------------------------------------
        function [t, i] = sortrows(t, vars, sens)
            if nargin < 2 || isempty(vars), vars = 1; end
            if nargin < 3, sens = 'ascend'; end
            j = table.indicesVariables(t, vars);
            n = height(t);
            i = (1:n)';
            for p = numel(j):-1:1
                colonne = t.Donnees{j(p)};
                cle = table.cleTri(colonne);
                cle = cle(i, :);
                if iscell(cle)
                    [~, ordre] = sort(cle);
                else
                    [~, ordre] = sortrows(cle);
                end
                if (iscell(sens) && strcmpi(sens{min(p, numel(sens))}, 'descend')) || ...
                        (~iscell(sens) && strcmpi(sens, 'descend'))
                    ordre = flipud(ordre(:));
                end
                i = i(ordre);
            end
            t = table.extraire(t, {i, ':'}, false);
        end
        function t = head(t, n)
            if nargin < 2, n = 8; end
            n = min(n, height(t));
            t = table.extraire(t, {(1:n)', ':'}, false);
        end
        function t = tail(t, n)
            if nargin < 2, n = 8; end
            h = height(t);
            n = min(n, h);
            t = table.extraire(t, {((h - n + 1):h)', ':'}, false);
        end
        function r = vertcat(varargin)
            r = varargin{1};
            for k = 2:numel(varargin)
                a = varargin{k};
                if width(a) ~= width(r)
                    error('MATLAB:table:vertcat:SizeMismatch', ...
                          'All tables must have the same number of variables.');
                end
                for j = 1:width(r)
                    r.Donnees{j} = [r.Donnees{j}; a.Donnees{j}];
                end
                r.NomsLignes = [r.NomsLignes, a.NomsLignes];
            end
        end
        function r = horzcat(varargin)
            r = varargin{1};
            for k = 2:numel(varargin)
                a = varargin{k};
                r.Donnees = [r.Donnees, a.Donnees];
                r.NomsVariables = [r.NomsVariables, a.NomsVariables];
            end
        end

        % --- conversions -------------------------------------------------------------
        function a = table2array(t)
            a = [];
            for k = 1:width(t)
                a = [a, table.enColonnes(t.Donnees{k})]; %#ok<AGROW>
            end
        end
        function c = table2cell(t)
            n = height(t); m = width(t);
            c = cell(n, m);
            for j = 1:m
                v = t.Donnees{j};
                for i = 1:n
                    if iscell(v), c{i, j} = v{i};
                    else, c{i, j} = table.ligneDe(v, i);
                    end
                end
            end
        end
        function s = table2struct(t, varargin)
            enColonne = false;
            for k = 1:2:numel(varargin) - 1
                if strcmpi(char(varargin{k}), 'ToScalar')
                    enColonne = logical(varargin{k + 1});
                end
            end
            if enColonne
                s = struct();
                for j = 1:width(t)
                    s.(t.NomsVariables{j}) = t.Donnees{j};
                end
                return
            end
            n = height(t);
            for i = n:-1:1
                for j = 1:width(t)
                    v = t.Donnees{j};
                    if iscell(v), s(i, 1).(t.NomsVariables{j}) = v{i};
                    else, s(i, 1).(t.NomsVariables{j}) = table.ligneDe(v, i);
                    end
                end
            end
            if n == 0, s = struct([]); end
        end

        % --- calculs groupés -----------------------------------------------------------
        function r = varfun(fonction, t, varargin)
            vars = 1:width(t); sortie = 'table'; groupes = [];
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'inputvariables',  vars = table.indicesVariables(t, varargin{k + 1});
                    case 'outputformat',    sortie = lower(char(varargin{k + 1}));
                    case 'groupingvariables', groupes = table.indicesVariables(t, varargin{k + 1});
                end
                k = k + 2;
            end
            if ~isempty(groupes)
                r = table.varfunGroupe(fonction, t, vars, groupes, sortie);
                return
            end
            valeurs = cell(1, numel(vars));
            noms = cell(1, numel(vars));
            for i = 1:numel(vars)
                valeurs{i} = fonction(t.Donnees{vars(i)});
                noms{i} = sprintf('%s_%s', table.nomFonction(fonction), ...
                                  t.NomsVariables{vars(i)});
            end
            switch sortie
                case 'uniform', r = cell2mat(valeurs);
                case 'cell',    r = valeurs;
                otherwise
                    r = table(valeurs{:}, 'VariableNames', noms);
            end
        end

        function r = rowfun(fonction, t, varargin)
            vars = 1:width(t); nomsSortie = {}; sortie = 'table';
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'inputvariables',    vars = table.indicesVariables(t, varargin{k + 1});
                    case 'outputvariablenames', nomsSortie = table.enCellules(varargin{k + 1});
                    case 'outputformat',      sortie = lower(char(varargin{k + 1}));
                end
                k = k + 2;
            end
            n = height(t);
            resultats = cell(n, 1);
            for i = 1:n
                entrees = cell(1, numel(vars));
                for j = 1:numel(vars)
                    v = t.Donnees{vars(j)};
                    if iscell(v), entrees{j} = v{i}; else, entrees{j} = table.ligneDe(v, i); end
                end
                resultats{i} = fonction(entrees{:});
            end
            colonne = cell2mat(resultats);
            if isempty(nomsSortie), nomsSortie = {'Var1'}; end
            switch sortie
                case 'uniform', r = colonne;
                case 'cell',    r = resultats;
                otherwise,      r = table(colonne, 'VariableNames', nomsSortie);
            end
        end

        function r = groupsummary(t, groupes, methode, vars)
            if nargin < 4, vars = setdiff(1:width(t), table.indicesVariables(t, groupes)); end
            ig = table.indicesVariables(t, groupes);
            iv = table.indicesVariables(t, vars);
            if ischar(methode) || isstring(methode), methode = {char(methode)}; end
            cles = table.clesGroupes(t, ig);
            [uniques, ~, ou] = table.uniqueCellules(cles);
            ng = numel(uniques);
            colonnes = {}; noms = {};
            for g = 1:numel(ig)
                v = t.Donnees{ig(g)};
                indices = zeros(ng, 1);
                for k = 1:ng, indices(k) = find(ou == k, 1); end
                colonnes{end + 1} = table.lignesDe(v, indices); %#ok<AGROW>
                noms{end + 1} = t.NomsVariables{ig(g)}; %#ok<AGROW>
            end
            compte = zeros(ng, 1);
            for k = 1:ng, compte(k) = sum(ou == k); end
            colonnes{end + 1} = compte; noms{end + 1} = 'GroupCount';
            for m = 1:numel(methode)
                for i = 1:numel(iv)
                    v = t.Donnees{iv(i)};
                    resultat = zeros(ng, 1);
                    for k = 1:ng
                        resultat(k) = feval(methode{m}, v(ou == k));
                    end
                    colonnes{end + 1} = resultat; %#ok<AGROW>
                    noms{end + 1} = sprintf('%s_%s', methode{m}, ...
                                            t.NomsVariables{iv(i)}); %#ok<AGROW>
                end
            end
            r = table(colonnes{:}, 'VariableNames', noms);
        end

        % --- jointures ----------------------------------------------------------------
        function r = innerjoin(a, b, varargin)
            r = table.jointure(a, b, varargin, 'inner');
        end
        function r = outerjoin(a, b, varargin)
            r = table.jointure(a, b, varargin, 'outer');
        end
        function r = join(a, b, varargin)
            r = table.jointure(a, b, varargin, 'left');
        end

        % --- affichage -------------------------------------------------------------------
        function disp(t)
            n = height(t); m = width(t);
            if m == 0 || n == 0
                fprintf('  %dx%d table\n', n, m);
                return
            end
            colonnes = cell(1, m);
            largeurs = zeros(1, m);
            for j = 1:m
                colonnes{j} = table.rendreColonne(t.Donnees{j});
                largeurs(j) = numel(t.NomsVariables{j});
                for i = 1:n, largeurs(j) = max(largeurs(j), numel(colonnes{j}{i})); end
            end
            largeurLigne = 0;
            if ~isempty(t.NomsLignes)
                for i = 1:n, largeurLigne = max(largeurLigne, numel(t.NomsLignes{i})); end
            end
            entete = '';
            if largeurLigne > 0, entete = [blanks(largeurLigne + 4)]; end
            for j = 1:m
                entete = [entete '    ' sprintf('%*s', largeurs(j), t.NomsVariables{j})]; %#ok<AGROW>
            end
            fprintf('%s\n', entete);
            souligne = '';
            if largeurLigne > 0, souligne = [blanks(largeurLigne + 4)]; end
            for j = 1:m
                souligne = [souligne '    ' repmat('_', 1, largeurs(j))]; %#ok<AGROW>
            end
            fprintf('%s\n\n', souligne);
            for i = 1:n
                ligne = '';
                if largeurLigne > 0
                    ligne = ['    ' sprintf('%-*s', largeurLigne, t.NomsLignes{i})];
                end
                for j = 1:m
                    ligne = [ligne '    ' sprintf('%*s', largeurs(j), colonnes{j}{i})]; %#ok<AGROW>
                end
                fprintf('%s\n', ligne);
            end
        end

        function summary(t)
            fprintf('Variables:\n\n');
            for j = 1:width(t)
                v = t.Donnees{j};
                fprintf('    %s: %dx%d %s\n', t.NomsVariables{j}, size(v, 1), ...
                        size(v, 2), class(v));
                if isnumeric(v) && ~isempty(v)
                    fprintf('        Values:\n');
                    fprintf('            Min       %g\n', min(v(:)));
                    fprintf('            Median    %g\n', median(double(v(:))));
                    fprintf('            Max       %g\n', max(v(:)));
                end
            end
        end
    end

    methods (Static)
        function h = hauteurDe(v)
            if iscell(v) || isnumeric(v) || islogical(v) || ischar(v) || isstring(v)
                h = size(v, 1);
            else
                h = size(v, 1);
            end
        end

        function c = enCellules(v)
            if iscell(v), c = v(:)';
            elseif isstring(v), c = cellstr(v); c = c(:)';
            elseif ischar(v), c = {v};
            else, c = num2cell(v(:)');
            end
        end

        function j = indexVariable(t, nom, obligatoire)
            if isnumeric(nom) || islogical(nom)
                j = double(nom); return
            end
            nom = char(nom);
            j = find(strcmp(nom, t.NomsVariables), 1);
            if isempty(j) && obligatoire
                error('MATLAB:table:UnrecognizedVarName', ...
                      'Unrecognized variable name ''%s''.', nom);
            end
        end

        function j = indicesVariables(t, vars)
            if ischar(vars) && strcmp(vars, ':')
                j = 1:width(t); return
            end
            if isnumeric(vars), j = reshape(double(vars), 1, []); return, end
            if islogical(vars), j = reshape(find(vars), 1, []); return, end
            liste = table.enCellules(vars);
            j = zeros(1, numel(liste));
            for k = 1:numel(liste)
                j(k) = table.indexVariable(t, liste{k}, true);
            end
        end

        function i = indicesLignes(t, sujet)
            n = height(t);
            if ischar(sujet) && strcmp(sujet, ':')
                i = (1:n)'; return
            end
            if isnumeric(sujet), i = double(sujet(:)); return, end
            if islogical(sujet), i = find(sujet(:)); return, end
            liste = table.enCellules(sujet);
            i = zeros(numel(liste), 1);
            for k = 1:numel(liste)
                j = find(strcmp(liste{k}, t.NomsLignes), 1);
                if isempty(j)
                    error('MATLAB:table:UnrecognizedRowName', ...
                          'Unrecognized row name ''%s''.', liste{k});
                end
                i(k) = j;
            end
        end

        function r = extraire(t, indices, contenu)
            if numel(indices) == 1
                lignes = (1:height(t))';
                vars = table.indicesVariables(t, indices{1});
            else
                lignes = table.indicesLignes(t, indices{1});
                vars = table.indicesVariables(t, indices{2});
            end
            if contenu
                r = [];
                for k = vars
                    bloc = table.lignesDe(t.Donnees{k}, lignes);
                    if isempty(r), r = bloc; else, r = [r, bloc]; end %#ok<AGROW>
                end
                if numel(vars) == 1 && iscell(t.Donnees{vars(1)}) && numel(lignes) == 1
                    r = r{1};
                end
                return
            end
            r = table();
            r.Donnees = cell(1, numel(vars));
            for k = 1:numel(vars)
                r.Donnees{k} = table.lignesDe(t.Donnees{vars(k)}, lignes);
            end
            r.NomsVariables = t.NomsVariables(vars);
            if ~isempty(t.NomsLignes), r.NomsLignes = t.NomsLignes(lignes); end
            if ~isempty(t.UnitesVariables), r.UnitesVariables = t.UnitesVariables(vars); end
            r.NomsDimensions = t.NomsDimensions;
            r.Description = t.Description;
        end

        function t = affecter(t, indices, valeur, contenu)
            if numel(indices) == 1
                lignes = (1:height(t))';
                vars = table.indicesVariables(t, indices{1});
            else
                lignes = table.indicesLignes(t, indices{1});
                if ischar(indices{2}) && strcmp(indices{2}, ':')
                    vars = 1:width(t);
                elseif (ischar(indices{2}) || iscell(indices{2}) || isstring(indices{2}))
                    liste = table.enCellules(indices{2});
                    vars = zeros(1, numel(liste));
                    for k = 1:numel(liste)
                        j = table.indexVariable(t, liste{k}, false);
                        if isempty(j)
                            t.Donnees{end + 1} = [];
                            t.NomsVariables{end + 1} = liste{k};
                            j = width(t);
                        end
                        vars(k) = j;
                    end
                else
                    vars = table.indicesVariables(t, indices{2});
                end
            end
            if contenu
                for k = 1:numel(vars)
                    v = t.Donnees{vars(k)};
                    if isempty(v), v = zeros(height(t), 1); end
                    if size(valeur, 2) >= numel(vars)
                        v(lignes, :) = valeur(:, k);
                    else
                        v(lignes, :) = valeur;
                    end
                    t.Donnees{vars(k)} = v;
                end
            else
                if ~isa(valeur, 'table')
                    error('MATLAB:table:InvalidRowAssignment', ...
                          'Right hand side must be a table for () assignment.');
                end
                for k = 1:numel(vars)
                    v = t.Donnees{vars(k)};
                    source = valeur.Donnees{min(k, width(valeur))};
                    if iscell(v)
                        v(lignes) = source;
                    else
                        v(lignes, :) = source;
                    end
                    t.Donnees{vars(k)} = v;
                end
            end
        end

        function t = poserPropriete(t, reste, valeur)
            if isempty(reste)
                error('MATLAB:table:InvalidPropertyAssignment', ...
                      'Assign to a specific property of Properties.');
            end
            nom = reste(1).subs;
            switch nom
                case 'VariableNames',        t.NomsVariables = table.enCellules(valeur);
                case 'RowNames',             t.NomsLignes = table.enCellules(valeur);
                case 'DimensionNames',       t.NomsDimensions = table.enCellules(valeur);
                case 'VariableUnits',        t.UnitesVariables = table.enCellules(valeur);
                case 'VariableDescriptions', t.DescriptionsVariables = table.enCellules(valeur);
                case 'Description',          t.Description = valeur;
                case 'UserData',             t.UserData = valeur;
                otherwise
                    error('MATLAB:table:UnknownProperty', ...
                          'Unrecognized table property ''%s''.', nom);
            end
        end

        function bloc = lignesDe(v, lignes)
            if iscell(v)
                bloc = v(lignes, :);
            elseif isa(v, 'table')
                bloc = table.extraire(v, {lignes, ':'}, false);
            elseif ischar(v) && size(v, 2) > 1
                bloc = v(lignes, :);
            else
                bloc = v(lignes, :);
            end
        end

        function bloc = ligneDe(v, i)
            if size(v, 2) == 1, bloc = v(i); else, bloc = v(i, :); end
        end

        function c = enColonnes(v)
            if iscell(v)
                error('MATLAB:table:table2array:CellVariable', ...
                      'Cell variables cannot be concatenated into an array.');
            end
            c = v;
        end

        function cle = cleTri(v)
            if iscell(v), cle = v(:);
            elseif isa(v, 'categorical'), cle = double(v(:));
            elseif isa(v, 'datetime'), cle = v.Serie(:);
            elseif isa(v, 'duration'), cle = seconds(v); cle = cle(:);
            elseif ischar(v), cle = cellstr(v);
            elseif isstring(v), cle = cellstr(v); cle = cle(:);
            else, cle = double(v);
            end
        end

        function cles = clesGroupes(t, ig)
            n = height(t);
            cles = cell(n, 1);
            for i = 1:n
                morceaux = cell(1, numel(ig));
                for g = 1:numel(ig)
                    v = t.Donnees{ig(g)};
                    if iscell(v), morceaux{g} = char(v{i});
                    elseif isa(v, 'categorical'), c = cellstr(v); morceaux{g} = c{i};
                    elseif ischar(v), morceaux{g} = strtrim(v(i, :));
                    elseif isstring(v), morceaux{g} = char(v(i));
                    else, morceaux{g} = sprintf('%.17g', double(v(i)));
                    end
                end
                cles{i} = strjoin(morceaux, char(1));
            end
        end

        function [u, i, ou] = uniqueCellules(cles)
            u = {}; i = []; ou = zeros(numel(cles), 1);
            for k = 1:numel(cles)
                j = find(strcmp(cles{k}, u), 1);
                if isempty(j)
                    u{end + 1} = cles{k}; %#ok<AGROW>
                    i(end + 1) = k;       %#ok<AGROW>
                    j = numel(u);
                end
                ou(k) = j;
            end
        end

        function n = nomFonction(f)
            n = func2str(f);
            n = strrep(n, '@', '');
            if any(n == '(')
                n = 'Fun';
            end
        end

        function r = varfunGroupe(fonction, t, vars, groupes, ~)
            vars = setdiff(vars, groupes);
            cles = table.clesGroupes(t, groupes);
            [uniques, ~, ou] = table.uniqueCellules(cles);
            ng = numel(uniques);
            colonnes = {}; noms = {};
            for g = 1:numel(groupes)
                v = t.Donnees{groupes(g)};
                indices = zeros(ng, 1);
                for k = 1:ng, indices(k) = find(ou == k, 1); end
                colonnes{end + 1} = table.lignesDe(v, indices); %#ok<AGROW>
                noms{end + 1} = t.NomsVariables{groupes(g)}; %#ok<AGROW>
            end
            compte = zeros(ng, 1);
            for k = 1:ng, compte(k) = sum(ou == k); end
            colonnes{end + 1} = compte; noms{end + 1} = 'GroupCount';
            for i = 1:numel(vars)
                v = t.Donnees{vars(i)};
                resultat = zeros(ng, 1);
                for k = 1:ng, resultat(k) = fonction(v(ou == k)); end
                colonnes{end + 1} = resultat; %#ok<AGROW>
                noms{end + 1} = sprintf('%s_%s', table.nomFonction(fonction), ...
                                        t.NomsVariables{vars(i)}); %#ok<AGROW>
            end
            r = table(colonnes{:}, 'VariableNames', noms);
        end

        function r = jointure(a, b, options, genre)
            cle = '';
            for k = 1:2:numel(options) - 1
                if any(strcmpi(char(options{k}), {'Keys', 'LeftKeys', 'RightKeys'}))
                    cle = options{k + 1};
                end
            end
            if isempty(cle)
                communs = intersect(a.NomsVariables, b.NomsVariables);
                if isempty(communs)
                    error('MATLAB:table:join:CannotInferKey', ...
                          'No common variables to use as keys.');
                end
                cle = communs{1};
            end
            listeCle = table.enCellules(cle);
            cle = char(listeCle{1});
            ia = table.indexVariable(a, cle, true);
            ib = table.indexVariable(b, cle, true);
            va = table.cleTri(a.Donnees{ia});
            vb = table.cleTri(b.Donnees{ib});
            lignesA = []; lignesB = [];
            for i = 1:height(a)
                if iscell(va), correspond = find(strcmp(va{i}, vb));
                else, correspond = find(vb == va(i));
                end
                if isempty(correspond)
                    if ~strcmp(genre, 'inner')
                        lignesA(end + 1) = i; lignesB(end + 1) = 0; %#ok<AGROW>
                    end
                else
                    for j = correspond(:)'
                        lignesA(end + 1) = i; lignesB(end + 1) = j; %#ok<AGROW>
                    end
                end
            end
            if strcmp(genre, 'outer')
                for j = 1:height(b)
                    if iscell(vb), correspond = find(strcmp(vb{j}, va));
                    else, correspond = find(va == vb(j));
                    end
                    if isempty(correspond)
                        lignesA(end + 1) = 0; lignesB(end + 1) = j; %#ok<AGROW>
                    end
                end
            end
            colonnes = {}; noms = {};
            for k = 1:width(a)
                colonnes{end + 1} = table.selectionner(a.Donnees{k}, lignesA); %#ok<AGROW>
                noms{end + 1} = a.NomsVariables{k}; %#ok<AGROW>
            end
            for k = 1:width(b)
                if k == ib, continue, end
                colonnes{end + 1} = table.selectionner(b.Donnees{k}, lignesB); %#ok<AGROW>
                nom = b.NomsVariables{k};
                if any(strcmp(nom, noms)), nom = [nom '_right']; end
                noms{end + 1} = nom; %#ok<AGROW>
            end
            r = table(colonnes{:}, 'VariableNames', noms);
        end

        function bloc = selectionner(v, lignes)
            n = numel(lignes);
            if iscell(v)
                bloc = cell(n, 1);
                for k = 1:n
                    if lignes(k) > 0, bloc{k} = v{lignes(k)}; else, bloc{k} = ''; end
                end
            else
                bloc = nan(n, size(v, 2));
                for k = 1:n
                    if lignes(k) > 0, bloc(k, :) = v(lignes(k), :); end
                end
            end
        end

        function textes = rendreColonne(v)
            n = size(v, 1);
            textes = cell(n, 1);
            for i = 1:n
                if iscell(v)
                    x = v{i};
                    if ischar(x), textes{i} = ['{''' x '''}'];
                    elseif isnumeric(x) && isscalar(x), textes{i} = ['{' num2str(x) '}'];
                    else, textes{i} = sprintf('{%dx%d %s}', size(x, 1), size(x, 2), class(x));
                    end
                elseif isa(v, 'categorical')
                    c = cellstr(v); textes{i} = c{i};
                elseif isa(v, 'datetime')
                    textes{i} = datetime.rendre(v.Serie(i), v.Format);
                elseif isa(v, 'duration')
                    s = seconds(v); textes{i} = duration.rendre(s(i), v.Format);
                elseif isstring(v)
                    textes{i} = char(v(i));
                elseif ischar(v)
                    textes{i} = strtrim(v(i, :));
                elseif islogical(v)
                    textes{i} = sprintf('%d', v(i));
                else
                    ligne = v(i, :);
                    morceaux = cell(1, numel(ligne));
                    for j = 1:numel(ligne)
                        morceaux{j} = table.nombre(ligne(j));
                    end
                    textes{i} = strjoin(morceaux, '    ');
                end
            end
        end

        function s = nombre(x)
            if isnan(x), s = 'NaN';
            elseif x == fix(x) && abs(x) < 1e10, s = sprintf('%d', x);
            else, s = sprintf('%.4f', x);
            end
        end
    end
end
