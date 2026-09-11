function V = matlibre_poly_assembler(contours)
%MATLIBRE_POLY_ASSEMBLER Réunit des contours en une liste séparée par des NaN.
%   Un contour est orienté dans le sens direct s'il est à profondeur
%   paire — dehors, ou dans un trou —, et dans l'autre s'il est à
%   profondeur impaire — c'est alors un trou. C'est ainsi qu'un trou se
%   distingue d'un plein, et la seule information que porte
%   l'orientation.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      V = matlibre_poly_assembler({[0 0; 2 0; 2 2; 0 2]});
%      size(V, 1)                      % 4 sommets, aucun NaN
%
%   Voir aussi POLYSHAPE, MATLIBRE_POLY_SEPARER.
    V = zeros(0, 2);
    if isempty(contours)
        return
    end
    % Un contour contenu dans un autre est un trou : on l'oriente en sens
    % inverse. La profondeur d'imbrication decide — un trou dans un trou
    % est a nouveau plein.
    orientes = cell(size(contours));
    for k = 1:numel(contours)
        c = contours{k};
        profondeur = 0;
        for j = 1:numel(contours)
            if j == k
                continue
            end
            if matlibre_poly_contenu(c, contours{j})
                profondeur = profondeur + 1;
            end
        end
        direct = matlibre_poly_aire_signee(c) >= 0;
        veutDirect = mod(profondeur, 2) == 0;
        if direct ~= veutDirect
            c = c(end:-1:1, :);
        end
        orientes{k} = c;
    end
    for k = 1:numel(orientes)
        if k > 1
            V(end + 1, :) = [NaN NaN];   %#ok<AGROW>
        end
        V = [V; orientes{k}];   %#ok<AGROW>
    end
end
