function datacursormode(mode)
%DATACURSORMODE Curseur de données (accepté, sans effet).
%   DATACURSORMODE ON permet, dans MATLAB, de cliquer sur un point d'une
%   courbe pour en lire les coordonnées ; DATACURSORMODE OFF l'interdit.
%
%   Les figures de MatLibre ne sont pas manipulables à la souris :
%   l'appel est accepté pour qu'un programme tourne sans retouche. Pour
%   lire les coordonnées d'un point, GET sur la poignée de la courbe rend
%   XData et YData.
%
%   Exemple :
%      h = plot(1:10); datacursormode('on');
%      [get(h, 'XData')', get(h, 'YData')']     % la meme information
%
%   Voir aussi BRUSH, ZOOM, PAN, GET, GINPUT.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'on', 'off'}))
        error('MATLAB:datacursormode:BadMode', ...
              'DATACURSORMODE takes ''on'' or ''off''.');
    end
end
