classdef datetime
%DATETIME Point dans le temps, avec date et heure.
%   T = DATETIME(Y,M,D) construit une date à minuit.
%   T = DATETIME(Y,M,D,H,MI,S) précise l'heure ; S peut être fractionnaire.
%   T = DATETIME(V) accepte un vecteur de date [Y M D H MI S] par ligne.
%   T = DATETIME(TEXTE) lit 'aaaa-mm-jj hh:mm:ss' ou 'jj-MMM-aaaa'.
%   T = DATETIME('now'), 'today', 'yesterday', 'tomorrow'.
%   T = DATETIME(X,'ConvertFrom',SOURCE) avec SOURCE parmi 'datenum',
%   'posixtime', 'excel', 'juliandate'.
%
%   L'état interne est un numéro de série compatible DATENUM : 1 correspond
%   au 1er janvier de l'an 0. Les composantes s'obtiennent par YEAR, MONTH,
%   DAY, HOUR, MINUTE, SECOND, ou par les propriétés du même nom.
%
%   Exemple :
%      t = datetime(2024, 2, 29, 13, 30, 0)
%      t + caldays(1)
%      t2 = datetime(2024, 3, 1);  t2 - t     % durée
%
%   Voir aussi DURATION, CALENDARDURATION, NAT, DATESHIFT, CALDIFF.
    properties
        Serie = 0                        % numéro de série (jours)
        Format = 'dd-MMM-uuuu HH:mm:ss'
        TimeZone = ''
    end
    methods
        function t = datetime(varargin)
            if nargin == 0
                t.Serie = now();
                return
            end
            % Options en fin d'appel.
            options = struct('ConvertFrom', '', 'InputFormat', '', 'Format', '', ...
                             'TimeZone', '');
            arguments_ = varargin;
            k = 1;
            positionnels = {};
            while k <= numel(arguments_)
                a = arguments_{k};
                if (ischar(a) || isstring(a)) && k < numel(arguments_) && ...
                        any(strcmpi(char(a), {'ConvertFrom', 'InputFormat', 'Format', 'TimeZone'}))
                    options.(datetime.nomOption(char(a))) = char(arguments_{k + 1});
                    k = k + 2;
                else
                    positionnels{end + 1} = a; %#ok<AGROW>
                    k = k + 1;
                end
            end
            if ~isempty(options.ConvertFrom)
                x = double(positionnels{1});
                switch lower(options.ConvertFrom)
                    case 'datenum',    t.Serie = x;
                    case 'posixtime',  t.Serie = x / 86400 + datetime.epoquePosix();
                    case 'excel',      t.Serie = x + datetime.epoqueExcel();
                    case 'juliandate', t.Serie = x - 1721058.5;
                    otherwise
                        error('MATLAB:datetime:UnknownConvertFrom', ...
                              'Unrecognized ConvertFrom value ''%s''.', options.ConvertFrom);
                end
            elseif numel(positionnels) == 1
                a = positionnels{1};
                if isa(a, 'datetime')
                    t.Serie = a.Serie; t.Format = a.Format; t.TimeZone = a.TimeZone;
                elseif ischar(a) || isstring(a) || iscellstr(a)
                    t.Serie = datetime.analyser(a, options.InputFormat);
                    if all(t.Serie == fix(t.Serie)), t.Format = 'dd-MMM-uuuu'; end
                elseif isnumeric(a) && size(a, 2) >= 3 && size(a, 1) >= 1 && ~isvector(a)
                    t.Serie = datetime.depuisVecteur(a);
                elseif isnumeric(a) && isvector(a) && numel(a) >= 3 && numel(a) <= 6
                    t.Serie = datetime.depuisVecteur(reshape(a, 1, []));
                else
                    error('MATLAB:datetime:InvalidData', ...
                          'Unable to interpret the input as a date.');
                end
            else
                v = positionnels;
                for i = numel(v) + 1:6, v{i} = 0; end
                t.Serie = matlibre_ymd2num(double(v{1}), double(v{2}), double(v{3}), ...
                                           double(v{4}), double(v{5}), double(v{6}));
                if numel(positionnels) == 3, t.Format = 'dd-MMM-uuuu'; end
            end
            if ~isempty(options.Format),   t.Format = options.Format; end
            if ~isempty(options.TimeZone)
                % Le fuseau est validé tout de suite : un nom inconnu doit
                % être refusé à la construction, pas des heures plus tard
                % au premier calcul de décalage.
                datetime.infoZone(options.TimeZone);
                t.TimeZone = char(options.TimeZone);
            end
        end

        % --- arithmétique ---------------------------------------------------
        function r = plus(a, b)
            if isa(b, 'datetime') && ~isa(a, 'datetime')
                r = plus(b, a); return
            end
            if isa(b, 'calendarDuration')
                s = matlibre_addmonths(a.Serie, b.Mois);
                s = s + b.Jours + b.Temps / 86400;
                r = datetime.avec(s, a.Format, a.TimeZone);
            elseif isa(b, 'duration')
                r = datetime.avec(a.Serie + seconds(b) / 86400, a.Format, a.TimeZone);
            else
                r = datetime.avec(a.Serie + double(b), a.Format, a.TimeZone);
            end
        end
        function r = minus(a, b)
            if isa(a, 'datetime') && isa(b, 'datetime')
                r = duration.avec((a.Serie - b.Serie) * 86400, 'hh:mm:ss');
            elseif isa(a, 'datetime') && isa(b, 'calendarDuration')
                r = plus(a, -b);
            elseif isa(a, 'datetime') && isa(b, 'duration')
                r = datetime.avec(a.Serie - seconds(b) / 86400, a.Format, a.TimeZone);
            elseif isa(a, 'datetime')
                r = datetime.avec(a.Serie - double(b), a.Format, a.TimeZone);
            else
                error('MATLAB:datetime:SubtractionNotDefined', ...
                      'Undefined operator ''-'' for these operands.');
            end
        end

        function r = lt(a, b), r = serieDe(a) <  serieDe(b); end
        function r = le(a, b), r = serieDe(a) <= serieDe(b); end
        function r = gt(a, b), r = serieDe(a) >  serieDe(b); end
        function r = ge(a, b), r = serieDe(a) >= serieDe(b); end
        function r = eq(a, b), r = serieDe(a) == serieDe(b); end
        function r = ne(a, b), r = serieDe(a) ~= serieDe(b); end
        function r = isequal(a, b), r = isequal(serieDe(a), serieDe(b)); end

        function [r, i] = max(a, b, varargin)
            if nargin >= 2 && ~isempty(b)
                [v, i] = max(serieDe(a), serieDe(b), varargin{:});
            else
                [v, i] = max(a.Serie, [], varargin{:});
            end
            r = datetime.avec(v, a.Format, a.TimeZone);
        end
        function [r, i] = min(a, b, varargin)
            if nargin >= 2 && ~isempty(b)
                [v, i] = min(serieDe(a), serieDe(b), varargin{:});
            else
                [v, i] = min(a.Serie, [], varargin{:});
            end
            r = datetime.avec(v, a.Format, a.TimeZone);
        end
        function [r, i] = sort(a, varargin)
            [v, i] = sort(a.Serie, varargin{:});
            r = datetime.avec(v, a.Format, a.TimeZone);
        end
        function r = diff(a, varargin)
            r = duration.avec(diff(a.Serie, varargin{:}) * 86400, 'hh:mm:ss');
        end
        function r = mean(a, varargin)
            r = datetime.avec(mean(a.Serie, varargin{:}), a.Format, a.TimeZone);
        end
        function r = median(a, varargin)
            r = datetime.avec(median(a.Serie, varargin{:}), a.Format, a.TimeZone);
        end
        function r = colon(a, pas, b)
            if nargin == 2
                b = pas; pas = duration.avec(86400, 'd');
            end
            if isa(pas, 'calendarDuration')
                v = []; courant = a;
                while courant.Serie <= b.Serie + 1e-9
                    v(end + 1) = courant.Serie; %#ok<AGROW>
                    courant = courant + pas;
                end
                r = datetime.avec(v, a.Format, a.TimeZone);
            else
                if isa(pas, 'duration'), dj = seconds(pas) / 86400; else, dj = double(pas); end
                r = datetime.avec(a.Serie:dj:b.Serie, a.Format, a.TimeZone);
            end
        end

        % --- taille et forme ------------------------------------------------
        function n = numel(t), n = numel(t.Serie); end
        function s = size(t, dim)
            if nargin > 1, s = size(t.Serie, dim); else, s = size(t.Serie); end
        end
        function n = length(t), n = length(t.Serie); end
        function n = ndims(t), n = ndims(t.Serie); end
        function r = isempty(t), r = isempty(t.Serie); end
        function r = isscalar(t), r = isscalar(t.Serie); end
        function r = isvector(t), r = isvector(t.Serie); end
        function r = transpose(t), r = datetime.avec(t.Serie.', t.Format, t.TimeZone); end
        function r = ctranspose(t), r = datetime.avec(t.Serie', t.Format, t.TimeZone); end
        function r = reshape(t, varargin)
            r = datetime.avec(reshape(t.Serie, varargin{:}), t.Format, t.TimeZone);
        end
        function r = horzcat(varargin)
            v = []; f = ''; z = '';
            for k = 1:numel(varargin)
                a = varargin{k};
                if isempty(f) && isa(a, 'datetime'), f = a.Format; z = a.TimeZone; end
                v = [v, reshape(serieDe(a), 1, [])];
            end
            r = datetime.avec(v, f, z);
        end
        function r = vertcat(varargin)
            v = []; f = ''; z = '';
            for k = 1:numel(varargin)
                a = varargin{k};
                if isempty(f) && isa(a, 'datetime'), f = a.Format; z = a.TimeZone; end
                v = [v; reshape(serieDe(a), [], 1)];
            end
            r = datetime.avec(v, f, z);
        end
        function e = end(t, k, n)
            if n == 1, e = numel(t.Serie); else, e = size(t.Serie, k); end
        end

        % --- indexation -------------------------------------------------------
        function varargout = subsref(t, s)
            switch s(1).type
                case '()'
                    ind = s(1).subs;
                    r = datetime.avec(t.Serie(ind{:}), t.Format, t.TimeZone);
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'Serie',    r = t.Serie;
                        case 'Format',   r = t.Format;
                        case 'TimeZone', r = t.TimeZone;
                        case 'Year',     r = year(t);
                        case 'Month',    r = month(t);
                        case 'Day',      r = day(t);
                        case 'Hour',     r = hour(t);
                        case 'Minute',   r = minute(t);
                        case 'Second',   r = second(t);
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                a = s(2).subs;
                                r = feval(nom, t, a{:});
                                s(2) = [];
                            else
                                r = feval(nom, t);
                            end
                    end
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:datetime:badSubscript', ...
                          'Brace indexing is not supported for datetime.');
            end
        end

        function t = subsasgn(t, s, valeur)
            switch s(1).type
                case '()'
                    ind = s(1).subs;
                    t.Serie(ind{:}) = serieDe(valeur);
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'TimeZone'
                            % Attacher un fuseau a une date qui n'en avait
                            % pas ne deplace rien : les composantes sont
                            % deja l'heure locale. Passer d'un fuseau a un
                            % autre, en revanche, decrit le meme instant
                            % dans une autre heure locale.
                            nouveau = char(valeur);
                            if ~isempty(nouveau), datetime.infoZone(nouveau); end
                            if ~isempty(t.TimeZone) && ~isempty(nouveau)
                                serie = t.Serie;
                                for k = 1:numel(serie)
                                    depart = datetime.decalageZone(t.TimeZone, serie(k));
                                    instant = serie(k) - depart / 24;
                                    arrivee = datetime.decalageZone(nouveau, instant);
                                    % Un tour de plus : le décalage
                                    % d'arrivée se juge sur l'heure locale
                                    % d'arrivée, pas sur l'instant nu.
                                    arrivee = datetime.decalageZone(nouveau, instant + arrivee / 24);
                                    % Ajouter la différence d'un coup évite
                                    % la double erreur d'arrondi d'un
                                    % retrait suivi d'un ajout.
                                    serie(k) = serie(k) + (arrivee - depart) / 24;
                                    serie(k) = round(serie(k) * 86400e6) / 86400e6;
                                end
                                t.Serie = serie;
                            end
                            t.TimeZone = nouveau;
                        case {'Serie', 'Format'}
                            t.(nom) = valeur;
                        otherwise
                            c = matlibre_num2ymd(t.Serie(:));
                            colonne = find(strcmp(nom, ...
                                {'Year', 'Month', 'Day', 'Hour', 'Minute', 'Second'}));
                            if isempty(colonne)
                                error('MATLAB:datetime:UnrecognizedProperty', ...
                                      'Unrecognized property ''%s'' for class datetime.', nom);
                            end
                            c(:, colonne) = valeur(:);
                            t.Serie = reshape(matlibre_ymd2num(c(:, 1), c(:, 2), c(:, 3), ...
                                                               c(:, 4), c(:, 5), c(:, 6)), ...
                                              size(t.Serie));
                    end
                otherwise
                    error('MATLAB:datetime:badSubscript', ...
                          'Unsupported assignment for datetime.');
            end
        end

        % --- conversions ------------------------------------------------------
        function n = datenum(t), n = t.Serie; end
        function v = datevec(t), v = matlibre_num2ymd(t.Serie(:)); end
        function s = posixtime(t), s = (t.Serie - datetime.epoquePosix()) * 86400; end
        function s = exceltime(t), s = t.Serie - datetime.epoqueExcel(); end
        function s = juliandate(t), s = t.Serie + 1721058.5; end
        function r = isnat(t), r = isnan(t.Serie); end
        function c = char(t)
            c = '';
            for k = 1:numel(t.Serie)
                ligne = datetime.rendre(t.Serie(k), t.Format);
                if k == 1, c = ligne; else, c = strvcat(c, ligne); end %#ok<VCAT>
            end
        end
        function c = cellstr(t)
            c = cell(size(t.Serie));
            for k = 1:numel(t.Serie)
                c{k} = datetime.rendre(t.Serie(k), t.Format);
            end
        end
        function s = string(t), s = string(cellstr(t)); end
        function s = datestr(t, varargin)
            if isempty(varargin)
                s = char(t);
            else
                s = datestr(t.Serie, varargin{:});
            end
        end
        function disp(t)
            if isempty(t.Serie), fprintf('  0x0 datetime\n'); return, end
            [nl, nc] = size(t.Serie);
            for i = 1:nl
                ligne = '';
                for j = 1:nc
                    ligne = [ligne '   ' datetime.rendre(t.Serie(i, j), t.Format)]; %#ok<AGROW>
                end
                fprintf('%s\n', ligne);
            end
        end

        % --- composantes de date ---------------------------------------------
        function v = year(t, ~)
            c = matlibre_num2ymd(t.Serie(:));
            v = reshape(c(:, 1), size(t.Serie));
        end
        function v = month(t, genre)
            c = matlibre_num2ymd(t.Serie(:));
            v = reshape(c(:, 2), size(t.Serie));
            if nargin > 1
                noms = {'January', 'February', 'March', 'April', 'May', 'June', 'July', ...
                        'August', 'September', 'October', 'November', 'December'};
                sortie = cell(size(v));
                for k = 1:numel(v)
                    nom = noms{v(k)};
                    if strcmpi(genre, 'shortname'), nom = nom(1:3); end
                    sortie{k} = nom;
                end
                v = sortie;
                if numel(v) == 1, v = v{1}; end
            end
        end
        function v = day(t, genre)
            c = matlibre_num2ymd(t.Serie(:));
            if nargin > 1 && any(strcmpi(genre, {'name', 'shortname'}))
                jours = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', ...
                         'Friday', 'Saturday'};
                sortie = cell(size(t.Serie));
                for k = 1:numel(t.Serie)
                    nom = jours{matlibre_weekday(t.Serie(k))};
                    if strcmpi(genre, 'shortname'), nom = nom(1:3); end
                    sortie{k} = nom;
                end
                v = sortie;
                if numel(v) == 1, v = v{1}; end
                return
            end
            if nargin > 1 && strcmpi(genre, 'dayofyear')
                debut = matlibre_ymd2num(c(:, 1), 1, 1);
                v = reshape(floor(t.Serie(:)) - debut + 1, size(t.Serie));
                return
            end
            v = reshape(c(:, 3), size(t.Serie));
        end
        function v = hour(t),   c = matlibre_num2ymd(t.Serie(:)); v = reshape(c(:, 4), size(t.Serie)); end
        function v = minute(t), c = matlibre_num2ymd(t.Serie(:)); v = reshape(c(:, 5), size(t.Serie)); end
        function v = second(t), c = matlibre_num2ymd(t.Serie(:)); v = reshape(c(:, 6), size(t.Serie)); end
        function v = quarter(t), v = floor((month(t) - 1) / 3) + 1; end
        function v = week(t)
            % Semaine ISO 8601 : la semaine 1 contient le premier jeudi.
            j = floor(t.Serie(:));
            jourISO = mod(matlibre_weekday(j) + 5, 7) + 1;      % lundi = 1
            jeudi = j - jourISO + 4;
            c = matlibre_num2ymd(jeudi);
            debut = matlibre_ymd2num(c(:, 1), 1, 1);
            v = reshape(floor((jeudi - debut) / 7) + 1, size(t.Serie));
        end
        function v = weekday(t), v = reshape(matlibre_weekday(t.Serie(:)), size(t.Serie)); end
        function r = isweekend(t)
            j = weekday(t);
            r = (j == 1) | (j == 7);
        end
        function [y, m, d] = ymd(t)
            c = matlibre_num2ymd(t.Serie(:));
            y = reshape(c(:, 1), size(t.Serie));
            m = reshape(c(:, 2), size(t.Serie));
            d = reshape(c(:, 3), size(t.Serie));
        end
        function [h, m, s] = hms(t)
            c = matlibre_num2ymd(t.Serie(:));
            h = reshape(c(:, 4), size(t.Serie));
            m = reshape(c(:, 5), size(t.Serie));
            s = reshape(c(:, 6), size(t.Serie));
        end
        function d = timeofday(t)
            d = duration.avec((t.Serie - floor(t.Serie)) * 86400, 'hh:mm:ss');
        end
        function r = isbetween(t, a, b)
            r = (t >= a) & (t <= b);
        end

        function r = dateshift(t, mode, unite, n)
            %DATESHIFT Déplace une date sur une limite de calendrier.
            %   DATESHIFT(T,'start',UNITE) recule au début de l'unité.
            %   DATESHIFT(T,'end',UNITE) avance à la fin de l'unité.
            %   DATESHIFT(T,'dayofweek',JOUR) va au jour de semaine demandé.
            if nargin < 4, n = 0; end
            c = matlibre_num2ymd(t.Serie(:));
            switch lower(mode)
                case 'start'
                    s = datetime.limite(c, lower(unite), t.Serie(:), 0);
                case 'end'
                    s = datetime.limite(c, lower(unite), t.Serie(:), 1);
                case 'dayofweek'
                    cible = unite;
                    if ischar(cible) || isstring(cible)
                        jours = {'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', ...
                                 'friday', 'saturday'};
                        cible = find(strcmpi(char(cible), jours), 1);
                    end
                    j = floor(t.Serie(:));
                    ecart = mod(cible - matlibre_weekday(j), 7);
                    s = j + ecart + 7 * max(0, n - 1);
                otherwise
                    error('MATLAB:datetime:UnknownDateShift', ...
                          'Unrecognized dateshift mode ''%s''.', mode);
            end
            r = datetime.avec(reshape(s, size(t.Serie)), t.Format, t.TimeZone);
        end

        function cd = caldiff(t, unite)
            %CALDIFF Différences successives en unités de calendrier.
            if nargin < 2, unite = 'ymd'; end
            v = t.Serie(:);
            n = numel(v) - 1;
            mois = zeros(1, n); jours = zeros(1, n); temps = zeros(1, n);
            for k = 1:n
                [mois(k), jours(k), temps(k)] = datetime.ecart(v(k), v(k + 1), unite);
            end
            cd = calendarDuration.depuis(mois, jours, temps);
        end

        function cd = between(a, b, unite)
            %BETWEEN Écart calendaire entre deux dates.
            if nargin < 3, unite = 'ymd'; end
            va = serieDe(a); vb = serieDe(b);
            n = max(numel(va), numel(vb));
            mois = zeros(1, n); jours = zeros(1, n); temps = zeros(1, n);
            for k = 1:n
                x = va(min(k, numel(va)));
                y = vb(min(k, numel(vb)));
                [mois(k), jours(k), temps(k)] = datetime.ecart(x, y, unite);
            end
            cd = calendarDuration.depuis(mois, jours, temps);
        end

        % --- fuseaux horaires ---------------------------------------------------------
        function d = tzoffset(t)
