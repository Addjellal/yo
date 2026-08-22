function contours = edge(x, methode, seuil)
%EDGE Détection de contours.
%   C = EDGE(X) applique Sobel avec un seuil automatique.
%   C = EDGE(X,'sobel'|'prewitt'|'log',SEUIL) choisit la méthode.
    if nargin < 2, methode = 'sobel'; end
    x = im2double(x);
    switch lower(char(methode))
        case {'sobel', 'prewitt'}
            hy = fspecial(lower(char(methode)));
            hx = hy.';
            gx = imfilter(x, hx);
            gy = imfilter(x, hy);
            carre = gx.^2 + gy.^2;
            % Seuil automatique de la fonction de référence : quatre fois
            % la moyenne du carré de l'amplitude.
            if nargin < 3 || isempty(seuil)
                contours = carre > 4 * mean(carre(:));
            else
                contours = sqrt(carre) > seuil;
            end
            return;
        case 'log'
            amplitude = abs(imfilter(x, fspecial('log', 5, 1)));
        otherwise
            error('images:edge:unknownMethod', 'Unknown method ''%s''.', methode);
    end
    if nargin < 3 || isempty(seuil)
        seuil = 0.75 * max(amplitude(:));
    end
    contours = amplitude > seuil;
end
