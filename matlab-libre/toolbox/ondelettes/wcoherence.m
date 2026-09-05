function [wcoh, wcs, f, coi] = wcoherence(x, y, varargin)
%WCOHERENCE Cohérence en ondelettes de deux signaux.
%   [WCOH,WCS,F,COI] = WCOHERENCE(X,Y) rend la cohérence de X et Y en
%   fonction du temps et de l'échelle, le spectre croisé, les fréquences
%   en cycles par échantillon et le cône d'influence.
%   [...] = WCOHERENCE(X,Y,FS) rend les fréquences en hertz.
%   [...] = WCOHERENCE(X,Y,TS) où TS est une durée rend des périodes.
%
%   Options par couples nom-valeur :
%      'VoicesPerOctave'      12 par défaut, entre 10 et 48 et pair
%      'NumScalesToSmooth'    largeur du lissage en échelle,
%                             VoicesPerOctave/2 par défaut
%      'NumOctaves'           nombre d'octaves analysées
%
%   La cohérence répond à une question que la corrélation ne sait pas
%   poser : à quel moment, et dans quelle bande, deux signaux
%   avancent-ils ensemble ? Le rapport
%
%      WCOH = |S(Wx conj(Wy) / a)|^2 / [ S(|Wx|^2/a) S(|Wy|^2/a) ]
%
%   vaut un partout si on ne lisse pas, quels que soient les signaux :
%   c'est l'inégalité de Cauchy-Schwarz, saturée par un seul terme. Le
%   lissage S, en temps puis en échelle, est donc ce qui donne son sens à
%   la mesure — il moyenne sur un voisinage, et seule une relation de
%   phase stable sur ce voisinage survit.
%
%   L'argument de WCS donne le décalage de phase entre les deux signaux
%   là où la cohérence est forte.
%
%   Exemple :
%      t = (0:1023)' / 200;
%      x = cos(2 * pi * 10 * t);
%      y = cos(2 * pi * 10 * t + pi / 4) + 0.2 * randn(size(t));
%      [wc, wcs, f] = wcoherence(x, y, 200);
%      [~, k] = min(abs(f - 10));
%      mean(wc(k, 200:800))                       % proche de un
%      mean(angle(wcs(k, 200:800))) * 180 / pi    % voisin de -45 degrés
%
%   Voir aussi CWT, CWTFILTERBANK, WSST, ONDELETTEANALYTIQUE.
    x = double(x(:)).';
    y = double(y(:)).';
    if numel(x) ~= numel(y)
        error('wavelet:wcoherence:Longueurs', ...
              'Les deux signaux doivent avoir la même longueur.');
    end
    n = numel(x);
    if n < 8
        error('wavelet:wcoherence:Longueur', ...
              'Les signaux doivent avoir au moins huit points.');
    end
    [cadence, enPeriode, nv, nsLisse, octaves] = lireArgumentsCoherence(varargin, n);
    nom = 'amor';
    parametres = [];
    [~, pic, sigmaT] = ondeletteAnalytique(nom, parametres, 1);
    sBas = pic / pi;
    if isempty(octaves)
        octaves = max(log2(n / (2 * sigmaT) / sBas), 1);
    end
    nombre = max(1, round(octaves * nv));
    echelles = sBas * 2 .^ ((0:nombre) / nv);
    omega = 2 * pi * (0:(n - 1)) / n;
    omega(omega > pi) = omega(omega > pi) - 2 * pi;
    fx = fft(x);
    fy = fft(y);
    cx = zeros(numel(echelles), n);
    cy = zeros(numel(echelles), n);
    for k = 1:numel(echelles)
        filtre = ondeletteAnalytique(nom, parametres, echelles(k) * omega);
        cx(k, :) = ifft(fx .* filtre);
        cy(k, :) = ifft(fy .* filtre);
    end
    normaliser = 1 ./ echelles(:);
    sxx = lisser(abs(cx) .^ 2 .* normaliser, echelles, sigmaT, nsLisse);
    syy = lisser(abs(cy) .^ 2 .* normaliser, echelles, sigmaT, nsLisse);
    sxy = lisser(cx .* conj(cy) .* normaliser, echelles, sigmaT, nsLisse);
    wcoh = abs(sxy) .^ 2 ./ max(sxx .* syy, realmin);
    wcoh = min(max(real(wcoh), 0), 1);
    wcs = sxy;
    f = pic ./ (2 * pi * echelles(:));
    distance = max(min((1:n) - 1, n - (1:n)), 0.5);
    coi = pic ./ (2 * pi * (distance / sigmaT));
    coi = min(coi(:), max(f));
    if enPeriode
        f = 1 ./ (f * cadence);
        coi = 1 ./ (coi * cadence);
    else
        f = f * cadence;
        coi = coi * cadence;
    end
