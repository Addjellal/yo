function zoom(varargin)
%ZOOM Loupe à la souris (acceptée, sans effet interactif).
%   ZOOM ON permet, dans MATLAB, de grossir une figure à la souris ;
%   ZOOM OFF l'interdit ; ZOOM OUT revient à la vue d'ensemble.
%
%   ZOOM(FACTEUR) grossit d'un facteur donné autour du centre de l'axe.
%   C'est la seule forme que MatLibre applique vraiment : les figures ne
%   sont pas manipulables à la souris, mais un facteur donné en clair
%   change bel et bien les bornes.
%
%   Exemples :
%      plot(1:100); zoom(2);         % on voit deux fois moins large
%      zoom('out');                  % retour a la vue d'ensemble
%
%   Voir aussi XLIM, YLIM, AXIS, PAN, ROTATE3D.
    if isempty(varargin)
        return;
    end
    argument = varargin{1};
    if ischar(argument) || isstring(argument)
        mode = lower(char(argument));
        if strcmp(mode, 'out') || strcmp(mode, 'reset')
            xlim('auto');
            ylim('auto');
        elseif ~any(strcmp(mode, {'on', 'off', 'xon', 'yon'}))
            error('MATLAB:zoom:BadMode', 'Unknown zoom option ''%s''.', mode);
        end
        return;
    end
    facteur = double(argument);
    if facteur <= 0
        error('MATLAB:zoom:BadFactor', 'The zoom factor must be positive.');
    end
    bornesX = xlim();
    bornesY = ylim();
    centreX = mean(bornesX);
    centreY = mean(bornesY);
    demiX = (bornesX(2) - bornesX(1)) / (2 * facteur);
    demiY = (bornesY(2) - bornesY(1)) / (2 * facteur);
    xlim([centreX - demiX, centreX + demiX]);
    ylim([centreY - demiY, centreY + demiY]);
end
