classdef cwtfilterbank
%CWTFILTERBANK Banc de filtres d'une transformée en ondelettes continue.
%   FB = CWTFILTERBANK() construit le banc par défaut : ondelette de
%   Morse, mille vingt-quatre points, dix voix par octave.
%   FB = CWTFILTERBANK('Nom',valeur,...) le règle.
%
%   Options :
%      'Wavelet'            'Morse' (défaut), 'amor' ou 'bump'
%      'SignalLength'       1024
%      'SamplingFrequency'  en hertz ; les fréquences rendues le sont
%      'SamplingPeriod'     durée entre échantillons, exclut la précédente
%      'FrequencyLimits'    [fmin fmax] ; par défaut CWTFREQBOUNDS
%      'VoicesPerOctave'    10, entre 1 et 48
%      'TimeBandwidth'      produit temps-fréquence de Morse, 60
%      'WaveletParameters'  [gamma beta] de Morse
%      'Boundary'           'reflection' (défaut) ou 'periodic'
%
%   Un banc de filtres est la bonne façon de voir la transformée
%   continue : une même ondelette dilatée en une suite d'échelles, chacune
%   devenant un filtre passe-bande. Les calculer une fois pour toutes fait
%   la différence quand on analyse plusieurs signaux de même longueur.
%
%   Méthodes :
%      WT                 coefficients, fréquences, cône d'influence
%      FREQZ              réponse en fréquence de chaque filtre
%      CENTERFREQUENCIES  fréquence centrale de chaque filtre
%      CENTERPERIODS      périodes correspondantes
%      SCALES             échelles
%      WAVELETS           ondelettes en temps
%      QFACTOR            facteur de qualité
%      TIMESPECTRUM       spectre moyenné sur les échelles
%      SCALESPECTRUM      spectre moyenné sur le temps
%
%   Exemple :
%      fb = cwtfilterbank('SignalLength', 1024, 'SamplingFrequency', 1000);
%      t = (0:1023) / 1000;
%      [cfs, f] = wt(fb, cos(2 * pi * 100 * t));
%      [~, k] = max(mean(abs(cfs), 2));
%      f(k)                        % voisin de 100
%
%   Voir aussi CWT, CWTFREQBOUNDS, WSST, WCOHERENCE, ONDELETTEANALYTIQUE.
    properties (SetAccess = private)
        Wavelet = 'Morse'
        SignalLength = 1024
        SamplingFrequency = []
        SamplingPeriod = []
        FrequencyLimits = []
        VoicesPerOctave = 10
        TimeBandwidth = 60
        WaveletParameters = []
        Boundary = 'reflection'
    end
    properties (Access = private)
        Echelles = []
        Filtres = []
        Pic = 0
        SigmaT = 0
        Parametres = []
    end
    methods
        function obj = cwtfilterbank(varargin)
            for k = 1:2:numel(varargin)
                nom = validatestring(varargin{k}, ...
                    {'Wavelet', 'SignalLength', 'SamplingFrequency', ...
                     'SamplingPeriod', 'FrequencyLimits', 'VoicesPerOctave', ...
                     'TimeBandwidth', 'WaveletParameters', 'Boundary'}, ...
                    'cwtfilterbank');
                obj.(nom) = varargin{k + 1};
            end
            if ~isempty(obj.SamplingFrequency) && ~isempty(obj.SamplingPeriod)
                error('wavelet:cwtfilterbank:Cadence', ...
                      'SamplingFrequency et SamplingPeriod s''excluent.');
            end
            if obj.VoicesPerOctave < 1 || obj.VoicesPerOctave > 48
                error('wavelet:cwtfilterbank:Voix', ...
                      'VoicesPerOctave doit être entre 1 et 48.');
            end
            obj.Wavelet = char(obj.Wavelet);
            if isempty(obj.WaveletParameters) && strcmpi(obj.Wavelet, 'Morse')
                obj.WaveletParameters = [3 obj.TimeBandwidth];
            end
            % MATLAB nomme WaveletParameters le couple [gamma produit] ;
            % l'ondelette est définie par [gamma beta], beta = produit/gamma.
            if strcmpi(obj.Wavelet, 'Morse')
                couple = double(obj.WaveletParameters);
                obj.Parametres = [couple(1), couple(2) / couple(1)];
                obj.TimeBandwidth = couple(2);
            else
                obj.Parametres = obj.WaveletParameters;
            end
            obj = construire(obj);
        end

        function [cfs, f, coi, scalcfs] = wt(obj, x)
        %WT Coefficients de la transformée continue.
        %   [CFS,F,COI] = WT(FB,X) rend une ligne par échelle, les
        %   fréquences centrales et le cône d'influence — la limite en
        %   deçà de laquelle les coefficients dépendent des bords.
            x = double(x(:)).';
            n = numel(x);
            if n ~= obj.SignalLength
                error('wavelet:cwtfilterbank:Longueur', ...
                      'Le signal doit avoir %d points.', obj.SignalLength);
            end
            [etendu, debut] = prolonger(obj, x);
            m = numel(etendu);
            spectre = fft(etendu);
            filtres = filtresSur(obj, m);
            cfs = zeros(size(filtres, 1), n);
            for s = 1:size(filtres, 1)
                ligne = ifft(spectre .* filtres(s, :));
                cfs(s, :) = ligne(debut:(debut + n - 1));
            end
            if nargout > 1
                f = centerFrequencies(obj);
            end
            if nargout > 2
                coi = coneInfluence(obj, n);
            end
            if nargout > 3
                % Ce qui reste sous la plus basse échelle : le signal
                % moins ce que le banc a capté.
                passeBas = 1 - sum(filtres .^ 2, 1) / 2;
                passeBas = max(min(passeBas, 1), 0);
                ligne = real(ifft(spectre .* passeBas));
                scalcfs = ligne(debut:(debut + n - 1));
            end
        end

        function psidft = freqz(obj)
        %FREQZ Réponse en fréquence de chaque filtre du banc.
            psidft = filtresSur(obj, obj.SignalLength);
        end

        function f = centerFrequencies(obj)
        %CENTERFREQUENCIES Fréquence centrale de chaque filtre.
            f = obj.Pic ./ (2 * pi * obj.Echelles(:));
            f = f * cadence(obj);
        end

        function p = centerPeriods(obj)
        %CENTERPERIODS Périodes centrales de chaque filtre.
            p = 1 ./ centerFrequencies(obj);
        end

        function s = scales(obj)
        %SCALES Échelles du banc.
            s = obj.Echelles(:);
        end

        function q = qfactor(obj)
        %QFACTOR Facteur de qualité : fréquence centrale sur largeur.
        %   Il ne dépend pas de l'échelle — c'est ce qui distingue une
        %   analyse en ondelettes d'une analyse à fenêtre fixe.
            [~, pic, ~, sigmaW] = ondeletteAnalytique(obj.Wavelet, obj.Parametres, 1);
            q = pic / (2 * sigmaW);
        end

        function [psi, t] = wavelets(obj)
        %WAVELETS Ondelettes du banc, en temps.
            filtres = filtresSur(obj, obj.SignalLength);
            psi = ifft(filtres, [], 2);
            psi = fftshift(psi, 2);
            n = obj.SignalLength;
            t = ((0:(n - 1)) - floor(n / 2)) / cadence(obj);
        end

        function [spectre, f] = timeSpectrum(obj, x, varargin)
        %TIMESPECTRUM Énergie de la transformée en fonction du temps.
            cfs = wt(obj, x);
            spectre = sum(abs(cfs) .^ 2, 1);
            f = (0:(numel(spectre) - 1)) / cadence(obj);
        end

        function [spectre, f] = scaleSpectrum(obj, x, varargin)
        %SCALESPECTRUM Énergie de la transformée en fonction de l'échelle.
            cfs = wt(obj, x);
            spectre = mean(abs(cfs) .^ 2, 2);
            f = centerFrequencies(obj);
        end

        function disp(obj)
            fprintf('  cwtfilterbank : %s, %d points, %d voix par octave\n', ...
                    obj.Wavelet, obj.SignalLength, obj.VoicesPerOctave);
            f = centerFrequencies(obj);
            fprintf('  %d filtres, de %.6g à %.6g\n', numel(f), min(f), max(f));
        end
    end
    methods (Access = private)
        function obj = construire(obj)
            [~, pic, sigmaT] = ondeletteAnalytique(obj.Wavelet, obj.Parametres, 1);
            obj.Pic = pic;
            obj.SigmaT = sigmaT;
            limites = obj.FrequencyLimits;
            if isempty(limites)
                [bas, haut] = cwtfreqbounds(obj.SignalLength, ...
                    'Wavelet', obj.Wavelet, 'WaveletParameters', obj.WaveletParameters);
            else
                limites = sort(double(limites(:)).') / cadence(obj);
                bas = limites(1);
                haut = limites(2);
            end
            % Les échelles sont en progression géométrique : une octave
            % compte VoicesPerOctave filtres, quelle que soit l'octave.
            sHaut = pic / (2 * pi * bas);
            sBas = pic / (2 * pi * haut);
            octaves = log2(sHaut / sBas);
            nombre = max(1, round(octaves * obj.VoicesPerOctave));
            obj.Echelles = sBas * 2 .^ ((0:nombre) / obj.VoicesPerOctave);
        end

        function f = cadence(obj)
            if ~isempty(obj.SamplingFrequency)
                f = double(obj.SamplingFrequency);
            elseif ~isempty(obj.SamplingPeriod)
                f = 1 / double(obj.SamplingPeriod);
            else
                f = 1;
            end
        end

        function filtres = filtresSur(obj, m)
            omega = 2 * pi * (0:(m - 1)) / m;
            omega(omega > pi) = omega(omega > pi) - 2 * pi;
            filtres = zeros(numel(obj.Echelles), m);
            for s = 1:numel(obj.Echelles)
                filtres(s, :) = ondeletteAnalytique(obj.Wavelet, obj.Parametres, ...
                                                    obj.Echelles(s) * omega);
            end
        end

        function [etendu, debut] = prolonger(obj, x)
            n = numel(x);
            if strcmpi(obj.Boundary, 'periodic')
                etendu = x;
                debut = 1;
                return
            end
            % Prolongement par réflexion : le signal miroir de chaque côté
            % évite le saut qu'un prolongement périodique créerait entre
            % la fin et le début.
            marge = floor(n / 2);
            gauche = x(min(marge, n):-1:1);
            droite = x(n:-1:max(1, n - marge + 1));
            etendu = [gauche, x, droite];
            debut = numel(gauche) + 1;
        end

        function coi = coneInfluence(obj, n)
            % À l'échelle s, l'ondelette s'étend sur environ sigmaT*s
            % échantillons ; un coefficient à la distance d du bord n'est
            % sûr que si sigmaT*s <= d.
            distance = min((1:n) - 1, n - (1:n));
            distance = max(distance, 0.5);
            coi = obj.Pic ./ (2 * pi * (distance / obj.SigmaT)) * cadence(obj);
            coi = min(coi, max(centerFrequencies(obj)));
            coi = coi(:);
        end
    end
end
