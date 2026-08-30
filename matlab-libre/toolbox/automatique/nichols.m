function [module, phase, w] = nichols(varargin)
%NICHOLS Diagramme de Nichols : gain en décibels contre phase.
%   NICHOLS(SYS) porte le gain en ordonnée et la phase en abscisse : les
%   deux marges se lisent d'un coup sur la même courbe, autour du point
%   critique (-180 degrés, 0 dB).
%
%   NICHOLS(SYS,W) impose la grille de pulsations, en radians par seconde.
%
%   NICHOLS(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT.
%
%   [MAG,PHASE,W] = NICHOLS(SYS) ne trace rien et rend le module —
%   linéaire, pas en décibels —, la phase en degrés et la grille, comme
%   BODE.
%
%   Exemple :
%      nichols(tf(1, [1 1 1]))
%
%   Voir aussi BODE, NYQUIST, MARGIN.
    [modeles, styles, w] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command NICHOLS(SYS1,SYS2,...) with output ' ...
                   'arguments is not supported.']);
        end
        [module, phase, w] = bode(modeles{1}, w);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [m, p] = bode(modeles{k}, w);
        courbes{end+1} = p;                     %#ok<AGROW>
        courbes{end+1} = 20 * log10(m);         %#ok<AGROW>
        if ~isempty(styles{k})
            courbes{end+1} = styles{k};         %#ok<AGROW>
        end
    end
    plot(courbes{:});
    grid on;
    xlabel('Phase (deg)');
    ylabel('Gain (dB)');
    title('Diagramme de Nichols');
end
