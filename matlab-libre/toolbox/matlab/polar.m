function H = polar(theta, rho, varargin)
%POLAR Courbe en coordonnées polaires (nom historique).
%   POLAR(THETA,RHO) fait ce que fait POLARPLOT. C'est le nom que la
%   fonction portait avant R2016a ; MATLAB le garde pour les programmes
%   anciens, et MatLibre aussi.
%
%   POLAR(THETA,RHO,STYLE) prend une chaîne de style.
%
%   Exemples :
%      theta = linspace(0, 2*pi, 200);
%      polar(theta, sin(2 * theta));
%
%   Voir aussi POLARPLOT, COMPASS, ROSE, PLOT.
    H = polarplot(theta, rho, varargin{:});
    if nargout == 0
        clear H;
    end
end
