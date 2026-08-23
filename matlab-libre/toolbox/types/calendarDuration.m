classdef calendarDuration
%CALENDARDURATION Durée exprimée en unités de calendrier.
%   CD = CALENDARDURATION(Y,M,D) construit une durée de Y années, M mois et
%   D jours. CALENDARDURATION(Y,M,D,H,MI,S) ajoute une partie horaire.
%
%   Une durée de calendrier n'est pas une durée fixe : un mois vaut 28, 29,
%   30 ou 31 jours selon la date à laquelle on l'ajoute. Les composantes
%   sont donc rangées séparément : mois, jours, et temps en secondes.
%
%   Exemple :
%      cd = calmonths(3) + caldays(2)   % 3mo 2d
%      calmonths(cd)                    % 3
%
%   Voir aussi CALYEARS, CALQUARTERS, CALMONTHS, CALWEEKS, CALDAYS, TIME.
    properties
        Mois = 0        % nombre entier de mois (années comprises)
        Jours = 0       % nombre entier de jours
        Temps = 0       % secondes
        Format = 'ymdt'
    end
    methods
        function cd = calendarDuration(y, m, d, h, mi, s)
            if nargin == 0
                return
            end
            if nargin == 1
                if isa(y, 'calendarDuration')
                    cd = y; return
                end
                cd.Jours = double(y); return
            end
            if nargin < 3, d = 0; end
            if nargin < 4, h = 0; end
            if nargin < 5, mi = 0; end
            if nargin < 6, s = 0; end
            cd.Mois = double(y) * 12 + double(m);
            cd.Jours = double(d);
            cd.Temps = double(h) * 3600 + double(mi) * 60 + double(s);
        end

        function r = plus(a, b)
            if isa(b, 'datetime') || isa(a, 'datetime')
                if isa(a, 'datetime'), r = a + b; else, r = b + a; end
                return
            end
            [am, aj, at] = composantes(a);
            [bm, bj, bt] = composantes(b);
            r = calendarDuration.depuis(am + bm, aj + bj, at + bt);
        end
        function r = minus(a, b)
            [am, aj, at] = composantes(a);
            [bm, bj, bt] = composantes(b);
            r = calendarDuration.depuis(am - bm, aj - bj, at - bt);
        end
        function r = uminus(a)
            r = calendarDuration.depuis(-a.Mois, -a.Jours, -a.Temps);
        end
        function r = times(a, b)
            if isa(a, 'calendarDuration')
                k = double(b); c = a;
            else
                k = double(a); c = b;
            end
            if any(k(:) ~= fix(k(:)))
                error('MATLAB:calendarDuration:MustBeInteger', ...
                      'Calendar durations can be multiplied only by integers.');
            end
            r = calendarDuration.depuis(c.Mois .* k, c.Jours .* k, c.Temps .* k);
        end
        function r = mtimes(a, b), r = times(a, b); end

        function r = eq(a, b)
            [am, aj, at] = composantes(a);
            [bm, bj, bt] = composantes(b);
            r = (am == bm) & (aj == bj) & (at == bt);
        end
        function r = ne(a, b), r = ~eq(a, b); end
        function r = isequal(a, b), r = all(reshape(eq(a, b), 1, [])); end

        function n = numel(cd), n = numel(cd.Mois); end
        function s = size(cd, dim)
            if nargin > 1, s = size(cd.Mois, dim); else, s = size(cd.Mois); end
        end
        function n = length(cd), n = length(cd.Mois); end
        function r = isempty(cd), r = isempty(cd.Mois); end
        function r = transpose(cd)
            r = calendarDuration.depuis(cd.Mois.', cd.Jours.', cd.Temps.');
        end
        function r = ctranspose(cd)
            r = calendarDuration.depuis(cd.Mois', cd.Jours', cd.Temps');
        end
        function r = reshape(cd, varargin)
            r = calendarDuration.depuis(reshape(cd.Mois, varargin{:}), ...
                                        reshape(cd.Jours, varargin{:}), ...
                                        reshape(cd.Temps, varargin{:}));
        end
        function r = horzcat(varargin)
            m = []; j = []; t = [];
            for k = 1:numel(varargin)
                [a, b, c] = composantes(varargin{k});
                m = [m, reshape(a, 1, [])]; j = [j, reshape(b, 1, [])];
                t = [t, reshape(c, 1, [])];
            end
            r = calendarDuration.depuis(m, j, t);
        end
        function r = vertcat(varargin)
            m = []; j = []; t = [];
            for k = 1:numel(varargin)
                [a, b, c] = composantes(varargin{k});
                m = [m; reshape(a, [], 1)]; j = [j; reshape(b, [], 1)];
                t = [t; reshape(c, [], 1)];
            end
            r = calendarDuration.depuis(m, j, t);
        end
        function e = end(cd, k, n)
            if n == 1, e = numel(cd.Mois); else, e = size(cd.Mois, k); end
        end

        function varargout = subsref(cd, s)
            switch s(1).type
                case '()'
                    ind = s(1).subs;
                    r = calendarDuration.depuis(cd.Mois(ind{:}), cd.Jours(ind{:}), ...
                                                cd.Temps(ind{:}));
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'Mois',   r = cd.Mois;
                        case 'Jours',  r = cd.Jours;
                        case 'Temps',  r = cd.Temps;
                        case 'Format', r = cd.Format;
                        otherwise,     r = feval(nom, cd);
                    end
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:calendarDuration:badSubscript', ...
                          'Brace indexing is not supported for calendarDuration.');
            end
        end

        function cd = subsasgn(cd, s, valeur)
            switch s(1).type
                case '.'
                    cd.(s(1).subs) = valeur;
                case '()'
                    ind = s(1).subs;
                    v = calendarDuration(valeur);
                    cd.Mois(ind{:}) = v.Mois;
                    cd.Jours(ind{:}) = v.Jours;
                    cd.Temps(ind{:}) = v.Temps;
                otherwise
                    error('MATLAB:calendarDuration:badSubscript', ...
                          'Unsupported assignment for calendarDuration.');
            end
        end

        function t = char(cd)
            t = '';
            for k = 1:numel(cd.Mois)
                ligne = calendarDuration.rendre(cd.Mois(k), cd.Jours(k), cd.Temps(k));
                if k == 1, t = ligne; else, t = strvcat(t, ligne); end %#ok<VCAT>
            end
        end
        function c = cellstr(cd)
            c = cell(size(cd.Mois));
            for k = 1:numel(cd.Mois)
                c{k} = calendarDuration.rendre(cd.Mois(k), cd.Jours(k), cd.Temps(k));
            end
        end
        function disp(cd)
            if isempty(cd.Mois), fprintf('  0x0 calendarDuration\n'); return, end
            [nl, nc] = size(cd.Mois);
            for i = 1:nl
                ligne = '';
                for j = 1:nc
                    ligne = [ligne '   ' ...
                             calendarDuration.rendre(cd.Mois(i, j), cd.Jours(i, j), ...
                                                     cd.Temps(i, j))]; %#ok<AGROW>
                end
                fprintf('%s\n', ligne);
            end
        end
    end

    methods (Static)
        function cd = depuis(mois, jours, temps)
            cd = calendarDuration();
            cd.Mois = mois; cd.Jours = jours; cd.Temps = temps;
        end

        function s = rendre(mois, jours, temps)
            morceaux = {};
            ans_ = fix(mois / 12);
            mo = mois - ans_ * 12;
            if ans_ ~= 0, morceaux{end + 1} = sprintf('%dy', ans_); end
            if mo ~= 0,   morceaux{end + 1} = sprintf('%dmo', mo); end
            if jours ~= 0, morceaux{end + 1} = sprintf('%dd', jours); end
            if temps ~= 0
                morceaux{end + 1} = duration.rendre(temps, 'hh:mm:ss');
            end
            if isempty(morceaux)
                s = '0d';
            else
                s = strjoin(morceaux, ' ');
            end
        end
    end
end

function [mois, jours, temps] = composantes(x)
    if isa(x, 'calendarDuration')
        mois = x.Mois; jours = x.Jours; temps = x.Temps;
    elseif isa(x, 'duration')
        mois = 0; jours = 0; temps = seconds(x);
    else
        mois = 0; jours = double(x); temps = 0;
    end
end
