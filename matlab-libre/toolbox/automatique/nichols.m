function [module, phase, w] = nichols(sys, w)
%NICHOLS Diagramme de Nichols : gain en décibels contre phase.
%   [MAG,PHASE,W] = NICHOLS(SYS) rend le module (linéaire) et la phase en
%   degrés, comme BODE. La différence est dans le tracé : sans sortie, la
%   fonction porte le gain en ordonnée et la phase en abscisse, ce qui
%   fait apparaître d'un coup les deux marges.
%
%   Exemple :
%      [m, p] = nichols(tf(1, [1 1 1]));
%
%   Voir aussi BODE, NYQUIST, MARGIN.
    if nargin < 2
        w = [];
    end
    [module, phase, w] = bode(sys, w);
    if nargout == 0
        plot(phase, 20 * log10(module));
        grid on;
        xlabel('Phase (deg)');
        ylabel('Gain (dB)');
        title('Diagramme de Nichols');
    end
end