%TZOFFSET Décalage du fuseau par rapport au temps universel.
%   D = TZOFFSET(T) rend, pour chaque instant, la durée à ajouter au
%   temps universel pour obtenir l'heure locale. Elle change au cours de
%   l'année quand le fuseau observe l'heure d'été.
%
%   Exemple :
%      d = datetime(2020, 1, 15, 'TimeZone', 'Europe/Paris');
%      hours(tzoffset(d))   % 1
%
%   Voir aussi ISDST, TIMEZONES, DATETIME.
            if isempty(t.TimeZone)
                error('MATLAB:datetime:UnzonedTzoffset', ...
                      'TZOFFSET demande une date avec fuseau.');
            end
            heures = zeros(size(t.Serie));
            for k = 1:numel(t.Serie)
                heures(k) = datetime.decalageZone(t.TimeZone, t.Serie(k));
            end
            d = hours(heures);
        end

        function v = isdst(t)
%ISDST L'heure d'été est-elle en vigueur ?
%   V = ISDST(T) est vrai aux instants où le fuseau applique son décalage
%   supplémentaire.
%
%   Exemple :
%      d = datetime(2020, 7, 15, 'TimeZone', 'Europe/Paris');
%      isdst(d)   % vrai
%
%   Voir aussi TZOFFSET, TIMEZONES.
            if isempty(t.TimeZone)
                error('MATLAB:datetime:UnzonedIsdst', ...
                      'ISDST demande une date avec fuseau.');
            end
            [standard, ~] = datetime.infoZone(t.TimeZone);
            v = false(size(t.Serie));
            for k = 1:numel(t.Serie)
                v(k) = datetime.decalageZone(t.TimeZone, t.Serie(k)) > standard + 1e-9;
            end
        end
    end

    methods (Static)
        function t = avec(serie, format, zone)
            t = datetime.vide();
            t.Serie = serie;
            if nargin > 1 && ~isempty(format), t.Format = format; end
            if nargin > 2, t.TimeZone = zone; end
        end
        function t = vide()
            t = datetime(0, 1, 1);
            t.Format = 'dd-MMM-uuuu HH:mm:ss';
        end
        function e = epoquePosix(), e = matlibre_ymd2num(1970, 1, 1, 0, 0, 0); end
        function e = epoqueExcel(),  e = matlibre_ymd2num(1899, 12, 30, 0, 0, 0); end

        % --- table des fuseaux -----------------------------------------------------------
        function [noms, decalages, familles] = tableFuseaux()
