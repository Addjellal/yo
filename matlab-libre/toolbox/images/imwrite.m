function imwrite(x, nomFichier, format)
%IMWRITE Écrit une image au format PGM (gris) ou PPM (couleur).
%   Ces deux formats sont du texte : aucune bibliothèque externe n'est
%   nécessaire, et tous les visionneurs les lisent.
    if nargin < 3
        format = '';
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
