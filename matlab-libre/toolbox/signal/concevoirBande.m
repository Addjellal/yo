function [b, a] = concevoirBande(w, genre, options)
%CONCEVOIRBANDE Filtre d'ordre minimal pour lowpass et ses voisines.
%   La bande de transition est déduite de la raideur : à raideur S, elle
%   occupe la fraction 1-S de ce qui sépare le bord de bande du bord du
%   spectre. C'est la même idée que dans MATLAB, où S vaut 0,85 par
%   défaut.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    marge = 1 - options.Steepness;
    ondulation = 0.1;
    attenuation = options.StopbandAttenuation;
    switch genre
        case 'low'
            wp = w(1);
            ws = min(wp + marge * (1 - wp), 0.999);
        case 'high'
            wp = w(1);
            ws = max(wp - marge * wp, 0.001);
        case 'bandpass'
            wp = w;
            ws = [max(w(1) - marge * w(1), 0.001), ...
                  min(w(2) + marge * (1 - w(2)), 0.999)];
        case 'stop'
            wp = [max(w(1) - marge * w(1), 0.001), ...
                  min(w(2) + marge * (1 - w(2)), 0.999)];
            ws = w;
        otherwise
            error('signal:concevoirBande:Genre', 'Genre inconnu : %s.', genre);
    end
    if strcmp(options.ImpulseResponse, 'fir')
        % Estimation de Kaiser : l'ordre suit l'atténuation demandée et
        % la largeur de la transition. Les bords doivent être donnés dans
        % l'ordre des fréquences croissantes, sans quoi les transitions
        % sont appariées de travers.
        bords = bordsCroissants(genre, wp, ws);
        souhaits = gabarit(genre);
        ecarts = repmat(10 ^ (-attenuation / 20), 1, numel(souhaits));
        ecarts(souhaits == 1) = 10 ^ (ondulation / 20) - 1;
        [n, Wn, beta, typeFir] = kaiserord(bords, souhaits, ecarts);
        % L'ordre d'un passe-bande ou d'un coupe-bande doit être pair
        % pour que le filtre soit réalisable en type I.
        if numel(Wn) == 2 && mod(n, 2) == 1
            n = n + 1;
        end
        b = fir1(n, Wn, typeFir, kaiser(n + 1, beta), 'noscale');
        a = 1;
        return;
    end
    switch genre
        case {'low', 'high'}
            [n, Wn] = ellipord(wp, ws, ondulation, attenuation);
        case 'bandpass'
            [n, Wn] = ellipord(wp, ws, ondulation, attenuation);
        case 'stop'
            [n, Wn] = ellipord(wp, ws, ondulation, attenuation);
    end
    n = max(n, 1);
    switch genre
        case 'low',      [b, a] = ellip(n, ondulation, attenuation, Wn);
        case 'high',     [b, a] = ellip(n, ondulation, attenuation, Wn, 'high');
        case 'bandpass', [b, a] = ellip(n, ondulation, attenuation, Wn);
        case 'stop',     [b, a] = ellip(n, ondulation, attenuation, Wn, 'stop');
    end
end

function bords = bordsCroissants(genre, wp, ws)
% Les bords de bande dans l'ordre des fréquences croissantes.
    switch genre
        case 'low',      bords = [wp(1), ws(1)];
        case 'high',     bords = [ws(1), wp(1)];
        case 'bandpass', bords = [ws(1), wp(1), wp(2), ws(2)];
        case 'stop',     bords = [wp(1), ws(1), ws(2), wp(2)];
    end
end

function g = gabarit(genre)
% Le gabarit qu'attend kaiserord : un par bande, dans l'ordre des
% fréquences croissantes.
    switch genre
        case 'low',      g = [1 0];
        case 'high',     g = [0 1];
        case 'bandpass', g = [0 1 0];
        case 'stop',     g = [1 0 1];
    end
end