%TABLEFUSEAUX Fuseaux reconnus, leur décalage d'hiver et leur règle d'été.
%   Ce n'est pas la base IANA complète : c'est une sélection des fuseaux
%   les plus employés, avec les règles en vigueur depuis 2007. Les
%   changements historiques ne sont pas suivis.
            noms = {'UTC', 'GMT', 'Z', ...
                    'Europe/London', 'Europe/Dublin', 'Europe/Lisbon', ...
                    'Europe/Paris', 'Europe/Berlin', 'Europe/Madrid', 'Europe/Rome', ...
                    'Europe/Amsterdam', 'Europe/Brussels', 'Europe/Zurich', ...
                    'Europe/Vienna', 'Europe/Stockholm', 'Europe/Oslo', ...
                    'Europe/Copenhagen', 'Europe/Warsaw', 'Europe/Prague', ...
                    'Europe/Budapest', 'Europe/Athens', 'Europe/Helsinki', ...
                    'Europe/Bucharest', 'Europe/Kiev', 'Europe/Moscow', ...
                    'America/New_York', 'America/Toronto', 'America/Chicago', ...
                    'America/Denver', 'America/Phoenix', 'America/Los_Angeles', ...
                    'America/Vancouver', 'America/Anchorage', 'America/Halifax', ...
                    'America/Sao_Paulo', 'America/Mexico_City', 'America/Bogota', ...
                    'America/Lima', 'America/Argentina/Buenos_Aires', ...
                    'Asia/Tokyo', 'Asia/Seoul', 'Asia/Shanghai', 'Asia/Hong_Kong', ...
                    'Asia/Taipei', 'Asia/Singapore', 'Asia/Bangkok', 'Asia/Jakarta', ...
                    'Asia/Kolkata', 'Asia/Karachi', 'Asia/Dubai', 'Asia/Riyadh', ...
                    'Australia/Sydney', 'Australia/Melbourne', 'Australia/Brisbane', ...
                    'Australia/Perth', 'Australia/Adelaide', 'Pacific/Auckland', ...
                    'Africa/Cairo', 'Africa/Johannesburg', 'Africa/Lagos', ...
                    'Africa/Nairobi', 'Africa/Casablanca', 'Atlantic/Reykjavik', ...
                    'Pacific/Honolulu'};
            decalages = [0, 0, 0, ...
                         0, 0, 0, ...
                         1, 1, 1, 1, ...
                         1, 1, 1, ...
                         1, 1, 1, ...
                         1, 1, 1, ...
                         1, 2, 2, ...
                         2, 2, 3, ...
                         -5, -5, -6, ...
                         -7, -7, -8, ...
                         -8, -9, -4, ...
                         -3, -6, -5, ...
                         -5, -3, ...
                         9, 9, 8, 8, ...
                         8, 8, 7, 7, ...
                         5.5, 5, 4, 3, ...
                         10, 10, 10, ...
                         8, 9.5, 12, ...
                         2, 2, 1, ...
                         3, 1, 0, ...
                         -10];
            familles = {'none', 'none', 'none', ...
                        'eu', 'eu', 'eu', ...
                        'eu', 'eu', 'eu', 'eu', ...
                        'eu', 'eu', 'eu', ...
                        'eu', 'eu', 'eu', ...
                        'eu', 'eu', 'eu', ...
                        'eu', 'eu', 'eu', ...
                        'eu', 'eu', 'none', ...
                        'us', 'us', 'us', ...
                        'us', 'none', 'us', ...
                        'us', 'us', 'us', ...
                        'none', 'none', 'none', ...
                        'none', 'none', ...
                        'none', 'none', 'none', 'none', ...
                        'none', 'none', 'none', 'none', ...
                        'none', 'none', 'none', 'none', ...
                        'au', 'au', 'none', ...
                        'none', 'au', 'nz', ...
                        'none', 'none', 'none', ...
                        'none', 'none', 'none', ...
                        'none'};
        end

        function [standard, famille] = infoZone(zone)
