function rotate3d(mode)
%ROTATE3D Rotation à la souris (acceptée, sans effet).
%   ROTATE3D ON permet, dans MATLAB, de faire tourner une figure
%   tridimensionnelle à la souris ; ROTATE3D OFF l'interdit.
%
%   Les figures de MatLibre ne sont pas manipulables à la souris et son
%   rendu est plan : l'appel est accepté pour qu'un programme tourne sans
%   retouche.
%
%   Exemple :
%      surf(peaks(30)); rotate3d('on');
%
%   Voir aussi ZOOM, PAN, VIEW, DATACURSORMODE, BRUSH.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'on', 'off'}))
        error('MATLAB:rotate3d:BadMode', 'ROTATE3D takes ''on'' or ''off''.');
    end
end
