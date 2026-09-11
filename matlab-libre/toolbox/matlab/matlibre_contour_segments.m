function segments = matlibre_contour_segments(lignes)
%MATLIBRE_CONTOUR_SEGMENTS Découpe une matrice de contour en morceaux.
%   La matrice que rend CONTOUR range ses courbes bout à bout, chacune
%   précédée d'un en-tête portant sa hauteur et son nombre de points.
%   C'est ce format qu'il faut défaire pour tracer les courbes une à une.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      s = matlibre_contour_segments([0 0 1; 2 0 1]);
%      size(s{1}, 2)                   % 2 points
%
%   Voir aussi CONTOUR, FIMPLICIT3, CONTOURC.
    segments = {};
    k = 1;
    while k < size(lignes, 2)
        nombre = lignes(2, k);
        if nombre < 1 || k + nombre > size(lignes, 2)
            break
        end
        segments{end+1} = lignes(:, k+1:k+nombre);   %#ok<AGROW>
        k = k + nombre + 1;
    end
end
