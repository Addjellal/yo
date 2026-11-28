function imwrite(x, nomFichier, format)
%IMWRITE Écrit une image au format PGM (gris) ou PPM (couleur).
%   Ces deux formats sont du texte : aucune bibliothèque externe n'est
%   nécessaire, et tous les visionneurs les lisent.
%
%   IMWRITE(X,FICHIER) prend le format de l'extension ; IMWRITE(X,FICHIER,
%   FORMAT) le donne. Seuls 'pgm', 'ppm' et 'pnm' s'écrivent : un autre
%   format — PNG, JPEG, TIFF, BMP — est refusé en le disant, plutôt que
%   d'écrire un PGM sous un nom qui annonce autre chose.
%
%   Exemple :
%      imwrite(uint8(magic(8) * 3), 'essai.pgm');
%      max(max(abs(double(imread('essai.pgm')) - magic(8) * 3)))   % 0 : rien ne se perd
%
%   Voir aussi IMREAD, IMSHOW.
    if nargin < 3 || isempty(format)
        [~, ~, extension] = fileparts(char(nomFichier));
        format = strrep(extension, '.', '');
    end
    format = lower(char(format));
    if ~isempty(format) && ~any(strcmp(format, {'pgm', 'ppm', 'pnm'}))
        error('MatLibre:imwrite:FormatNonPris', ...
              ['IMWRITE writes only the PGM and PPM text formats; the ''%s'' format ' ...
               'needs a library that MatLibre does not include. ' ...
               'Use .pgm (grayscale) or .ppm (color).'], format);
    end
    x = im2double(x);
    fid = fopen(nomFichier, 'w');
    if fid < 0
        error('images:imwrite:cannotOpen', 'Cannot open ''%s''.', nomFichier);
    end
    [h, l, c] = size(x);
    if c == 3
        fprintf(fid, 'P3\n%d %d\n255\n', l, h);
        for i = 1:h
            for j = 1:l
                fprintf(fid, '%d %d %d ', round(255*x(i,j,1)), ...
                        round(255*x(i,j,2)), round(255*x(i,j,3)));
            end
            fprintf(fid, '\n');
        end
    else
        fprintf(fid, 'P2\n%d %d\n255\n', l, h);
        for i = 1:h
            for j = 1:l
                fprintf(fid, '%d ', round(255 * x(i, j)));
            end
            fprintf(fid, '\n');
        end
    end
    fclose(fid);
end
