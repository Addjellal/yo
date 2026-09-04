function G = matlibre_contraste_local(C)
%MATLIBRE_CONTRASTE_LOCAL Force du contour en chaque pixel.
%   G = MATLIBRE_CONTRASTE_LOCAL(C) somme, sur tous les plans, le carré
%   des différences avec les voisins de gauche-droite et de haut-bas.
%   C'est ce qui sert à écarter un germe d'un contour.
%
%   Exemple :
%      G = matlibre_contraste_local(cat(3, [0 1; 0 1]));
%      size(G)   % 2 2
%
%   Voir aussi SUPERPIXELS.
    G = zeros(size(C, 1), size(C, 2));
    for p = 1:size(C, 3)
        plan = C(:, :, p);
        dx = zeros(size(plan));
        dy = zeros(size(plan));
        if size(plan, 2) > 2
            dx(:, 2:end-1) = plan(:, 3:end) - plan(:, 1:end-2);
        end
        if size(plan, 1) > 2
            dy(2:end-1, :) = plan(3:end, :) - plan(1:end-2, :);
        end
        G = G + dx .^ 2 + dy .^ 2;
    end
end
