classdef duration
%DURATION Durée, longueur de temps sans origine.
%   D = DURATION(H,M,S) construit une durée à partir d'heures, minutes et
%   secondes. D = DURATION(H,M,S,MS) ajoute des millisecondes.
%   D = DURATION(X) où X est numérique interprète X comme des secondes.
%
%   La propriété Format contrôle l'affichage. Les valeurs reconnues sont
%   'y', 'd', 'h', 'm', 's' (un nombre suivi de l'unité) et les formats
%   d'horloge 'dd:hh:mm:ss', 'hh:mm:ss', 'mm:ss', 'hh:mm', éventuellement
%   suivis d'un point et de un à neuf 'S' pour les fractions de seconde.
%
%   Exemple :
%      d = hours(2) + minutes(30)   % 2.5 hr
%      seconds(d)                   % 9000
%      d.Format = 'hh:mm:ss';
%      char(d)                      % '02:30:00'
%
%   Voir aussi SECONDS, MINUTES, HOURS, DAYS, YEARS, CALENDARDURATION.
    properties
        Secondes = 0        % stockage interne : secondes (réel)
        Format = 'hh:mm:ss'
    end
    methods
        function d = duration(a, b, c, ms)
            if nargin == 0
                d.Secondes = 0;
            elseif nargin == 1
                if ischar(a) || isstring(a)
                    d.Secondes = duration.analyser(a);
                elseif isa(a, 'duration')
                    d.Secondes = a.Secondes;
                    d.Format = a.Format;
                else
                    d.Secondes = double(a);
                end
            else
                if nargin < 3, c = 0; end
                if nargin < 4, ms = 0; end
                d.Secondes = double(a) * 3600 + double(b) * 60 + double(c) + double(ms) / 1000;
            end
        end

        % --- arithmétique -------------------------------------------------
        function r = plus(a, b)
            if isa(a, 'duration') && isa(b, 'datetime')
                r = b + a; return
            end
            r = duration.avec(valeurSecondes(a) + valeurSecondes(b), formatDe(a, b));
        end
        function r = minus(a, b)
            r = duration.avec(valeurSecondes(a) - valeurSecondes(b), formatDe(a, b));
        end
        function r = uminus(a), r = duration.avec(-a.Secondes, a.Format); end
        function r = uplus(a), r = a; end
        function r = times(a, b)
            if isa(a, 'duration')
                r = duration.avec(a.Secondes .* double(b), a.Format);
            else
                r = duration.avec(double(a) .* b.Secondes, b.Format);
            end
        end
        function r = mtimes(a, b), r = times(a, b); end
        function r = rdivide(a, b)
            if isa(b, 'duration') && isa(a, 'duration')
                r = a.Secondes ./ b.Secondes;      % rapport sans dimension
            elseif isa(a, 'duration')
                r = duration.avec(a.Secondes ./ double(b), a.Format);
            else
                r = double(a) ./ b.Secondes;
            end
        end
        function r = mrdivide(a, b), r = rdivide(a, b); end
        function r = ldivide(a, b), r = rdivide(b, a); end
        function r = mldivide(a, b), r = rdivide(b, a); end
        function r = abs(a), r = duration.avec(abs(a.Secondes), a.Format); end
        function r = floor(a), r = duration.avec(floor(a.Secondes), a.Format); end
        function r = ceil(a), r = duration.avec(ceil(a.Secondes), a.Format); end
        function r = round(a, n)
            if nargin < 2
                r = duration.avec(round(a.Secondes), a.Format);
            else
                r = duration.avec(round(a.Secondes, n), a.Format);
            end
        end
        function r = fix(a), r = duration.avec(fix(a.Secondes), a.Format); end
        function r = mod(a, b), r = duration.avec(mod(valeurSecondes(a), valeurSecondes(b)), formatDe(a, b)); end
        function r = rem(a, b), r = duration.avec(rem(valeurSecondes(a), valeurSecondes(b)), formatDe(a, b)); end
        function r = sum(a, varargin), r = duration.avec(sum(a.Secondes, varargin{:}), a.Format); end
        function r = cumsum(a, varargin), r = duration.avec(cumsum(a.Secondes, varargin{:}), a.Format); end
        function r = diff(a, varargin), r = duration.avec(diff(a.Secondes, varargin{:}), a.Format); end
        function r = mean(a, varargin), r = duration.avec(mean(a.Secondes, varargin{:}), a.Format); end
        function r = median(a, varargin), r = duration.avec(median(a.Secondes, varargin{:}), a.Format); end
        function r = std(a, varargin), r = duration.avec(std(a.Secondes, varargin{:}), a.Format); end
        function [r, i] = max(a, b, varargin)
            if nargin >= 2 && ~isempty(b)
                [v, i] = max(valeurSecondes(a), valeurSecondes(b), varargin{:});
            else
                [v, i] = max(a.Secondes, [], varargin{:});
            end
            r = duration.avec(v, a.Format);
        end
        function [r, i] = min(a, b, varargin)
            if nargin >= 2 && ~isempty(b)
                [v, i] = min(valeurSecondes(a), valeurSecondes(b), varargin{:});
            else
                [v, i] = min(a.Secondes, [], varargin{:});
            end
            r = duration.avec(v, a.Format);
        end
        function [r, i] = sort(a, varargin)
            [v, i] = sort(a.Secondes, varargin{:});
            r = duration.avec(v, a.Format);
        end

        % --- comparaisons -------------------------------------------------
        function r = lt(a, b), r = valeurSecondes(a) < valeurSecondes(b); end
        function r = le(a, b), r = valeurSecondes(a) <= valeurSecondes(b); end
        function r = gt(a, b), r = valeurSecondes(a) > valeurSecondes(b); end
        function r = ge(a, b), r = valeurSecondes(a) >= valeurSecondes(b); end
        function r = eq(a, b), r = valeurSecondes(a) == valeurSecondes(b); end
        function r = ne(a, b), r = valeurSecondes(a) ~= valeurSecondes(b); end
        function r = isequal(a, b), r = isequal(valeurSecondes(a), valeurSecondes(b)); end
        function r = isnan(a), r = isnan(a.Secondes); end
        function r = isfinite(a), r = isfinite(a.Secondes); end
        function r = isinf(a), r = isinf(a.Secondes); end

        % --- taille et forme ----------------------------------------------
        function n = numel(d), n = numel(d.Secondes); end
        function s = size(d, dim)
            if nargin > 1
                s = size(d.Secondes, dim);
            else
                s = size(d.Secondes);
            end
        end
        function n = length(d), n = length(d.Secondes); end
        function n = ndims(d), n = ndims(d.Secondes); end
        function r = isempty(d), r = isempty(d.Secondes); end
        function r = isscalar(d), r = isscalar(d.Secondes); end
        function r = isvector(d), r = isvector(d.Secondes); end
        function r = iscolumn(d), r = iscolumn(d.Secondes); end
        function r = isrow(d), r = isrow(d.Secondes); end
        function r = transpose(d), r = duration.avec(d.Secondes.', d.Format); end
        function r = ctranspose(d), r = duration.avec(d.Secondes', d.Format); end
        function r = reshape(d, varargin), r = duration.avec(reshape(d.Secondes, varargin{:}), d.Format); end
        function r = horzcat(varargin)
            v = []; f = '';
            for k = 1:numel(varargin)
                a = varargin{k};
                if isempty(f) && isa(a, 'duration'), f = a.Format; end
                v = [v, reshape(valeurSecondes(a), 1, [])];
            end
            if isempty(f), f = 'hh:mm:ss'; end
            r = duration.avec(v, f);
        end
        function r = vertcat(varargin)
            v = []; f = '';
            for k = 1:numel(varargin)
                a = varargin{k};
                if isempty(f) && isa(a, 'duration'), f = a.Format; end
                v = [v; reshape(valeurSecondes(a), [], 1)];
            end
            if isempty(f), f = 'hh:mm:ss'; end
            r = duration.avec(v, f);
        end
        function e = end(d, k, n)
            if n == 1
                e = numel(d.Secondes);
            else
                e = size(d.Secondes, k);
            end
        end

        % --- indexation -----------------------------------------------------
        function varargout = subsref(d, s)
            switch s(1).type
                case '()'
                    indices = s(1).subs;
                    r = duration.avec(d.Secondes(indices{:}), d.Format);
                    if numel(s) > 1
                        r = appliquerReste(r, s(2:end));
                    end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'Secondes'
                            r = d.Secondes;
                        case 'Format'
                            r = d.Format;
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                arguments_ = s(2).subs;
                                r = feval(nom, d, arguments_{:});
                                s(2) = [];
                            else
                                r = feval(nom, d);
                            end
                    end
                    if numel(s) > 1
                        r = appliquerReste(r, s(2:end));
                    end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:duration:badSubscript', ...
                          'Brace indexing is not supported for duration.');
            end
        end

        function d = subsasgn(d, s, valeur)
            switch s(1).type
                case '()'
                    indices = s(1).subs;
                    if isa(valeur, 'duration')
                        valeur = valeur.Secondes;
                    end
                    d.Secondes(indices{:}) = valeur;
                case '.'
                    d.(s(1).subs) = valeur;
                otherwise
                    error('MATLAB:duration:badSubscript', ...
                          'Unsupported assignment for duration.');
            end
        end

        % --- conversions et affichage ---------------------------------------
        function t = char(d)
            v = d.Secondes;
            t = '';
            for k = 1:numel(v)
                ligne = duration.rendre(v(k), d.Format);
                if k == 1
                    t = ligne;
                else
                    t = strvcat(t, ligne); %#ok<VCAT>
                end
            end
        end
        function c = cellstr(d)
            v = d.Secondes;
            c = cell(size(v));
            for k = 1:numel(v)
                c{k} = duration.rendre(v(k), d.Format);
            end
        end
        function s = string(d)
            c = cellstr(d);
            s = string(c);
        end
        function disp(d)
            v = d.Secondes;
            if isempty(v)
                fprintf('  0x0 duration\n');
                return
            end
            [nl, nc] = size(v);
            for i = 1:nl
                ligne = '';
                for j = 1:nc
                    ligne = [ligne '   ' duration.rendre(v(i, j), d.Format)]; %#ok<AGROW>
                end
                fprintf('%s\n', ligne);
            end
        end
    end

    methods (Static)
        function d = avec(secondes, format)
            %AVEC Fabrique une durée en imposant le format d'affichage.
            d = duration(secondes);
            d.Format = format;
        end

        function s = rendre(x, format)
            %RENDRE Texte d'une valeur en secondes selon le format donné.
            if isnan(x), s = 'NaN'; return, end
            if isinf(x)
                if x > 0, s = 'Inf'; else, s = '-Inf'; end
                return
            end
            switch format
                case 'y', s = [duration.nombre(x / 31556952) ' yr'];  return
                case 'd', s = [duration.nombre(x / 86400) ' day'];    return
                case 'h', s = [duration.nombre(x / 3600) ' hr'];      return
                case 'm', s = [duration.nombre(x / 60) ' min'];       return
                case 's', s = [duration.nombre(x) ' sec'];            return
            end
            signe = '';
            if x < 0, signe = '-'; x = -x; end
            % Nombre de décimales demandé par les 'S' finaux.
            dec = 0;
            base = format;
            p = strfind(format, '.');
            if ~isempty(p)
                base = format(1:p(1) - 1);
                dec = numel(format) - p(1);
            end
            if dec > 0
                x = round(x * 10^dec) / 10^dec;
            else
                x = round(x);
            end
            switch base
                case 'dd:hh:mm:ss'
                    j = floor(x / 86400); reste = x - j * 86400;
                    h = floor(reste / 3600); reste = reste - h * 3600;
                    m = floor(reste / 60); sec = reste - m * 60;
                    s = sprintf('%02d:%02d:%02d:%s', j, h, m, duration.secTexte(sec, dec));
                case 'hh:mm:ss'
                    h = floor(x / 3600); reste = x - h * 3600;
                    m = floor(reste / 60); sec = reste - m * 60;
                    s = sprintf('%02d:%02d:%s', h, m, duration.secTexte(sec, dec));
                case 'mm:ss'
                    m = floor(x / 60); sec = x - m * 60;
                    s = sprintf('%02d:%s', m, duration.secTexte(sec, dec));
                case 'hh:mm'
                    h = floor(x / 3600); m = floor((x - h * 3600) / 60);
                    s = sprintf('%02d:%02d', h, m);
                otherwise
                    error('MATLAB:duration:UnknownFormat', ...
                          'Unrecognized duration display format ''%s''.', format);
            end
            s = [signe s];
        end

        function t = secTexte(sec, dec)
            if dec > 0
                t = sprintf('%0*.*f', dec + 3, dec, sec);
            else
                t = sprintf('%02d', round(sec));
            end
        end

        function t = nombre(x)
            if x == fix(x) && abs(x) < 1e15
                t = sprintf('%d', x);
            else
                t = sprintf('%.5g', x);
            end
        end

        function s = analyser(texte)
            %ANALYSER Lit 'hh:mm:ss' ou 'dd:hh:mm:ss' et rend des secondes.
            texte = char(texte);
            signe = 1;
            if ~isempty(texte) && texte(1) == '-'
                signe = -1; texte(1) = [];
            end
            morceaux = strsplit(texte, ':');
            v = zeros(1, numel(morceaux));
            for k = 1:numel(morceaux)
                v(k) = str2double(morceaux{k});
            end
            switch numel(v)
                case 1, s = v(1);
                case 2, s = v(1) * 60 + v(2);
                case 3, s = v(1) * 3600 + v(2) * 60 + v(3);
                case 4, s = v(1) * 86400 + v(2) * 3600 + v(3) * 60 + v(4);
                otherwise
                    error('MATLAB:duration:ParseErr', ...
                          'Unable to interpret ''%s'' as a duration.', texte);
            end
            s = signe * s;
        end
    end
end

function s = valeurSecondes(x)
    if isa(x, 'duration')
        s = x.Secondes;
    else
        s = double(x);
    end
end

function f = formatDe(a, b)
    if isa(a, 'duration')
        f = a.Format;
    elseif isa(b, 'duration')
        f = b.Format;
    else
        f = 'hh:mm:ss';
    end
end
