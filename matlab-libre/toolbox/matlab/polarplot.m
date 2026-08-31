function H = polarplot(theta, rho, varargin)
%POLARPLOT Courbe en coordonnées polaires.
%   POLARPLOT(THETA,RHO) trace la courbe dont l'angle est THETA, en
%   radians, et le rayon RHO.
%
%   POLARPLOT(THETA,RHO,STYLE) prend une chaîne de style, comme PLOT.
%
%   POLARPLOT(...,'Name',valeur) accepte les mêmes propriétés que PLOT.
%
%   H = POLARPLOT(...) rend la poignée de la courbe.
%
%   MatLibre n'a pas d'axes polaires : la courbe est convertie en
%   coordonnées cartésiennes et tracée sur un axe ordinaire, sur lequel
%   sont dessinés les cercles de rayon constant et les rayons qui
%   servent de graduations. La lecture est la même ; ce qui manque est
%   la graduation angulaire en degrés autour du cadre.
%
%   Exemples :
%      theta = linspace(0, 2*pi, 400);
%      polarplot(theta, 1 + cos(theta));       % la cardioide
%      polarplot(theta, abs(sin(3*theta)));    % la rosace a six petales
%
%   Voir aussi POLAR, COMPASS, ROSE, PLOT, POL2CART.
    theta = theta(:);
    rho = rho(:);
    aEffacer = ishold();
    if ~aEffacer
        cla;
        matlibre_grille_polaire(max(abs(rho)));
    end
    hold('on');
    H = plot(rho .* cos(theta), rho .* sin(theta), varargin{:});
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
