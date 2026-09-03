function b = fir1(n, Wn, varargin)
%FIR1 Filtre à réponse impulsionnelle finie, par fenêtrage.
%   B = FIR1(N,WN) conçoit un passe-bas d'ordre N dont la fréquence de
%   coupure normalisée est WN (1 correspond à la moitié de la fréquence
%   d'échantillonnage). B contient N+1 coefficients.
%   B = FIR1(N,WN,'high') conçoit un passe-haut.
%   B = FIR1(N,[W1 W2]) conçoit un passe-bande.
%   B = FIR1(N,[W1 W2],'stop') conçoit un coupe-bande.
%
%   B = FIR1(...,FENETRE) emploie la fenêtre donnée au lieu de celle de
%   Hamming, et B = FIR1(...,'noscale') laisse le gain tel que le
%   fenêtrage le donne, sans le ramener à l'unité dans la bande passante.
%
%   La fenêtre de Hamming est appliquée par défaut, comme dans la
%   documentation MathWorks.
%
%   Exemples :
%      b = fir1(20, 0.3);
%      b = fir1(20, [0.2 0.4], kaiser(21, 5), 'noscale');
%
%   Voir aussi FIR2, FIRLS, FIRPM, KAISERORD, FREQZ, FILTER.
    genre = 'low';
    fenetreChoisie = [];
    normaliser = true;
    for k = 1:numel(varargin)
        a = varargin{k};
        if ischar(a) || isstring(a)
            mot = lower(char(a));
            if strcmp(mot, 'noscale')
                normaliser = false;
            elseif strcmp(mot, 'scale')
                normaliser = true;
            else
                genre = mot;
            end
        elseif isnumeric(a)
            fenetreChoisie = a(:).';
        end
    end
    if numel(Wn) == 2
        if strcmp(genre, 'low')
            genre = 'bandpass';
        end
    end
    M = n + 1;
    if isempty(fenetreChoisie)
        w = hamming(M).';
    else
        w = fenetreChoisie;
    end
    milieu = (n) / 2;
    k = 0:n;
    d = k - milieu;
    switch genre
        case {'low', 'lowpass'}
            h = Wn * sinc(Wn * d);
        case {'high', 'highpass'}
            h = sinc(d) - Wn * sinc(Wn * d);
        case {'bandpass', 'band'}
            h = Wn(2) * sinc(Wn(2) * d) - Wn(1) * sinc(Wn(1) * d);
        case {'stop', 'bandstop'}
            h = sinc(d) - (Wn(2) * sinc(Wn(2) * d) - Wn(1) * sinc(Wn(1) * d));
        otherwise
            error('signal:fir1:InvalidType', 'Unknown filter type ''%s''.', genre);
    end
    b = h .* w;
    if ~normaliser
        return
    end
    % Gain unité dans la bande passante.
    switch genre
        case {'low', 'lowpass', 'stop', 'bandstop'}
            b = b / sum(b);
        case {'high', 'highpass'}
            s = sum(b .* cos(pi * (0:n)));
            if s ~= 0
                b = b / abs(s);
            end
        otherwise
            centre = mean(Wn);
            s = abs(sum(b .* exp(-1i * pi * centre * (0:n))));
            if s ~= 0
                b = b / s;
            end
    end
end
