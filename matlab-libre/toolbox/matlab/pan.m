function pan(mode)
%PAN Déplacement à la souris (accepté, sans effet).
%   PAN ON permet, dans MATLAB, de faire glisser le contenu d'un axe à la
%   souris ; PAN OFF l'interdit.
%
%   Les figures de MatLibre ne sont pas manipulables à la souris :
%   l'appel est accepté pour qu'un programme tourne sans retouche. Pour
%   déplacer la vue, XLIM et YLIM font le travail.
%
%   Exemple :
%      plot(1:100); pan('on');
%
%   Voir aussi ZOOM, XLIM, YLIM, ROTATE3D, BRUSH.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'on', 'off', 'xon', 'yon'}))
        error('MATLAB:pan:BadMode', 'PAN takes ''on'' or ''off''.');
    end
end
