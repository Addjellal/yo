function material(mode)
%MATERIAL Propriétés de réflexion d'une surface (acceptées, sans effet).
%   MATERIAL SHINY, MATERIAL DULL, MATERIAL METAL et MATERIAL DEFAULT
%   règlent, dans MATLAB, la façon dont une surface renvoie la lumière.
%
%   Le rendu de MatLibre est plan et ne calcule pas d'éclairage :
%   l'appel est accepté et ne change rien à l'image.
%
%   Exemple :
%      surf(peaks(30)); material('dull');
%
%   Voir aussi LIGHT, LIGHTING, SHADING, SURFL.
    if nargin >= 1 && ~(isnumeric(mode)) && ...
       ~any(strcmpi(char(mode), {'shiny', 'dull', 'metal', 'default'}))
        error('MATLAB:material:BadMode', ...
              'The material must be ''shiny'', ''dull'', ''metal'' or ''default''.');
    end
end
