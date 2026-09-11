function octets = matlibre_points_utf8(points)
%MATLIBRE_POINTS_UTF8 Écriture UTF-8 d'une suite de points de code.
%   OCTETS = MATLIBRE_POINTS_UTF8(POINTS) rend la suite d'octets. C'est
%   l'inverse exact de MATLIBRE_UTF8_POINTS.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      double(matlibre_points_utf8(233))   % [195 169]
%
%   Voir aussi UNICODE2NATIVE, NATIVE2UNICODE, MATLIBRE_UTF8_POINTS.
    points = double(points(:))';
    octets = [];
    for k = 1:numel(points)
        p = points(k);
        if p < 0 || p > 1114111 || p ~= floor(p)
            error('MATLAB:unicode:PointInvalide', ...
                  '%g n''est pas un point de code Unicode.', p);
        end
        if p < 128
            octets = [octets, p];   %#ok<AGROW>
        elseif p < 2048
            octets = [octets, 192 + floor(p / 64), 128 + mod(p, 64)];   %#ok<AGROW>
        elseif p < 65536
            octets = [octets, 224 + floor(p / 4096), ...
                      128 + mod(floor(p / 64), 64), 128 + mod(p, 64)];   %#ok<AGROW>
        else
            octets = [octets, 240 + floor(p / 262144), ...
                      128 + mod(floor(p / 4096), 64), ...
                      128 + mod(floor(p / 64), 64), 128 + mod(p, 64)];   %#ok<AGROW>
        end
    end
    octets = uint8(octets);
end