%INFOZONE Décalage d'hiver et règle d'heure d'été d'un fuseau.
%   Reconnaît les noms de la table, les décalages fixes écrits
%   '+HH:MM' ou '-HH', et le fuseau vide, qui vaut le temps universel.
            zone = char(zone);
            if isempty(zone) || strcmpi(zone, 'local')
                standard = 0; famille = 'none'; return
            end
            if zone(1) == '+' || zone(1) == '-'
                signe = 1;
                if zone(1) == '-', signe = -1; end
                reste = zone(2:end);
                deuxPoints = find(reste == ':', 1);
                if isempty(deuxPoints)
                    if numel(reste) == 4
                        h = str2double(reste(1:2));
                        m = str2double(reste(3:4));
                    else
                        h = str2double(reste);
                        m = 0;
                    end
                else
                    h = str2double(reste(1:deuxPoints-1));
                    m = str2double(reste(deuxPoints+1:end));
                end
                if isnan(h) || isnan(m)
                    error('MATLAB:datetime:UnknownTimeZone', ...
                          'Fuseau horaire inconnu : ''%s''.', zone);
                end
                standard = signe * (h + m / 60);
                famille = 'none';
                return
            end
            [noms, decalages, familles] = datetime.tableFuseaux();
            k = find(strcmpi(zone, noms), 1);
            if isempty(k)
                error('MATLAB:datetime:UnknownTimeZone', ...
                      'Fuseau horaire inconnu : ''%s''.', zone);
            end
            standard = decalages(k);
            famille = familles{k};
        end

        function h = decalageZone(zone, serieLocale)
