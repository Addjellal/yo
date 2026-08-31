function lighting(mode)
%LIGHTING Modèle d'éclairage (accepté, sans effet).
%   LIGHTING FLAT, LIGHTING GOURAUD et LIGHTING NONE choisissent, dans
%   MATLAB, comment la lumière est répartie sur une surface.
%
%   Le rendu de MatLibre est plan et ne calcule pas d'éclairage :
%   l'appel est accepté pour qu'un programme tourne sans retouche, et
%   ne change rien à l'image.
%
%   Exemple :
%      surf(peaks(30)); lighting('gouraud');
%
%   Voir aussi LIGHT, MATERIAL, SHADING, SURFL.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'flat', 'gouraud', 'phong', 'none'}))
        error('MATLAB:lighting:BadMode', ...
              'The lighting must be ''flat'', ''gouraud'' or ''none''.');
    end
end
