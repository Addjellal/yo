classdef frd
%FRD Modèle de réponse fréquentielle.
%   SYS = FRD(REPONSE,FREQUENCES) crée un modèle qui ne porte que des
%   mesures : la valeur de la réponse à chaque fréquence, et rien
%   d'autre. C'est ce qu'on a quand on a mesuré un procédé au vibreur ou
%   à l'analyseur de spectre, sans en avoir tiré d'équations.
%
%   SYS = FRD(REPONSE,FREQUENCES,'Units','Hz') dit que les fréquences
%   sont en hertz ; sans cela, elles sont en radians par seconde.
%   SYS = FRD(SYS,FREQUENCES) échantillonne un modèle SS ou TF aux
%   fréquences données.
%
%   Les propriétés :
%      ResponseData   la réponse, un nombre complexe par fréquence ;
%      Frequency      les fréquences ;
%      FrequencyUnit  'rad/TimeUnit' ou 'Hz' ;
%      Ts             la période d'échantillonnage.
%
%   Les opérations + - * et INV sont définies : elles s'appliquent point
%   par point, les deux modèles devant porter les mêmes fréquences.
%   BODE, NYQUIST, SIGMA et NORM acceptent un FRD.
%
%   Un FRD ne se simule pas et n'a pas de pôles : il ne dit rien entre
%   deux points mesurés. C'est sa force — il ne suppose aucune structure —
%   et sa limite.
%
%   Exemples :
%      w = logspace(-1, 2, 50);
%      G = frd(freqresp(tf(1, [1 1]), w), w);
%      bode(G);
%      abs(G.ResponseData(1))
%
%      H = frd(tf(1, [1 0.2 1]), w);      % echantillonne un modele
%      norm(H, Inf)                        % le pic mesure
%
%   Voir aussi FREQRESP, BODE, NYQUIST, SIGMA, TF, SS, INTERP1.
    properties
        type = 'frd'
        ResponseData = []
        Frequency = []
        FrequencyUnit = 'rad/TimeUnit'
        Ts = 0
        Name = ''
    end

    methods
        function sys = frd(reponse, frequences, varargin)
            if nargin == 0
                return
            end
            if isa(reponse, 'frd')
                sys = reponse;
                if nargin >= 2 && ~isempty(frequences)
                    sys = frd.interpoler(sys, frequences);
                end
                return
            end
            if isa(reponse, 'ss') || isa(reponse, 'tf')
                if nargin < 2 || isempty(frequences)
                    error('Control:frd:NoFrequency', ...
                          'FRD needs the frequencies at which to sample the model.');
                end
                sys.ResponseData = freqresp(reponse, frequences);
                sys.Frequency = double(frequences(:));
                sys.Ts = reponse.Ts;
            else
                sys.ResponseData = reponse;
                sys.Frequency = double(frequences(:));
            end
            k = 1;
            while k + 1 <= numel(varargin)
                option = lower(char(varargin{k}));
                if strcmp(option, 'units') || strcmp(option, 'frequencyunit')
                    sys.FrequencyUnit = char(varargin{k + 1});
                elseif strcmp(option, 'ts')
                    sys.Ts = varargin{k + 1};
                elseif strcmp(option, 'name')
                    sys.Name = char(varargin{k + 1});
                else
                    error('Control:frd:BadOption', 'Unknown option ''%s''.', option);
                end
                k = k + 2;
            end
            if numel(varargin) == 1 && isnumeric(varargin{1})
                sys.Ts = varargin{1};
            end
        end

        function varargout = size(sys, dimension)
            d = size(sys.ResponseData);
            if numel(d) < 3
                d = [1 1];
            else
                d = d(1:2);
            end
            if nargin >= 2
                varargout{1} = d(min(dimension, 2));
                return
            end
            if nargout <= 1
                varargout{1} = d;
            else
                varargout{1} = d(1);
                varargout{2} = d(2);
            end
        end

        function r = plus(a, b), r = frd.combiner(a, b, @(x, y) x + y); end
        function r = minus(a, b), r = frd.combiner(a, b, @(x, y) x - y); end
        function r = mtimes(a, b), r = frd.combiner(a, b, @(x, y) x .* y); end
        function r = times(a, b), r = frd.combiner(a, b, @(x, y) x .* y); end
        function r = mrdivide(a, b), r = frd.combiner(a, b, @(x, y) x ./ y); end
        function r = uminus(a)
            a = frd.versFrd(a, []);
            r = a;
            r.ResponseData = -a.ResponseData;
        end
        function r = inv(a)
            r = a;
            r.ResponseData = 1 ./ a.ResponseData;
        end
        function [module, phase, w] = bode(sys, w)
            if nargin >= 2 && ~isempty(w)
                sys = frd.interpoler(sys, w);
            end
            w = sys.Frequency;
            valeurs = sys.ResponseData(:);
            module = abs(valeurs);
            phase = unwrap(angle(valeurs)) * 180 / pi;
            if nargout == 0
                subplot(2, 1, 1);
                loglog(w, module);
                ylabel('gain');
                grid('on');
                subplot(2, 1, 2);
                semilogx(w, phase);
                ylabel('phase (deg)');
                xlabel('pulsation (rad/s)');
                grid('on');
                clear module
            end
        end
        function n = norm(sys, type)
            if nargin < 2 || (isnumeric(type) && type == 2)
                n = sqrt(trapz(sys.Frequency, abs(sys.ResponseData(:)) .^ 2) / pi);
            else
                n = max(abs(sys.ResponseData(:)));
            end
        end
        function H = freqresp(sys, w)
            if nargin < 2 || isempty(w)
                H = sys.ResponseData;
                return
            end
            H = frd.interpoler(sys, w).ResponseData;
        end
        function disp(sys)
            fprintf('  reponse frequentielle mesuree : %d points, de %g a %g rad/s\n', ...
                    numel(sys.Frequency), min(sys.Frequency), max(sys.Frequency));
        end
    end

    methods (Static)
        function r = versFrd(x, frequences)
        %VERSFRD Fait un FRD de ce qu'on lui donne.
            if isa(x, 'frd')
                r = x;
                return
            end
            if isa(x, 'ss') || isa(x, 'tf')
                r = frd(x, frequences);
                return
            end
            r = frd(repmat(double(x), numel(frequences), 1), frequences);
        end

        function r = combiner(a, b, operation)
        %COMBINER Applique une opération point par point aux deux réponses.
            if isa(a, 'frd')
                frequences = a.Frequency;
            else
                frequences = b.Frequency;
            end
            a = frd.versFrd(a, frequences);
            b = frd.versFrd(b, frequences);
            if numel(a.Frequency) ~= numel(b.Frequency) || ...
               max(abs(a.Frequency - b.Frequency)) > 1e-9 * max(1, max(a.Frequency))
                b = frd.interpoler(b, a.Frequency);
            end
            r = a;
            r.ResponseData = operation(a.ResponseData(:), b.ResponseData(:));
        end

        function r = interpoler(sys, frequences)
        %INTERPOLER La réponse aux fréquences demandées, par interpolation.
            frequences = double(frequences(:));
            valeurs = sys.ResponseData(:);
            reelle = interp1(sys.Frequency, real(valeurs), frequences, 'linear', 'extrap');
            imaginaire = interp1(sys.Frequency, imag(valeurs), frequences, ...
                                 'linear', 'extrap');
            r = sys;
            r.ResponseData = reelle + 1i * imaginaire;
            r.Frequency = frequences;
        end
    end
end
