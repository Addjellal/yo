function hidden(mode)
%HIDDEN Élimination des parties cachées (acceptée, sans effet).
%   HIDDEN ON cache, dans MATLAB, les lignes d'un maillage qui passent
%   derrière la surface ; HIDDEN OFF les laisse voir ; HIDDEN sans
%   argument bascule.
%
%   Le rendu de MatLibre est plan : il n'y a pas de parties cachées, et
%   l'appel ne change rien à l'image.
%
%   Exemple :
%      mesh(peaks(30)); hidden('off');
%
%   Voir aussi MESH, SURF, SHADING, LIGHTING.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'on', 'off'}))
        error('MATLAB:hidden:BadMode', 'HIDDEN takes ''on'' or ''off''.');
    end
end