%DECALAGEZONE Décalage effectif, en heures, à un instant local donné.
%   L'heure d'été est décidée sur l'heure locale d'hiver : dans l'heure
%   même de la bascule, où l'heure locale est ambiguë, le résultat suit la
%   convention de l'heure d'hiver.
            [standard, famille] = datetime.infoZone(zone);
            h = standard;
            if strcmp(famille, 'none'), return, end
            composantes = matlibre_num2ymd(serieLocale);
            annee = composantes(1);
            % Les deux bornes sont exprimées en heure locale telle que
            % l'utilisateur l'écrit : celle d'hiver au printemps, celle
            % d'été à l'automne. L'heure qui se répète à l'automne est
            % ainsi rattachée à sa première occurrence, comme le fait
            % MATLAB.
            switch famille
                case 'eu'
                    % Dernier dimanche de mars et dernier dimanche
                    % d'octobre, tous deux à 01:00 temps universel.
                    debut = datetime.dernierDimanche(annee, 3) + (1 + standard) / 24;
                    fin = datetime.dernierDimanche(annee, 10) + (2 + standard) / 24;
                    dedans = serieLocale >= debut && serieLocale < fin;
                case 'us'
                    % Deuxième dimanche de mars à 02:00 heure d'hiver,
                    % premier dimanche de novembre à 02:00 heure d'été.
                    debut = datetime.niemeDimanche(annee, 3, 2) + 2 / 24;
                    fin = datetime.niemeDimanche(annee, 11, 1) + 2 / 24;
                    dedans = serieLocale >= debut && serieLocale < fin;
                case 'au'
                    % Hémisphère sud : l'été enjambe le changement d'année.
                    debut = datetime.niemeDimanche(annee, 10, 1) + 2 / 24;
                    fin = datetime.niemeDimanche(annee, 4, 1) + 3 / 24;
                    dedans = serieLocale >= debut || serieLocale < fin;
                case 'nz'
                    debut = datetime.dernierDimanche(annee, 9) + 2 / 24;
                    fin = datetime.niemeDimanche(annee, 4, 1) + 3 / 24;
                    dedans = serieLocale >= debut || serieLocale < fin;
                otherwise
                    dedans = false;
            end
            if dedans, h = standard + 1; end
        end

        function s = niemeDimanche(annee, mois, n)
