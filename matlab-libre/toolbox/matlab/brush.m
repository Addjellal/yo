function brush(mode)
%BRUSH Sélection de points à la souris (acceptée, sans effet).
%   BRUSH ON permet, dans MATLAB, de surligner des points d'un tracé à la
%   souris et de retrouver les données correspondantes ; BRUSH OFF
%   l'interdit.
%
%   Les figures de MatLibre ne sont pas manipulables à la souris :
%   l'appel est accepté pour qu'un programme tourne sans retouche.
%
%   Exemple :
%      plot(randn(100, 1), 'o'); brush('on');
%
%   Voir aussi DATACURSORMODE, ZOOM, PAN, FINDOBJ.
    if nargin >= 1 && ~any(strcmpi(char(mode), {'on', 'off'})) && ~ischar(mode)
        error('MATLAB:brush:BadMode', 'BRUSH takes ''on'' or ''off''.');
    end
end
