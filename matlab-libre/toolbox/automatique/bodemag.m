function [module, w] = bodemag(varargin)
%BODEMAG Diagramme de Bode du seul module.
%   BODEMAG(SYS) trace le gain en décibels du modèle SYS en fonction de
%   la pulsation, l'abscisse en échelle logarithmique. La phase n'est pas
%   dessinée : c'est le seul point qui sépare BODEMAG de BODE, et il tient
%   toute la case courante au lieu de la moitié.
%
%   BODEMAG(SYS,W) impose la grille de pulsations, en radians par
%   seconde : un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.
%
%   BODEMAG(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT.
%
%   [MODULE,W] = BODEMAG(SYS) ne trace rien et rend le module linéaire et
%   la grille employée.
%
%   Exemple :
%      G = tf(1, [1 0.2 1]);
%      bodemag(feedback(G, 1), 'b', G, 'r--')
%
%   Voir aussi BODE, SIGMA, NICHOLS, FREQRESP.
    [modeles, styles, w] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command BODEMAG(SYS1,SYS2,...) with output ' ...
                   'arguments is not supported.']);
        end
        [module, ~, w] = bode(modeles{1}, w);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [m, ~, wk] = bode(modeles{k}, w);
        courbes{end+1} = wk;              %#ok<AGROW>
        courbes{end+1} = 20 * log10(m);   %#ok<AGROW>
        if ~isempty(styles{k})
            courbes{end+1} = styles{k};   %#ok<AGROW>
        end
    end
    semilogx(courbes{:});
    grid on;
    xlabel('Pulsation (rad/s)');
    ylabel('Gain (dB)');
end
