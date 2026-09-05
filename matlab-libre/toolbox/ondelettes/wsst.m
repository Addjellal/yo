function [sst, f] = wsst(x, varargin)
%WSST Transformée en ondelettes synchronisée.
%   [SST,F] = WSST(X) rend la transformée synchronisée de X et les
%   fréquences, en cycles par échantillon.
%   [SST,F] = WSST(X,FS) les rend en hertz.
%   [SST,F] = WSST(X,TS) où TS est une durée les rend par période.
%   [SST,...] = WSST(...,ONDELETTE) où ONDELETTE vaut 'amor' (défaut) ou
%   'bump'.
%   [SST,...] = WSST(...,'VoicesPerOctave',NV) règle le nombre de voix
%   par octave, 32 par défaut, entre 10 et 48 et pair.
%
%   Une transformée en ondelettes étale l'énergie d'une sinusoïde sur
%   toutes les échelles voisines : la lecture en est floue. Or la phase,
%   elle, ne ment pas — la fréquence instantanée
%
%      w(a,b) = -i / (2 pi) * dW/db (a,b) / W(a,b)
%
%   est la même pour toutes les échelles où le coefficient est
%   appréciable. La synchronisation consiste à reporter chaque
%   coefficient non pas à son échelle mais à cette fréquence-là, ce qui
%   rassemble en une ligne nette ce que la transformée avait étalé.
%
%   L'opération conserve l'énergie du signal, puisqu'elle ne fait que
%   déplacer des coefficients : elle reste inversible.
%
%   Exemple :
%      t = (0:2047)' / 1000;
%      x = cos(2 * pi * 50 * t) + cos(2 * pi * 180 * t);
%      [s, f] = wsst(x, 1000);
%      [~, k] = sort(mean(abs(s), 2), 'descend');
%      sort(f(k(1:2)))            % voisin de 50 et 180
%
%   Voir aussi CWT, CWTFILTERBANK, WCOHERENCE, ONDELETTEANALYTIQUE.
    [x, cadence, enPeriode, nom, parametres, nv] = lireArgumentsWsst(x, varargin);
    n = numel(x);
    [~, pic, sigmaT] = ondeletteAnalytique(nom, parametres, 1);
    % Grille d'échelles géométrique, comme le banc continu.
    sBas = pic / pi;
    sHaut = n / (2 * sigmaT);
    octaves = max(log2(sHaut / sBas), 1 / nv);
    nombre = max(1, round(octaves * nv));
    echelles = sBas * 2 .^ ((0:nombre) / nv);
    omega = 2 * pi * (0:(n - 1)) / n;
    omega(omega > pi) = omega(omega > pi) - 2 * pi;
    spectre = fft(x(:).');
    coefficients = zeros(numel(echelles), n);
    derivees = zeros(numel(echelles), n);
    for k = 1:numel(echelles)
        filtre = ondeletteAnalytique(nom, parametres, echelles(k) * omega);
        coefficients(k, :) = ifft(spectre .* filtre);
        % La dérivée par rapport au temps se lit en fréquence : dériver,
        % c'est multiplier par i w.
        derivees(k, :) = ifft(spectre .* filtre .* (1i * omega));
    end
    seuil = 1e-8 * max(abs(coefficients(:)));
    valide = abs(coefficients) > seuil;
    instantanee = zeros(size(coefficients));
    instantanee(valide) = real(-1i * derivees(valide) ./ coefficients(valide)) / (2 * pi);
    % Les fréquences de sortie sont celles des échelles : la
    % réaffectation ne change pas la grille, seulement la ligne où chaque
    % coefficient atterrit.
    f = pic ./ (2 * pi * echelles(:));
    f = flipud(f);
    sst = zeros(numel(f), n);
    % Poids de la formule de reconstruction : da/a^{3/2} devient, sur une
    % grille géométrique, un facteur constant fois a^{-1/2}.
    pas = log(2) / nv;
    lignes = numel(f);
    for k = 1:numel(echelles)
        poids = pas * echelles(k) ^ (-1 / 2);
        w = instantanee(k, :);
        garde = valide(k, :) & isfinite(w) & w > 0;
        if ~any(garde)
            continue
        end
        colonnes = find(garde);
        cible = discretiser(w(colonnes), f(1), nv, lignes);
        indices = cible(:) + (colonnes(:) - 1) * lignes;
        apports = coefficients(k, colonnes) * poids;
        sst(:) = sst(:) + accumarray(indices, apports(:), [lignes * n, 1]);
    end
    if enPeriode
        f = 1 ./ (f * cadence);
    else
        f = f * cadence;
    end
end

function cible = discretiser(w, premiere, nv, lignes)
%DISCRETISER Ligne d'arrivée de chaque fréquence instantanée.
%   La grille est géométrique de raison 2^(1/nv) : la ligne se lit
%   directement, sans chercher parmi les bornes.
    cible = round(nv * log2(w / premiere)) + 1;
    cible = min(max(cible, 1), lignes);
end

function [x, cadence, enPeriode, nom, parametres, nv] = lireArgumentsWsst(x, arguments)
    x = double(x(:));
    if numel(x) < 4
        error('wavelet:wsst:Longueur', 'Le signal doit avoir au moins quatre points.');
    end
    cadence = 1;
    enPeriode = false;
    nom = 'amor';
    parametres = [];
    nv = 32;
    k = 1;
    if k <= numel(arguments) && isnumeric(arguments{k}) && isscalar(arguments{k})
        valeur = double(arguments{k});
        if valeur <= 0
            error('wavelet:wsst:Cadence', 'La cadence doit être positive.');
        end
        if valeur >= 1
            cadence = valeur;
        else
            cadence = 1 / valeur;
            enPeriode = true;
        end
        k = k + 1;
    end
    if k <= numel(arguments) && (ischar(arguments{k}) || isstring(arguments{k})) ...
            && any(strcmpi(char(arguments{k}), {'amor', 'bump', 'morse'}))
        nom = lower(char(arguments{k}));
        k = k + 1;
    end
    while k + 1 <= numel(arguments)
        switch lower(char(arguments{k}))
            case 'voicesperoctave'
                nv = round(double(arguments{k + 1}));
                if nv < 10 || nv > 48 || mod(nv, 2) ~= 0
                    error('wavelet:wsst:Voix', ...
                          'VoicesPerOctave doit être un entier pair de 10 à 48.');
                end
            case 'waveletparameters'
                couple = double(arguments{k + 1});
                parametres = [couple(1), couple(2) / couple(1)];
            otherwise
                error('wavelet:wsst:Option', 'Option inconnue : %s.', ...
                      char(arguments{k}));
        end
        k = k + 2;
    end
end