%NIEMEDIMANCHE Numéro de série du N-ième dimanche d'un mois, à minuit.
            premier = matlibre_ymd2num(annee, mois, 1, 0, 0, 0);
            jour = matlibre_weekday(premier);      % 1 = dimanche
            decalage = mod(1 - jour, 7);
            s = premier + decalage + 7 * (n - 1);
        end

        function s = dernierDimanche(annee, mois)
%DERNIERDIMANCHE Numéro de série du dernier dimanche d'un mois, à minuit.
            if mois == 12
                premierSuivant = matlibre_ymd2num(annee + 1, 1, 1, 0, 0, 0);
            else
                premierSuivant = matlibre_ymd2num(annee, mois + 1, 1, 0, 0, 0);
            end
            dernier = premierSuivant - 1;
            jour = matlibre_weekday(dernier);
            s = dernier - mod(jour - 1, 7);
        end

        function n = nomOption(nom)
            noms = {'ConvertFrom', 'InputFormat', 'Format', 'TimeZone'};
            i = find(strcmpi(nom, noms), 1);
            n = noms{i};
        end

        function s = depuisVecteur(v)
            n = size(v, 1);
            c = zeros(n, 6);
            c(:, 1:size(v, 2)) = v;
            if size(v, 2) < 3, c(:, 3) = 1; end
            s = matlibre_ymd2num(c(:, 1), c(:, 2), c(:, 3), c(:, 4), c(:, 5), c(:, 6));
            s = reshape(s, n, 1);
        end

        function s = analyser(texte, format)
            if nargin < 2, format = ''; end
            if iscellstr(texte) || (isstring(texte) && numel(texte) > 1)
                c = cellstr(texte);
                s = zeros(size(c));
                for k = 1:numel(c)
                    s(k) = datetime.analyser(c{k}, format);
                end
                return
            end
            mot = strtrim(char(texte));
            switch lower(mot)
                case 'now',       s = now(); return
                case 'today',     s = floor(now()); return
                case 'yesterday', s = floor(now()) - 1; return
                case 'tomorrow',  s = floor(now()) + 1; return
                case 'nat',       s = NaN; return
            end
            if ~isempty(format)
                s = datetime.analyserFormat(mot, format);
                return
            end
            s = datenum(mot);
        end

        function s = analyserFormat(texte, format)
            %ANALYSERFORMAT Lit une date en suivant un format documenté.
            c = struct('Year', 0, 'Month', 1, 'Day', 1, 'Hour', 0, 'Minute', 0, 'Second', 0);
            i = 1; k = 1;
            noms = {'January', 'February', 'March', 'April', 'May', 'June', 'July', ...
                    'August', 'September', 'October', 'November', 'December'};
            while k <= numel(format)
                jeton = datetime.jetonSuivant(format, k);
                largeur = numel(jeton);
                switch jeton
                    case {'uuuu', 'yyyy'}
                        c.Year = str2double(texte(i:i + 3)); i = i + 4;
                    case {'uu', 'yy'}
                        a = str2double(texte(i:i + 1)); i = i + 2;
                        if a < 50, c.Year = 2000 + a; else, c.Year = 1900 + a; end
                    case 'MMMM'
                        trouve = 0;
                        for m = 1:12
                            n = numel(noms{m});
                            if i + n - 1 <= numel(texte) && strcmpi(texte(i:i + n - 1), noms{m})
                                c.Month = m; i = i + n; trouve = 1; break
                            end
                        end
                        if ~trouve
                            error('MATLAB:datetime:ParseErr', ...
                                  'Unable to parse ''%s'' with format ''%s''.', texte, format);
                        end
                    case 'MMM'
                        for m = 1:12
                            if strcmpi(texte(i:i + 2), noms{m}(1:3)), c.Month = m; break, end
                        end
                        i = i + 3;
                    case 'MM', c.Month = str2double(texte(i:i + 1)); i = i + 2;
                    case 'dd', c.Day = str2double(texte(i:i + 1)); i = i + 2;
                    case 'HH', c.Hour = str2double(texte(i:i + 1)); i = i + 2;
                    case 'mm', c.Minute = str2double(texte(i:i + 1)); i = i + 2;
                    case 'ss', c.Second = str2double(texte(i:i + 1)); i = i + 2;
                    case 'SSS'
                        c.Second = c.Second + str2double(texte(i:i + 2)) / 1000; i = i + 3;
                    otherwise
                        i = i + largeur;   % séparateur littéral
                end
                k = k + largeur;
            end
            s = matlibre_ymd2num(c.Year, c.Month, c.Day, c.Hour, c.Minute, c.Second);
        end

        function j = jetonSuivant(format, k)
            car = format(k);
            n = 1;
            while k + n <= numel(format) && format(k + n) == car
                n = n + 1;
            end
            j = format(k:k + n - 1);
        end

        function s = limite(c, unite, serie, fin)
            n = size(c, 1);
            s = zeros(n, 1);
            for k = 1:n
                a = c(k, 1); m = c(k, 2); j = c(k, 3);
                switch unite
                    case 'year',    debut = matlibre_ymd2num(a, 1, 1);
                    case 'quarter', debut = matlibre_ymd2num(a, 3 * floor((m - 1) / 3) + 1, 1);
                    case 'month',   debut = matlibre_ymd2num(a, m, 1);
                    case 'week'
                        jour = floor(serie(k));
                        debut = jour - matlibre_weekday(jour) + 1;
                    case 'day',     debut = matlibre_ymd2num(a, m, j);
                    case 'hour',    debut = floor(serie(k) * 24) / 24;
                    case 'minute',  debut = floor(serie(k) * 1440) / 1440;
                    case 'second',  debut = floor(serie(k) * 86400) / 86400;
                    otherwise
                        error('MATLAB:datetime:UnknownUnit', ...
                              'Unrecognized time unit ''%s''.', unite);
                end
                if fin
                    switch unite
                        case 'year',    s(k) = matlibre_ymd2num(a + 1, 1, 1);
                        case 'quarter', s(k) = matlibre_addmonths(debut, 3);
                        case 'month',   s(k) = matlibre_addmonths(debut, 1);
                        case 'week',    s(k) = debut + 7;
                        case 'day',     s(k) = debut + 1;
                        case 'hour',    s(k) = debut + 1 / 24;
                        case 'minute',  s(k) = debut + 1 / 1440;
                        case 'second',  s(k) = debut + 1 / 86400;
                    end
                else
                    s(k) = debut;
                end
            end
        end

        function [mois, jours, temps] = ecart(x, y, unite)
            %ECART Écart calendaire de x vers y, en mois, jours et secondes.
            unite = lower(unite);
            signe = 1;
            if y < x, tmp = x; x = y; y = tmp; signe = -1; end
            mois = 0;
            if any(unite == 'y') || any(unite == 'm')
                cx = matlibre_num2ymd(x); cy = matlibre_num2ymd(y);
                mois = (cy(1) - cx(1)) * 12 + (cy(2) - cx(2));
                if matlibre_addmonths(x, mois) > y, mois = mois - 1; end
                x = matlibre_addmonths(x, mois);
                if ~any(unite == 'm')
                    ans_ = fix(mois / 12);
                    x = matlibre_addmonths(x, ans_ * 12 - mois);
                    mois = ans_ * 12;
                end
            end
            jours = 0;
            if any(unite == 'd')
                jours = floor(y - x);
                x = x + jours;
            end
            temps = round((y - x) * 86400 * 1e6) / 1e6;
            mois = signe * mois; jours = signe * jours; temps = signe * temps;
        end

        function s = rendre(serie, format)
            if isnan(serie), s = 'NaT'; return, end
            c = matlibre_num2ymd(serie);
            noms = {'January', 'February', 'March', 'April', 'May', 'June', 'July', ...
                    'August', 'September', 'October', 'November', 'December'};
            jours = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', ...
                     'Saturday'};
            m = max(1, min(12, c(2)));
            js = matlibre_weekday(serie);
            s = '';
            k = 1;
            while k <= numel(format)
                jeton = datetime.jetonSuivant(format, k);
                k = k + numel(jeton);
                switch jeton
                    case {'uuuu', 'yyyy'}, s = [s sprintf('%04d', c(1))];
                    case {'uu', 'yy'},     s = [s sprintf('%02d', mod(c(1), 100))];
                    case 'MMMM', s = [s noms{m}];
                    case 'MMM',  s = [s noms{m}(1:3)];
                    case 'MM',   s = [s sprintf('%02d', c(2))];
                    case 'M',    s = [s sprintf('%d', c(2))];
                    case 'dd',   s = [s sprintf('%02d', c(3))];
                    case 'd',    s = [s sprintf('%d', c(3))];
                    case 'EEEE', s = [s jours{js}];
                    case 'EEE',  s = [s jours{js}(1:3)];
                    case 'HH',   s = [s sprintf('%02d', c(4))];
                    case 'H',    s = [s sprintf('%d', c(4))];
                    case 'hh',   s = [s sprintf('%02d', mod(c(4) - 1, 12) + 1)];
                    case 'mm',   s = [s sprintf('%02d', c(5))];
                    case 'ss',   s = [s sprintf('%02d', floor(c(6)))];
                    case 'SSS',  s = [s sprintf('%03d', round(mod(c(6), 1) * 1000))];
                    case 'a'
                        if c(4) < 12, s = [s 'AM']; else, s = [s 'PM']; end
                    otherwise,   s = [s jeton];
                end
            end
        end
    end
end

function s = serieDe(x)
    if isa(x, 'datetime')
        s = x.Serie;
    elseif ischar(x) || isstring(x)
        s = datetime.analyser(x, '');
    else
        s = double(x);
    end
end