end

function [cadence, enPeriode, nv, nsLisse, octaves] = lireArgumentsCoherence(arguments, n)
    cadence = 1;
    enPeriode = false;
    nv = 12;
    nsLisse = [];
    octaves = [];
    k = 1;
    if k <= numel(arguments) && isnumeric(arguments{k}) && isscalar(arguments{k})
        valeur = double(arguments{k});
        if valeur <= 0
            error('wavelet:wcoherence:Cadence', 'La cadence doit être positive.');
        end
        if valeur >= 1
            cadence = valeur;
        else
            cadence = 1 / valeur;
            enPeriode = true;
        end
        k = k + 1;
    end
    while k + 1 <= numel(arguments)
        switch lower(char(arguments{k}))
            case 'voicesperoctave'
                nv = round(double(arguments{k + 1}));
                if nv < 10 || nv > 48 || mod(nv, 2) ~= 0
                    error('wavelet:wcoherence:Voix', ...
                          'VoicesPerOctave doit être un entier pair de 10 à 48.');
                end
            case 'numscalestosmooth'
                nsLisse = round(double(arguments{k + 1}));
            case 'numoctaves'
                octaves = double(arguments{k + 1});
            otherwise
                error('wavelet:wcoherence:Option', 'Option inconnue : %s.', ...
                      char(arguments{k}));
        end
        k = k + 2;
    end
    if isempty(nsLisse)
        nsLisse = round(nv / 2);
    end
    nsLisse = max(1, nsLisse);
    if ~isempty(octaves) && octaves < 1
        error('wavelet:wcoherence:Octaves', 'NumOctaves doit valoir au moins un.');
    end
    if n < 8
        error('wavelet:wcoherence:Longueur', 'Signal trop court.');
    end
end

function m = lisser(m, echelles, sigmaT, nsLisse)
%LISSER Lissage en temps puis en échelle.
%   En temps, une gaussienne dont la largeur suit l'échelle : le
%   voisinage moyenné est celui de l'ondelette elle-même, ce qui garde la
%   même résolution relative à toutes les échelles.
%   En échelle, une moyenne glissante sur NSLISSE lignes.
    n = size(m, 2);
    omega = 2 * pi * (0:(n - 1)) / n;
    omega(omega > pi) = omega(omega > pi) - 2 * pi;
    spectre = fft(m, [], 2);
    for k = 1:numel(echelles)
        largeur = max(sigmaT * echelles(k), 1);
        % Gaussienne de la bonne largeur, appliquée en fréquence : sa
        % transformée est encore une gaussienne.
        noyau = exp(-(largeur ^ 2) * omega .^ 2 / 2);
        spectre(k, :) = spectre(k, :) .* noyau;
    end
    m = ifft(spectre, [], 2);
    if nsLisse > 1
        noyau = ones(nsLisse, 1) / nsLisse;
        m = filtrerColonnes(m, noyau);
    end
end

function m = filtrerColonnes(m, noyau)
    lignes = size(m, 1);
    demi = floor(numel(noyau) / 2);
    prolonge = [m(min(demi, lignes):-1:1, :); m; m(lignes:-1:max(1, lignes - demi + 1), :)];
    sortie = zeros(size(m));
    debut = size(prolonge, 1) - lignes - demi;
    for k = 1:lignes
        indices = (k + debut):(k + debut + numel(noyau) - 1);
        indices = min(max(indices, 1), size(prolonge, 1));
        sortie(k, :) = noyau' * prolonge(indices, :);
    end
    m = sortie;
end
