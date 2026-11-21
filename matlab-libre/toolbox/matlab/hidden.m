function hidden(mode)
%HIDDEN Élimination des parties cachées d'un maillage.
%   HIDDEN ON cache les lignes d'un maillage qui passent
%   derrière la surface ; HIDDEN OFF les laisse voir ; HIDDEN sans
%   argument bascule.
%
%   HIDDEN OFF rend transparentes les faces des maillages (MESH) de l'axe
%   courant, si bien que les arêtes de derrière se voient ; HIDDEN ON leur
%   rend leur fond blanc, qui les cache.
%
%   Exemple :
%      mesh(peaks(30)); hidden('off');
%
%   Voir aussi MESH, SURF, SHADING, LIGHTING.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'on', 'off'}))
        error('MATLAB:hidden:BadMode', 'HIDDEN takes ''on'' or ''off''.');
    end
    if nargin < 1
        mode = 'on';
    end
    for h = reshape(get(gca, 'Children'), 1, [])
        if strcmp(get(h, 'Type'), 'surface') && ...
           any(strcmpi(get(h, 'FaceColor'), {'#FFFFFF', 'none'})) && ...
           any(strcmpi(get(h, 'EdgeColor'), {'flat', 'interp'}))
            if strcmpi(char(mode), 'off')
                set(h, 'FaceColor', 'none');
            else
                set(h, 'FaceColor', 'w');
            end
        end
    end
end
