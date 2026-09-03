function [contours, seuilUtilise] = edge(x, methode, seuil, sigma)
%EDGE Détection de contours.
%   C = EDGE(X) applique Sobel avec un seuil automatique.
%   C = EDGE(X,'sobel'|'prewitt'|'roberts'|'log'|'canny',SEUIL) choisit
%   la méthode.
%
%   La méthode de Canny est celle qui donne des contours d'un pixel
%   d'épaisseur : elle lisse l'image, cherche le maximum du gradient dans
%   la direction où il pointe — les autres points sont écartés —, puis
%   suit les contours par un double seuil, ce qui garde les traits
%   faibles rattachés à un trait fort.
%
%   C = EDGE(X,'canny',[BAS HAUT]) donne les deux seuils, entre 0 et 1.
%   C = EDGE(X,'canny',SEUIL,SIGMA) règle le lissage (racine de 2 par
%   défaut).
%
%   [C,SEUIL] = EDGE(...) rend aussi le seuil employé.
%
%   Exemple :
%      I = mat2gray(peaks(100));
%      C = edge(I, 'canny');
%
%   Voir aussi IMGRADIENT, FSPECIAL, IMFILTER, HOUGH, BWMORPH.
    if nargin < 2, methode = 'sobel'; end
    if nargin < 3, seuil = []; end
    if nargin < 4 || isempty(sigma), sigma = sqrt(2); end
    x = im2double(x);
    if size(x, 3) > 1
        x = im2gray(x);
    end
    seuilUtilise = seuil;
    switch lower(char(methode))
        case {'sobel', 'prewitt'}
            hy = fspecial(lower(char(methode)));
            hx = hy.';
            gx = imfilter(x, hx);
            gy = imfilter(x, hy);
            carre = gx.^2 + gy.^2;
            % Seuil automatique de la fonction de référence : quatre fois
            % la moyenne du carré de l'amplitude.
            if isempty(seuil)
                seuilUtilise = sqrt(4 * mean(carre(:)));
                contours = carre > 4 * mean(carre(:));
            else
                contours = sqrt(carre) > seuil;
            end
            return;
        case 'roberts'
            gx = imfilter(x, [1 0; 0 -1]);
            gy = imfilter(x, [0 1; -1 0]);
            carre = gx .^ 2 + gy .^ 2;
            if isempty(seuil)
                seuilUtilise = sqrt(4 * mean(carre(:)));
                contours = carre > 4 * mean(carre(:));
            else
                contours = sqrt(carre) > seuil;
            end
            return;
        case 'canny'
            [contours, seuilUtilise] = canny(x, seuil, sigma);
            return;
        case {'log', 'zerocross'}
            amplitude = abs(imfilter(x, fspecial('log', 5, 1)));
        otherwise
            error('images:edge:unknownMethod', 'Unknown method ''%s''.', methode);
    end
    if isempty(seuil)
        seuil = 0.75 * max(amplitude(:));
        seuilUtilise = seuil;
    end
    contours = amplitude > seuil;
end

function [contours, seuils] = canny(x, seuil, sigma)
% Lissage, gradient, suppression des non-maxima, double seuil.
    taille = 2 * ceil(3 * sigma) + 1;
    lisse = imfilter(x, fspecial('gaussian', taille, sigma), 'replicate');
    hy = fspecial('sobel');
    gx = imfilter(lisse, hy.', 'replicate');
    gy = imfilter(lisse, hy, 'replicate');
    amplitude = hypot(gx, gy);
    if max(amplitude(:)) > 0
        amplitude = amplitude / max(amplitude(:));
    end
    direction = atan2(gy, gx);
    [m, n] = size(amplitude);
    maxima = false(m, n);
    for i = 2:(m - 1)
        for j = 2:(n - 1)
            % La direction est ramenée à l'une des quatre du voisinage :
            % on compare l'amplitude à ses deux voisins de ce côté.
            angle = mod(direction(i, j) * 180 / pi + 180, 180);
            if angle < 22.5 || angle >= 157.5
                voisins = [amplitude(i, j - 1), amplitude(i, j + 1)];
            elseif angle < 67.5
                voisins = [amplitude(i + 1, j - 1), amplitude(i - 1, j + 1)];
            elseif angle < 112.5
                voisins = [amplitude(i - 1, j), amplitude(i + 1, j)];
            else
                voisins = [amplitude(i - 1, j - 1), amplitude(i + 1, j + 1)];
            end
            maxima(i, j) = amplitude(i, j) >= voisins(1) && amplitude(i, j) >= voisins(2);
        end
    end
    if isempty(seuil)
        % Seuil haut automatique : celui qui laisse sept dixièmes des
        % pixels du côté « pas un contour », lu sur l'histogramme du
        % gradient — c'est la règle de la fonction de référence. Prendre
        % un quantile des amplitudes non nulles ne marche pas : le
        % lissage laisse partout une poussière numérique, et le seuil
        % tombait à zéro.
        [compte, bords] = histcounts(amplitude(:), 64);
        cumul = cumsum(compte) / max(numel(amplitude), 1);
        indice = find(cumul > 0.7, 1);
        if isempty(indice)
            haut = 0.1;
        else
            haut = bords(indice + 1);
        end
        bas = 0.4 * haut;
    elseif isscalar(seuil)
        haut = seuil;
        bas = 0.4 * haut;
    else
        bas = seuil(1);
        haut = seuil(2);
    end
    seuils = [bas, haut];
    forts = maxima & (amplitude >= haut);
    faibles = maxima & (amplitude >= bas);
    % Hystérésis : un contour faible n'est gardé que s'il touche un
    % contour fort, de proche en proche.
    contours = imreconstruct(forts, faibles);
end
