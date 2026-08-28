classdef timetable
%TIMETABLE Table dont chaque ligne porte un instant ou une durée.
%   TT = TIMETABLE(T,V1,V2,...) où T est un vecteur datetime ou duration.
%   TT = TIMETABLE(V1,V2,...,'RowTimes',T) donne le même résultat.
%   TT = TIMETABLE(V1,...,'SampleRate',FS) ou 'TimeStep',DT engendre les
%   instants à partir de zéro seconde.
%
%   Indexation :
%      TT(lignes,variables)  sous-timetable
%      TT{lignes,variables}  contenu extrait
%      TT.Nom                une variable
%      TT.Properties.RowTimes  le vecteur des instants
%
%   Exemple :
%      t = datetime(2024,1,1) + caldays(0:2)';
%      tt = timetable(t, [10;20;30], 'VariableNames', {'mesure'});
%      height(tt)     % 3
%
%   Voir aussi TABLE, RETIME, SYNCHRONIZE, TABLE2TIMETABLE.
    properties
        Temps = []
        Donnees = {}
        NomsVariables = {}
        NomsDimensions = {'Time', 'Variables'}
        UnitesVariables = {}
        Description = ''
        UserData = []
    end
    methods
        function tt = timetable(varargin)
            if nargin == 0, return, end
            noms = {}; temps = []; frequence = []; pas = [];
            donnees = {}; nomsAuto = {};
            k = 1;
            while k <= numel(varargin)
                a = varargin{k};
                if (ischar(a) || isstring(a)) && k < numel(varargin) && ...
                        any(strcmpi(char(a), {'VariableNames', 'RowTimes', 'SampleRate', ...
                                              'TimeStep', 'StartTime', 'VariableUnits'}))
                    valeur = varargin{k + 1};
                    switch lower(char(a))
                        case 'variablenames', noms = table.enCellules(valeur);
                        case 'rowtimes',      temps = valeur;
                        case 'samplerate',    frequence = valeur;
                        case 'timestep',      pas = valeur;
                        case 'variableunits', tt.UnitesVariables = table.enCellules(valeur);
                    end
                    k = k + 2;
                elseif isempty(donnees) && isempty(temps) && ...
                        (isa(a, 'datetime') || isa(a, 'duration'))
                    temps = a;
                    k = k + 1;
                else
                    donnees{end + 1} = a; %#ok<AGROW>
                    nomsAuto{end + 1} = sprintf('Var%d', numel(donnees)); %#ok<AGROW>
                    k = k + 1;
                end
            end
            n = 0;
            if ~isempty(donnees), n = size(donnees{1}, 1); end
            if isempty(temps)
                if ~isempty(frequence)
                    temps = duration.avec((0:n - 1)' / frequence, 's');
                elseif ~isempty(pas)
                    if isa(pas, 'duration')
                        temps = duration.avec((0:n - 1)' * seconds(pas), 's');
                    else
                        temps = duration.avec((0:n - 1)' * double(pas), 's');
                    end
                else
                    error('MATLAB:timetable:NoRowTimes', ...
                          'Specify row times with RowTimes, SampleRate, or TimeStep.');
                end
            end
            for i = 1:numel(donnees)
                if size(donnees{i}, 1) ~= n
                    error('MATLAB:timetable:UnequalVarLengths', ...
                          'All variables must have the same number of rows.');
                end
            end
            % L'axe de temps est toujours une colonne, comme dans MATLAB.
            if numel(temps) > 1 && size(temps, 1) == 1, temps = temps.'; end
            tt.Temps = temps;
            tt.Donnees = donnees;
            if isempty(noms), tt.NomsVariables = nomsAuto; else, tt.NomsVariables = noms(:)'; end
        end

        function n = height(tt)
            if isempty(tt.Donnees), n = numel(tt.Temps); else, n = size(tt.Donnees{1}, 1); end
        end
        function n = width(tt), n = numel(tt.Donnees); end
        function s = size(tt, dim)
            s = [height(tt), width(tt)];
            if nargin > 1, s = s(dim); end
        end
        function n = numel(tt), n = height(tt) * width(tt); end
        function r = isempty(tt), r = height(tt) == 0; end
        function e = end(tt, k, n)
            if n == 1, e = numel(tt);
            elseif k == 1, e = height(tt);
            else, e = width(tt);
            end
        end

        function varargout = subsref(tt, s)
            switch s(1).type
                case '()'
                    r = timetable.extraire(tt, s(1).subs, false);
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '{}'
                    r = timetable.extraire(tt, s(1).subs, true);
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    if strcmp(nom, 'Properties')
                        r = struct('RowTimes', tt.Temps, ...
                                   'VariableNames', {tt.NomsVariables}, ...
                                   'DimensionNames', {tt.NomsDimensions}, ...
                                   'VariableUnits', {tt.UnitesVariables}, ...
                                   'Description', tt.Description, ...
                                   'UserData', tt.UserData);
                    elseif strcmp(nom, tt.NomsDimensions{1}) || strcmp(nom, 'Time')
                        r = tt.Temps;
                    else
                        j = find(strcmp(nom, tt.NomsVariables), 1);
                        if ~isempty(j)
                            r = tt.Donnees{j};
                        elseif any(strcmp(nom, {'Temps', 'Donnees', 'NomsVariables', ...
                                                'NomsDimensions', 'UnitesVariables', ...
                                                'Description', 'UserData'}))
                            r = tt.(nom);
                        elseif numel(s) > 1 && strcmp(s(2).type, '()')
                            a = s(2).subs;
                            r = feval(nom, tt, a{:});
                            s(2) = [];
                        else
                            r = feval(nom, tt);
                        end
                    end
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
            end
        end

        function tt = subsasgn(tt, s, valeur)
            switch s(1).type
                case '.'
                    nom = s(1).subs;
                    if strcmp(nom, 'Properties')
                        sousNom = s(2).subs;
                        switch sousNom
                            case 'RowTimes',       tt.Temps = valeur;
                            case 'VariableNames',  tt.NomsVariables = table.enCellules(valeur);
                            case 'DimensionNames', tt.NomsDimensions = table.enCellules(valeur);
                            case 'VariableUnits',  tt.UnitesVariables = table.enCellules(valeur);
                            case 'Description',    tt.Description = valeur;
                            case 'UserData',       tt.UserData = valeur;
                            otherwise
                                error('MATLAB:timetable:UnknownProperty', ...
                                      'Unrecognized property ''%s''.', sousNom);
                        end
                        return
                    end
                    if any(strcmp(nom, {'Temps', 'Donnees', 'NomsVariables', ...
                                        'NomsDimensions', 'UnitesVariables', ...
                                        'Description', 'UserData'}))
                        tt.(nom) = valeur; return
                    end
                    j = find(strcmp(nom, tt.NomsVariables), 1);
                    if numel(s) > 1
                        tt.Donnees{j} = assignerReste(tt.Donnees{j}, s(2:end), valeur);
                        return
                    end
                    if isempty(j)
                        tt.Donnees{end + 1} = valeur;
                        tt.NomsVariables{end + 1} = nom;
                    else
                        tt.Donnees{j} = valeur;
                    end
                case '{}'
                    lignes = timetable.indicesLignes(tt, s(1).subs{1});
                    vars = timetable.indicesVariables(tt, s(1).subs{2});
                    for k = 1:numel(vars)
                        v = tt.Donnees{vars(k)};
                        v(lignes, :) = valeur;
                        tt.Donnees{vars(k)} = v;
                    end
                otherwise
                    error('MATLAB:timetable:badSubscript', ...
                          'Unsupported assignment for timetable.');
            end
        end

        function t = timetable2table(tt, varargin)
            garder = true;
            for k = 1:2:numel(varargin) - 1
                if strcmpi(char(varargin{k}), 'ConvertRowTimes')
                    garder = logical(varargin{k + 1});
                end
            end
            if garder
                t = table(tt.Temps, tt.Donnees{:}, 'VariableNames', ...
                          [tt.NomsDimensions(1), tt.NomsVariables]);
            else
                t = table(tt.Donnees{:}, 'VariableNames', tt.NomsVariables);
            end
        end

        function r = isregular(tt)
            if height(tt) < 3, r = true; return, end
            if isa(tt.Temps, 'datetime'), v = tt.Temps.Serie; else, v = seconds(tt.Temps); end
            d = diff(v(:));
            r = max(abs(d - d(1))) < 1e-9 * max(1, abs(d(1)));
        end

        function tt = head(tt, n)
            if nargin < 2, n = 8; end
            n = min(n, height(tt));
            tt = timetable.extraire(tt, {(1:n)', ':'}, false);
        end
        function tt = tail(tt, n)
            if nargin < 2, n = 8; end
            h = height(tt); n = min(n, h);
            tt = timetable.extraire(tt, {((h - n + 1):h)', ':'}, false);
        end
        function [tt, i] = sortrows(tt, varargin)
            if isa(tt.Temps, 'datetime'), cle = tt.Temps.Serie(:); else, cle = seconds(tt.Temps); cle = cle(:); end
            [~, i] = sort(cle);
            tt = timetable.extraire(tt, {i, ':'}, false);
        end

        function s = retime(tt, nouveauxTemps, methode)
            %RETIME Ré-échantillonne une timetable sur de nouveaux instants.
            %   Méthodes : 'fillwithmissing' (défaut), 'previous', 'next',
            %   'nearest', 'linear', 'spline', et les agrégations 'sum',
            %   'mean', 'min', 'max', 'count'.
            if nargin < 3, methode = 'fillwithmissing'; end
            ancien = timetable.axe(tt.Temps);
            nouveau = timetable.axe(nouveauxTemps);
            colonnes = cell(1, width(tt));
            agregation = any(strcmpi(methode, {'sum', 'mean', 'min', 'max', 'count'}));
            for k = 1:width(tt)
                v = double(tt.Donnees{k});
                if agregation
                    r = zeros(numel(nouveau), 1);
                    for i = 1:numel(nouveau)
                        if i < numel(nouveau)
                            dedans = ancien >= nouveau(i) & ancien < nouveau(i + 1);
                        else
                            dedans = ancien >= nouveau(i);
                        end
                        if strcmpi(methode, 'count')
                            r(i) = sum(dedans);
                        elseif any(dedans)
                            r(i) = feval(lower(methode), v(dedans));
                        else
                            r(i) = NaN;
                        end
                    end
                    colonnes{k} = r;
                else
                    switch lower(methode)
                        case {'linear', 'spline', 'pchip', 'nearest', 'previous', 'next'}
                            colonnes{k} = interp1(ancien, v, nouveau, lower(methode), NaN);
                        otherwise
                            r = nan(numel(nouveau), 1);
                            for i = 1:numel(nouveau)
                                j = find(abs(ancien - nouveau(i)) < 1e-9, 1);
                                if ~isempty(j), r(i) = v(j); end
                            end
                            colonnes{k} = r;
                    end
                end
            end
            s = timetable(nouveauxTemps, colonnes{:}, 'VariableNames', tt.NomsVariables);
        end

        function s = synchronize(a, b, varargin)
            %SYNCHRONIZE Réunit deux timetables sur un axe de temps commun.
            methode = 'fillwithmissing';
            cible = 'union';
            if ~isempty(varargin)
                cible = varargin{1};
                if numel(varargin) > 1, methode = varargin{2}; end
            end
            ta = timetable.axe(a.Temps);
            tb = timetable.axe(b.Temps);
            switch lower(char(cible))
                case 'union',        axe = union(ta, tb);
                case 'intersection', axe = intersect(ta, tb);
                case 'first',        axe = ta;
                case 'last',         axe = tb;
                otherwise,           axe = union(ta, tb);
            end
            axe = sort(axe(:));
            if isa(a.Temps, 'datetime')
                temps = datetime.avec(axe, a.Temps.Format, a.Temps.TimeZone);
            else
                temps = duration.avec(axe * 86400, 'hh:mm:ss');
            end
            ra = retime(a, temps, methode);
            rb = retime(b, temps, methode);
            s = timetable(temps, ra.Donnees{:}, rb.Donnees{:}, 'VariableNames', ...
                          [ra.NomsVariables, rb.NomsVariables]);
        end

        function disp(tt)
            n = height(tt); m = width(tt);
            if n == 0
                fprintf('  %dx%d timetable\n', n, m);
                return
            end
            colonneTemps = cell(n, 1);
            if isa(tt.Temps, 'datetime')
                for i = 1:n
                    colonneTemps{i} = datetime.rendre(tt.Temps.Serie(i), tt.Temps.Format);
                end
            else
                v = seconds(tt.Temps);
                for i = 1:n
                    colonneTemps{i} = duration.rendre(v(i), tt.Temps.Format);
                end
            end
            largeurTemps = numel(tt.NomsDimensions{1});
            for i = 1:n, largeurTemps = max(largeurTemps, numel(colonneTemps{i})); end
            colonnes = cell(1, m); largeurs = zeros(1, m);
            for j = 1:m
                colonnes{j} = table.rendreColonne(tt.Donnees{j});
                largeurs(j) = numel(tt.NomsVariables{j});
                for i = 1:n, largeurs(j) = max(largeurs(j), numel(colonnes{j}{i})); end
            end
            entete = sprintf('    %-*s', largeurTemps, tt.NomsDimensions{1});
            for j = 1:m
                entete = [entete '    ' sprintf('%*s', largeurs(j), tt.NomsVariables{j})]; %#ok<AGROW>
            end
            fprintf('%s\n', entete);
            souligne = ['    ' repmat('_', 1, largeurTemps)];
            for j = 1:m
                souligne = [souligne '    ' repmat('_', 1, largeurs(j))]; %#ok<AGROW>
            end
            fprintf('%s\n\n', souligne);
            for i = 1:n
                ligne = sprintf('    %-*s', largeurTemps, colonneTemps{i});
                for j = 1:m
                    ligne = [ligne '    ' sprintf('%*s', largeurs(j), colonnes{j}{i})]; %#ok<AGROW>
                end
                fprintf('%s\n', ligne);
            end
        end
    end

    methods (Static)
        function v = axe(temps)
            if isa(temps, 'datetime')
                v = temps.Serie(:);
            elseif isa(temps, 'duration')
                v = seconds(temps); v = v(:) / 86400;
            else
                v = double(temps(:));
            end
        end

        function i = indicesLignes(tt, sujet)
            n = height(tt);
            if ischar(sujet) && strcmp(sujet, ':'), i = (1:n)'; return, end
            % Sélecteurs de lignes : un intervalle de temps, ou des
            % instants à tolérance près.
            if isa(sujet, 'timerange') || isa(sujet, 'withtol')
                i = lignesRetenues(sujet, tt.Temps);
                return
            end
            if islogical(sujet), i = find(sujet(:)); return, end
            if isnumeric(sujet), i = double(sujet(:)); return, end
            if isa(sujet, 'datetime') || isa(sujet, 'duration')
                axe = timetable.axe(tt.Temps);
                cible = timetable.axe(sujet);
                i = zeros(numel(cible), 1);
                for k = 1:numel(cible)
                    j = find(abs(axe - cible(k)) < 1e-9, 1);
                    if isempty(j)
                        error('MATLAB:timetable:UnrecognizedRowTime', ...
                              'Unrecognized row time.');
                    end
                    i(k) = j;
                end
                return
            end
            i = (1:n)';
        end

        function j = indicesVariables(tt, vars)
            if ischar(vars) && strcmp(vars, ':'), j = 1:width(tt); return, end
            if isa(vars, 'vartype')
                j = variablesRetenues(vars, tt.Donnees);
                return
            end
            if isnumeric(vars), j = reshape(double(vars), 1, []); return, end
            if islogical(vars), j = reshape(find(vars), 1, []); return, end
            liste = table.enCellules(vars);
            j = zeros(1, numel(liste));
            for k = 1:numel(liste)
                p = find(strcmp(liste{k}, tt.NomsVariables), 1);
                if isempty(p)
                    error('MATLAB:timetable:UnrecognizedVarName', ...
                          'Unrecognized variable name ''%s''.', liste{k});
                end
                j(k) = p;
            end
        end

        function r = extraire(tt, indices, contenu)
            if numel(indices) == 1
                lignes = timetable.indicesLignes(tt, indices{1});
                vars = 1:width(tt);
            else
                lignes = timetable.indicesLignes(tt, indices{1});
                vars = timetable.indicesVariables(tt, indices{2});
            end
            if contenu
                r = [];
                for k = vars
                    bloc = table.lignesDe(tt.Donnees{k}, lignes);
                    if isempty(r), r = bloc; else, r = [r, bloc]; end %#ok<AGROW>
                end
                return
            end
            r = timetable();
            r.Temps = tt.Temps(lignes);
            r.Donnees = cell(1, numel(vars));
            for k = 1:numel(vars)
                r.Donnees{k} = table.lignesDe(tt.Donnees{vars(k)}, lignes);
            end
            r.NomsVariables = tt.NomsVariables(vars);
            r.NomsDimensions = tt.NomsDimensions;
        end
    end
end
