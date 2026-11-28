function [img, H] = iradon(p, theta, varargin)
%IRADON Transformée de Radon inverse, par rétroprojection filtrée.
%   I = IRADON(R,THETA) reconstruit une image à partir des projections R
%   (une colonne par angle, comme celles de RADON) prises aux angles THETA,
%   en degrés ; THETA peut aussi être l'écart entre deux angles, pris alors
%   à partir de zéro.
%   I = IRADON(R,THETA,INTERP,FILTRE,ECHELLE,TAILLE) précise, comme
%   MATLAB :
%      INTERP   'linear' (défaut) ou 'nearest' : l'interpolation de la
%               rétroprojection
%      FILTRE   'Ram-Lak' (défaut), 'Shepp-Logan', 'Cosine', 'Hamming',
%               'Hann' ou 'None'
%      ECHELLE  la part de la bande gardée, entre 0 et 1 (1 par défaut)
%      TAILLE   le côté de l'image (2*floor(size(R,1)/(2*sqrt(2))) par défaut)
%   [I,H] = IRADON(...) rend aussi la réponse en fréquence du filtre.
%
%   Chaque projection est filtrée par la rampe |f|, construite dans le
%   domaine spatial (Kak et Slaney, Principles of Computerized Tomographic
%   Imaging, chapitre 3 : h(0) = 1/4, h(n) = -1/(n pi)^2 pour n impair,
%   zéro pour n pair) et appliquée sur des projections complétées de zéros
%   jusqu'à une puissance de deux au moins double, ce qui évite le
%   repliement circulaire et le décalage du continu. Les projections
%   filtrées sont ensuite rétroprojetées et sommées, au facteur pi/(2 N)
%   près pour N angles.
%
%   Exemple :
%      P = phantom(64);
%      I = iradon(radon(P, 0:179), 0:179, 'linear', 'Ram-Lak', 1, 64);
%      sqrt(mean((I(:) - P(:)) .^ 2))  % petit
%
%   Voir aussi RADON, PHANTOM.
    interp = 'linear';
    filtre = 'ram-lak';
    echelle = 1;
    taille = [];
    nombres = {};
    for k = 1:numel(varargin)
        a = varargin{k};
        if ischar(a) || isstring(a)
            mot = lower(char(a));
            if any(strcmp(mot, {'linear', 'nearest'}))
                interp = mot;
            elseif any(strcmp(mot, {'spline', 'pchip', 'cubic', 'v5cubic'}))
                error('images:iradon:Interpolation', ...
                      'MatLibre interpolates the backprojection with ''linear'' or ''nearest''.');
            elseif any(strcmp(mot, {'ram-lak', 'shepp-logan', 'cosine', 'hamming', 'hann', 'none'}))
                filtre = mot;
            else
                error('images:iradon:invalidFilter', 'Argument inconnu : %s.', mot);
            end
        else
            nombres{end + 1} = a;                                   %#ok<AGROW>
        end
    end
    if numel(nombres) >= 1 && ~isempty(nombres{1}), echelle = nombres{1}; end
    if numel(nombres) >= 2, taille = nombres{2}; end
    if ~(echelle > 0 && echelle <= 1)
        error('images:iradon:invalidFrequencyScaling', 'Frequency scaling must be in (0, 1].');
    end
    p = double(p);
    long = size(p, 1);
    if isscalar(theta) && size(p, 2) > 1
        theta = (0:size(p, 2) - 1) * theta;
    end
    if numel(theta) ~= size(p, 2)
        error('images:iradon:thetaNotMatchingProjectionNumber', ...
              'One angle per projection (%d) is required.', size(p, 2));
    end
    theta = theta(:).' * pi / 180;
    if isempty(taille)
        taille = 2 * floor(long / (2 * sqrt(2)));
    end
    [p, H] = filtrer(p, filtre, echelle);
    img = zeros(taille);
    % L'origine est le pixel central que RADON choisirait, floor((N+1)/2),
    % sur les deux axes : x vers la droite, y vers le haut.
    origine = floor((taille + 1) / 2);
    x = repmat((1:taille) - origine, taille, 1);
    y = repmat(origine - (1:taille).', 1, taille);
    centre = ceil(long / 2);
    diagonale = 2 * ceil(taille / sqrt(2)) + 1;
    if size(p, 1) < diagonale
        manque = diagonale - size(p, 1);
        p = [zeros(ceil(manque / 2), size(p, 2)); p; zeros(floor(manque / 2), size(p, 2))];
        centre = centre + ceil(manque / 2);
    end
    for k = 1:numel(theta)
        projection = [p(:, k); 0];
        t = x * cos(theta(k)) + y * sin(theta(k));
        if strcmp(interp, 'nearest')
            indices = round(t) + centre;
            dehors = indices < 1 | indices > size(p, 1);
            indices(dehors) = numel(projection);
            img = img + projection(indices);
        else
            a = floor(t);
            i0 = a + centre;
            i1 = i0 + 1;
            dehors = i0 < 1 | i1 > size(p, 1);
            i0(dehors) = numel(projection);
            i1(dehors) = numel(projection);
            img = img + (t - a) .* projection(i1) + (a + 1 - t) .* projection(i0);
        end
    end
    img = img * pi / (2 * numel(theta));
end

function [p, H] = filtrer(p, filtre, d)
%FILTRER Filtre rampe et ses variantes, dans le domaine de Fourier, après complément de zéros.
    long = size(p, 1);
    ordre = max(64, 2 ^ nextpow2(2 * long));
    if strcmp(filtre, 'none')
        H = ones(ordre, 1);
        return
    end
    n = 0:(ordre / 2);
    reponse = zeros(1, ordre / 2 + 1);
    reponse(1) = 1 / 4;
    reponse(2:2:end) = -1 ./ ((pi * n(2:2:end)) .^ 2);
    reponse = [reponse, reponse(end - 1:-1:2)];
    filt = 2 * real(fft(reponse));
    filt = filt(1:ordre / 2 + 1);
    w = 2 * pi * (0:numel(filt) - 1) / ordre;
    switch filtre
        case 'shepp-logan'
            filt(2:end) = filt(2:end) .* (sin(w(2:end) / (2 * d)) ./ (w(2:end) / (2 * d)));
        case 'cosine'
            filt(2:end) = filt(2:end) .* cos(w(2:end) / (2 * d));
        case 'hamming'
            filt(2:end) = filt(2:end) .* (0.54 + 0.46 * cos(w(2:end) / d));
        case 'hann'
            filt(2:end) = filt(2:end) .* (1 + cos(w(2:end) ./ d)) / 2;
    end
    filt(w > pi * d) = 0;
    H = [filt, filt(end - 1:-1:2)].';
    p(ordre, 1) = 0;
    p = real(ifft(fft(p) .* H));
    p = p(1:long, :);
end
