function y = matlibre_upsconv2(x, fColonnes, fLignes, taille, mode)
%MATLIBRE_UPSCONV2 Suréchantillonnage puis convolution d'une image.
%   Y = MATLIBRE_UPSCONV2(X,FC,FL,TAILLE,MODE) fait, selon les colonnes
%   puis selon les lignes, ce que MATLIBRE_UPSCONV1 fait d'un vecteur :
%   un zéro entre deux coefficients, la convolution par FC (verticale)
%   puis par FL (horizontale), et la partie centrale de taille TAILLE. En
%   mode 'per', le prolongement est périodique. TAILLE vide : aucune
%   coupe, la convolution entière (ce qu'UPCOEF2 emploie). Un X vide
%   donne 0. Les pages d'un tableau à trois dimensions sont traitées une
%   à une.
    if isempty(x)
        y = 0;
        return
    end
    x = double(x);
    if isempty(taille)
        taille = [NaN NaN];
    end
    pages = size(x, 3);
    for p = 1:pages
        z = selonColonnes(x(:, :, p), fColonnes(:), taille(1), mode);
        z = selonColonnes(z.', fLignes(:), taille(2), mode).';
        if p == 1
            y = zeros(size(z, 1), size(z, 2), pages);
        end
        y(:, :, p) = z;
    end
end

function y = selonColonnes(x, f, longueur, mode)
    [m, n] = size(x);
    lf = numel(f);
    if ~strcmp(mode, 'per')
        u = zeros(2 * m - 1, n);
        u(1:2:end, :) = x;
        y = conv2(u, f);
        N = size(y, 1);
        if ~isnan(longueur) && longueur < N
            d = (N - longueur) / 2;
            y = y(1 + floor(d):N - ceil(d), :);
        end
    else
        u = zeros(2 * m, n);
        u(1:2:end, :) = x;
        h = lf / 2;
        u = u(mod(-h:2 * m + h - 1, 2 * m) + 1, :);
        y = conv2(u, f);
        if isnan(longueur)
            longueur = 2 * m;
        end
        y = y(lf:lf + longueur - 1, :);
    end
end
