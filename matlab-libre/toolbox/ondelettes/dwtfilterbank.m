classdef dwtfilterbank
%DWTFILTERBANK Banc de filtres d'une transformée en ondelettes discrète.
%   FB = DWTFILTERBANK() construit le banc par défaut : 'db4', mille
%   vingt-quatre points, autant de niveaux que la longueur en permet.
%   FB = DWTFILTERBANK('Nom',valeur,...) le règle.
%
%   Options :
%      'Wavelet'            'db4' par défaut, tout nom que WFILTERS connaît
%      'SignalLength'       1024, au moins deux
%      'Level'              nombre de niveaux, WMAXLEV par défaut
%      'SamplingFrequency'  en hertz
%      'SamplingPeriod'     durée entre échantillons, exclut la précédente
%      'FilterType'         'Analysis' (défaut) ou 'Synthesis'
%      'Boundary'           'reflection' (défaut) ou 'periodic'
%
%   La transformée discrète décime : à chaque niveau le signal est filtré
%   puis pris un point sur deux. On peut cependant regarder ce que
%   l'ensemble fait à un signal sans jamais décimer, en remontant les
%   filtres dans le domaine des fréquences :
%
%      PHI_0(w) = 1
%      PHI_j(w) = PHI_{j-1}(w) LO(2^{j-1} w) / sqrt(2)
%      PSI_j(w) = PHI_{j-1}(w) HI(2^{j-1} w) / sqrt(2)
%
%   Ce sont les filtres équivalents. Pour une ondelette orthogonale ils
%   forment une partition exacte de l'énergie :
%
%      somme_j |PSI_j(w)|^2 + |PHI_J(w)|^2 = 1  pour tout w
%
%   ce que FRAMEBOUNDS vérifie en rendant deux bornes égales à un.
%
%   Méthodes :
%      FREQZ             réponse en fréquence des filtres équivalents
%      WAVELETS          ondelettes en temps, une par niveau
%      SCALINGFUNCTIONS  fonctions d'échelle
%      FRAMEBOUNDS       bornes inférieure et supérieure du repère
%      CENTERFREQUENCIES fréquence centrale de chaque niveau
%      CENTERPERIODS     périodes correspondantes
%      QFACTOR           facteur de qualité de chaque niveau
%      POWERBW           largeur de bande à mi-puissance
%
%   Exemple :
%      fb = dwtfilterbank('Wavelet', 'sym4', 'SignalLength', 1024);
%      [a, b] = framebounds(fb)      % 1 et 1 : le banc est orthogonal
%      f = centerfrequencies(fb);
%
%   Voir aussi DWT, WAVEDEC, WFILTERS, CWTFILTERBANK, MODWT.
    properties (SetAccess = private)
        Wavelet = 'db4'
        SignalLength = 1024
        Level = []
        SamplingFrequency = []
        SamplingPeriod = []
        FilterType = 'Analysis'
        Boundary = 'reflection'
    end
    properties (Access = private)
        Bas = []
        Haut = []
    end
    methods
        function obj = dwtfilterbank(varargin)
            for k = 1:2:numel(varargin)
                nom = validatestring(varargin{k}, ...
                    {'Wavelet', 'SignalLength', 'Level', 'SamplingFrequency', ...
                     'SamplingPeriod', 'FilterType', 'Boundary'}, 'dwtfilterbank');
                obj.(nom) = varargin{k + 1};
            end
            if ~isempty(obj.SamplingFrequency) && ~isempty(obj.SamplingPeriod)
                error('wavelet:dwtfilterbank:Cadence', ...
                      'SamplingFrequency et SamplingPeriod s''excluent.');
            end
            obj.Wavelet = char(obj.Wavelet);
            obj.SignalLength = round(double(obj.SignalLength));
            if obj.SignalLength < 2
                error('wavelet:dwtfilterbank:Longueur', ...
                      'SignalLength doit valoir au moins deux.');
            end
            [Lo_D, Hi_D, Lo_R, Hi_R] = wfilters(obj.Wavelet);
            if strcmpi(obj.FilterType, 'Synthesis')
                obj.Bas = Lo_R;
                obj.Haut = Hi_R;
            else
                obj.Bas = Lo_D;
                obj.Haut = Hi_D;
            end
            maximum = max(1, wmaxlev(obj.SignalLength, obj.Wavelet));
            if isempty(obj.Level)
                obj.Level = maximum;
            end
            obj.Level = round(double(obj.Level));
            if obj.Level < 1
                error('wavelet:dwtfilterbank:Niveau', ...
                      'Level doit valoir au moins un.');
            end
        end

        function [psidft, f, phidft] = freqz(obj)
        %FREQZ Réponse en fréquence des filtres équivalents.
            [psidft, phidft] = filtresEquivalents(obj);
            n = obj.SignalLength;
            f = (0:(n - 1)) / n * cadence(obj);
        end

        function [psi, t] = wavelets(obj)
        %WAVELETS Ondelettes du banc, une par niveau.
            psidft = filtresEquivalents(obj);
            psi = fftshift(ifft(psidft, [], 2), 2);
            t = tempsCentre(obj);
        end

        function [phi, t] = scalingfunctions(obj)
        %SCALINGFUNCTIONS Fonctions d'échelle du banc, une par niveau.
            [~, phidft] = filtresEquivalents(obj);
            phi = fftshift(ifft(phidft, [], 2), 2);
            t = tempsCentre(obj);
        end

        function [inferieure, superieure] = framebounds(obj)
        %FRAMEBOUNDS Bornes du repère formé par le banc.
        %   Les deux valent un exactement quand l'ondelette est
        %   orthogonale ; elles s'écartent pour une biorthogonale, et
        %   l'écart mesure ce que la reconstruction amplifie au pire.
            [psidft, phidft] = filtresEquivalents(obj);
            total = sum(abs(psidft) .^ 2, 1) + abs(phidft(end, :)) .^ 2;
            inferieure = min(total);
            superieure = max(total);
        end

        function f = centerfrequencies(obj)
        %CENTERFREQUENCIES Fréquence centrale de chaque niveau.
            [psidft, ~] = filtresEquivalents(obj);
            f = barycentreFrequences(obj, psidft);
        end

        function p = centerperiods(obj)
        %CENTERPERIODS Périodes centrales de chaque niveau.
            p = 1 ./ centerfrequencies(obj);
        end

        function q = qfactor(obj)
        %QFACTOR Facteur de qualité de chaque niveau.
            [psidft, ~] = filtresEquivalents(obj);
            centre = barycentreFrequences(obj, psidft);
            q = centre ./ max(largeurBande(obj, psidft), eps);
        end

        function bw = powerbw(obj)
        %POWERBW Largeur de bande à mi-puissance de chaque niveau.
            [psidft, ~] = filtresEquivalents(obj);
            bw = largeurBande(obj, psidft);
        end

        function disp(obj)
            fprintf('  dwtfilterbank : %s, %d points, %d niveaux\n', ...
                    obj.Wavelet, obj.SignalLength, obj.Level);
            [a, b] = framebounds(obj);
            fprintf('  bornes du repère : %.12g et %.12g\n', a, b);
        end
    end
    methods (Access = private)
        function [psidft, phidft] = filtresEquivalents(obj)
            n = obj.SignalLength;
            omega = 2 * pi * (0:(n - 1)) / n;
            phi = ones(1, n);
            psidft = zeros(obj.Level, n);
            phidft = zeros(obj.Level, n);
            for niveau = 1:obj.Level
                facteur = 2 ^ (niveau - 1);
                bas = reponse(obj.Bas, facteur * omega);
                haut = reponse(obj.Haut, facteur * omega);
                psidft(niveau, :) = phi .* haut / sqrt(2);
                phi = phi .* bas / sqrt(2);
                phidft(niveau, :) = phi;
            end
        end

        function f = barycentreFrequences(obj, psidft)
            n = obj.SignalLength;
            moitie = 1:floor(n / 2) + 1;
            f = (moitie - 1) / n * cadence(obj);
            poids = abs(psidft(:, moitie)) .^ 2;
            f = (poids * f(:)) ./ max(sum(poids, 2), eps);
        end

        function bw = largeurBande(obj, psidft)
            n = obj.SignalLength;
            moitie = 1:floor(n / 2) + 1;
            f = (moitie - 1)' / n * cadence(obj);
            bw = zeros(size(psidft, 1), 1);
            for k = 1:size(psidft, 1)
                module = abs(psidft(k, moitie)) .^ 2;
                seuil = max(module) / 2;
                dedans = find(module >= seuil);
                if isempty(dedans)
                    bw(k) = 0;
                else
                    bw(k) = f(dedans(end)) - f(dedans(1));
                end
            end
        end

        function t = tempsCentre(obj)
            n = obj.SignalLength;
            t = ((0:(n - 1)) - floor(n / 2)) / cadence(obj);
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
    end
end

function H = reponse(h, omega)
%REPONSE Réponse en fréquence d'un filtre à réponse finie.
    H = zeros(size(omega));
    for n = 1:numel(h)
        H = H + h(n) * exp(-1i * (n - 1) * omega);
    end
end
