function [minfreq, maxfreq] = cwtfreqbounds(N, varargin)
%CWTFREQBOUNDS Bornes de fréquence utiles d'une transformée continue.
%   [MINFREQ,MAXFREQ] = CWTFREQBOUNDS(N) rend, en cycles par échantillon,
%   les fréquences extrêmes qu'une transformée en ondelettes continue
%   peut mesurer sur un signal de N points.
%
%   [MINFREQ,MAXFREQ] = CWTFREQBOUNDS(N,FS) les rend en hertz pour une
%   fréquence d'échantillonnage FS.
%   [MINPERIOD,MAXPERIOD] = CWTFREQBOUNDS(N,TS) où TS est une durée rend
%   des périodes.
%
%   Options par couples nom-valeur :
%      'Wavelet'           'Morse' (défaut), 'amor' ou 'bump'
%      'TimeBandwidth'     produit temps-fréquence de Morse, 60 par défaut
%      'WaveletParameters' [gamma beta] de Morse
%      'CutOff'            pourcentage du sommet toléré à Nyquist,
%                          50 pour Morse, 10 sinon
%
%   Les deux bornes ne viennent pas du même empêchement.
%
%   En haut, c'est le repliement : à l'échelle la plus fine l'ondelette
%   déborde sur Nyquist. On demande que son module y soit retombé à
%   CutOff pour cent de son sommet, ce qui fixe l'échelle la plus petite
%   utilisable, donc la fréquence la plus haute.
%
%   En bas, c'est la longueur du signal : à l'échelle la plus grossière
%   l'ondelette ne tient plus dans les données. On demande que deux
%   écarts types de sa durée y tiennent, ce qui fixe l'échelle la plus
%   grande, donc la fréquence la plus basse. C'est aussi pourquoi la
%   borne basse dépend de N et la borne haute non.
%
%   Exemple :
%      [fmin, fmax] = cwtfreqbounds(1024)
%      [fmin, fmax] = cwtfreqbounds(2048, 1000)     % en hertz
%
%   Voir aussi CWTFILTERBANK, CWT, ONDELETTEANALYTIQUE.
    if ~isscalar(N) || N < 4 || N ~= fix(N)
        error('wavelet:cwtfreqbounds:Longueur', ...
              'N doit être un entier supérieur ou égal à quatre.');
    end
    pasFourni = ~isempty(varargin) && isnumeric(varargin{1}) && isscalar(varargin{1});
    if pasFourni
        cadence = double(varargin{1});
        varargin(1) = [];
    else
        cadence = [];
    end
    options = struct('Wavelet', 'Morse', 'TimeBandwidth', [], ...
                     'WaveletParameters', [], 'CutOff', []);
    for k = 1:2:numel(varargin)
        nom = validatestring(varargin{k}, fieldnames(options), 'cwtfreqbounds');
        options.(nom) = varargin{k + 1};
    end
    parametres = parametresOndelette(options);
    nom = lower(char(options.Wavelet));
    if strcmpi(nom, 'morse'), defautCoupure = 50; else, defautCoupure = 10; end
    coupure = options.CutOff;
    if isempty(coupure), coupure = defautCoupure; end
    if coupure <= 0 || coupure > 100
        error('wavelet:cwtfreqbounds:Coupure', ...
              'CutOff doit être un pourcentage dans ]0,100].');
    end
    [~, pic, sigmaT] = ondeletteAnalytique(nom, parametres, pic0());
    % Pulsation où le module retombe sous la coupure, du côté des hautes
    % fréquences.
    omegaCoupure = pulsationCoupure(nom, parametres, pic, coupure / 100);
    maxfreq = pic / (2 * omegaCoupure);
    minfreq = pic * sigmaT / (pi * N);
    if minfreq >= maxfreq
        minfreq = maxfreq / 2;
    end
    if ~isempty(cadence)
        if cadence <= 0
            error('wavelet:cwtfreqbounds:Cadence', ...
                  'La fréquence ou la période d''échantillonnage doit être positive.');
        end
        if pasFourni && cadence >= 1
            minfreq = minfreq * cadence;
            maxfreq = maxfreq * cadence;
        else
            % Une période d'échantillonnage : on rend des périodes, la
            % plus courte d'abord n'aurait pas de sens — la plus longue
            % correspond à la plus basse fréquence.
            haute = maxfreq / cadence;
            basse = minfreq / cadence;
            minfreq = 1 / haute;
            maxfreq = 1 / basse;
        end
    end
end

function w = pic0()
    w = 1;
end

function parametres = parametresOndelette(options)
%PARAMETRESONDELETTE Passage de la convention de MATLAB à celle de Morse.
%   MATLAB nomme WaveletParameters le couple [gamma produit], où le
%   produit est celui du temps par la fréquence ; l'ondelette, elle, est
%   définie par [gamma beta] avec beta = produit / gamma.
    if ~isempty(options.WaveletParameters)
        couple = double(options.WaveletParameters);
        parametres = [couple(1), couple(2) / couple(1)];
    elseif ~isempty(options.TimeBandwidth)
        parametres = [3 options.TimeBandwidth / 3];
    else
        parametres = [];
    end
end

function omega = pulsationCoupure(nom, parametres, pic, fraction)
    cible = 2 * fraction;
    bas = pic;
    haut = pic;
    for k = 1:200
        haut = haut * 1.2;
        if ondeletteAnalytique(nom, parametres, haut) <= cible
            break
        end
    end
    for k = 1:200
        milieu = (bas + haut) / 2;
        if ondeletteAnalytique(nom, parametres, milieu) > cible
            bas = milieu;
        else
            haut = milieu;
        end
    end
    omega = (bas + haut) / 2;
    omega = max(omega, pic);
end
