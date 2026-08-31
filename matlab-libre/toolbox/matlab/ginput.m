function [x, y, bouton] = ginput(n)
%GINPUT Lecture de points à la souris (indisponible).
%   [X,Y] = GINPUT(N) attend, dans MATLAB, que l'on clique N fois sur la
%   figure et rend les coordonnées des points cliqués.
%
%   Les figures de MatLibre ne sont pas interactives : GINPUT ne peut pas
%   faire ce qu'on lui demande, et le dit plutôt que de rendre des
%   coordonnées inventées. Un programme qui en a besoin doit prendre ses
%   points autrement — INPUT au clavier, ou des coordonnées écrites en
%   clair.
%
%   Voir aussi INPUT, DATACURSORMODE, GTEXT, WAITFORBUTTONPRESS.
    if nargin < 1
        n = Inf;
    end
    error('MATLAB:ginput:NoInteractiveFigure', ...
          ['GINPUT needs an interactive figure; MatLibre figures are not ' ...
           'clickable. Give the coordinates directly instead.']);
end
