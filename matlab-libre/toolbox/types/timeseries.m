classdef timeseries
%TIMESERIES Un signal échantillonné : ses valeurs et leurs instants.
%   TS = TIMESERIES(DATA) crée une série dont les instants sont 0, 1, 2...
%   TS = TIMESERIES(DATA,TIME) donne les instants, croissants. DATA porte
%   un échantillon par ligne — un scalaire, ou une ligne de valeurs, par
%   instant — ou, pour des échantillons matriciels, un tableau m-par-n-
%   par-N, l'instant en dernier.
%   TS = TIMESERIES(...,'Name',NOM) nomme la série.
%
%   Ses propriétés : Name ('unnamed'), Data, Time, Length (le nombre
%   d'instants), TimeInfo (Units, Start, End, Length, Increment),
%   DataInfo (Units, Interpolation) et IsTimeFirst.
%
%   GETDATASAMPLES(TS,I) rend les échantillons de rangs I ; RESAMPLE(TS,T)
%   rééchantillonne par interpolation linéaire, et PLOT(TS) trace la série
%   contre son temps.
%
%   C'est la forme que prennent, dans Simulink, les signaux d'un bloc To
%   Workspace au format 'Timeseries', et que lit un From Workspace.
%
%   Exemple :
%      ts = timeseries([0; 2; 4], [0 1 2], 'Name', 'vitesse');
%      ts.Length                         % 3
%      v = resample(ts, 0.5);
%      v.Data                            % 1
%
%   Voir aussi SIM, ADD_BLOCK.
    properties
        Name = 'unnamed'
        Data = []
        Time = zeros(0, 1)
        TimeInfo = struct('Units', 'seconds', 'Start', [], 'End', [], 'Length', 0, ...
                          'Increment', NaN)
        DataInfo = struct('Units', '', 'Interpolation', 'linear')
        IsTimeFirst = true
    end
    properties (Dependent)
        Length
    end
    methods
        function ts = timeseries(data, varargin)
            if nargin == 0
                return
            end
            arguments_ = varargin;
            temps = [];
            if ~isempty(arguments_) && ~(ischar(arguments_{1}) || isstring(arguments_{1}))
                temps = arguments_{1};
                arguments_ = arguments_(2:end);
            end
            if ~isempty(arguments_) && (ischar(arguments_{1}) || isstring(arguments_{1})) && ...
               ~strcmpi(arguments_{1}, 'Name') && mod(numel(arguments_), 2) == 1
                ts.Name = char(arguments_{1});   % timeseries(data, time, 'nom')
                arguments_ = arguments_(2:end);
            end
            for k = 1:2:numel(arguments_)
                if k + 1 > numel(arguments_) || ~strcmpi(arguments_{k}, 'Name')
                    error('MATLAB:timeseries:InvalidOption', ...
                          'timeseries prend ses options par paires, dont ''Name''.');
                end
                ts.Name = char(arguments_{k + 1});
            end
            if isvector(data) && ~isempty(data) && (isempty(temps) || numel(data) == numel(temps))
                data = data(:);
            end
            if isempty(temps)
                n = size(data, 1);
                if ndims(data) > 2
                    n = size(data, ndims(data));
                end
                temps = (0:n - 1)';
            end
            temps = double(temps(:));
            if any(diff(temps) < 0)
                error('MATLAB:timeseries:TimeNotMonotonic', ...
                      'Les instants d''une timeseries doivent etre croissants.');
            end
            if size(data, 1) == numel(temps)
                ts.IsTimeFirst = true;
            elseif size(data, ndims(data)) == numel(temps)
                ts.IsTimeFirst = false;
            else
                error('MATLAB:timeseries:SizeMismatch', ...
                      ['La timeseries a %d instant(s), et ses donnees ne portent pas autant ' ...
                       'd''echantillons.'], numel(temps));
            end
            ts.Data = data;
            ts.Time = temps;
            ts = majInfos(ts);
        end
        function n = get.Length(ts)
            n = numel(ts.Time);
        end
        function ts = set.Time(ts, t)
            ts.Time = double(t(:));
            ts = majInfos(ts);
        end
        function d = getdatasamples(ts, i)
            if ts.IsTimeFirst
                d = ts.Data(i, :);
                if isvector(ts.Data)
                    d = ts.Data(i);
                end
            else
                autres = repmat({':'}, 1, ndims(ts.Data) - 1);
                d = ts.Data(autres{:}, i);
            end
        end
        function r = resample(ts, t)
            t = double(t(:));
            if ~ts.IsTimeFirst
                error('MATLAB:timeseries:Resample', ...
                      'RESAMPLE ne sait reechantillonner que des echantillons en lignes.');
            end
            donnees = double(ts.Data);
            if ts.Length == 1
                valeurs = repmat(donnees, numel(t), 1);
            elseif strcmpi(ts.DataInfo.Interpolation, 'zoh')
                valeurs = interp1(ts.Time, donnees, t, 'previous', 'extrap');
            else
                valeurs = interp1(ts.Time, donnees, t, 'linear', 'extrap');
            end
            r = ts;
            r.Data = valeurs;
            r.Time = t;
        end
        function h = plot(ts, varargin)
            if ts.IsTimeFirst
                hh = plot(ts.Time, ts.Data, varargin{:});
            else
                hh = plot(ts.Time, reshape(ts.Data, [], ts.Length).', varargin{:});
            end
            title(sprintf('Time Series Plot:%s', ts.Name));
            xlabel(sprintf('Time (%s)', ts.TimeInfo.Units));
            if nargout > 0
                h = hh;
            end
        end
        function oui = isempty(ts)
            oui = ts.Length == 0;
        end
        function disp(ts)
            fprintf('  timeseries\n\n  Common Properties:\n');
            fprintf('            Name: ''%s''\n', ts.Name);
            fprintf('            Time: [%dx1 double]\n', ts.Length);
            fprintf('        TimeInfo: [1x1 struct]\n');
            d = size(ts.Data);
            fprintf('            Data: [%s %s]\n', strjoin(arrayfun(@num2str, d, ...
                    'UniformOutput', false), 'x'), class(ts.Data));
            fprintf('        DataInfo: [1x1 struct]\n\n');
        end
    end
end

function ts = majInfos(ts)
    ts.TimeInfo.Length = numel(ts.Time);
    if isempty(ts.Time)
        ts.TimeInfo.Start = [];
        ts.TimeInfo.End = [];
        ts.TimeInfo.Increment = NaN;
    else
        ts.TimeInfo.Start = ts.Time(1);
        ts.TimeInfo.End = ts.Time(end);
        pas = diff(ts.Time);
        if ~isempty(pas) && all(abs(pas - pas(1)) <= 1e-12 * max(1, abs(pas(1))))
            ts.TimeInfo.Increment = pas(1);
        else
            ts.TimeInfo.Increment = NaN;
        end
    end
end
