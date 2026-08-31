function H = ezplot(fonction, intervalle)
%EZPLOT Trace une fonction ou une courbe implicite (nom historique).
%   EZPLOT(F) trace F sur [-2*pi 2*pi]. F est une poignée d'une variable,
%   ou une chaîne comme 'sin(x)/x'.
%
%   EZPLOT(F,[A B]) fixe l'intervalle.
%
%   EZPLOT(F) où F est une poignée de deux variables trace la courbe
%   implicite F(x,y) = 0 : c'est ainsi qu'on dessine un cercle,
%   'x^2 + y^2 - 1'.
%
%   EZPLOT(FX,FY) trace la courbe paramétrée.
%
%   H = EZPLOT(...) rend la poignée.
%
%   EZPLOT est l'ancien nom ; depuis R2016b, MATLAB recommande FPLOT pour
%   une fonction d'une variable et FIMPLICIT pour une courbe implicite.
%   MatLibre garde les trois.
%
%   Exemples :
%      ezplot('sin(x)/x');
%      ezplot(@(x) x.^2 - 2, [-3 3]);
%      ezplot(@(x, y) x.^2 + y.^2 - 1);       % le cercle unite
%
%   Voir aussi FPLOT, FIMPLICIT, FCONTOUR, EZSURF, EZCONTOUR.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-2 * pi, 2 * pi];
    end
    if ischar(fonction) || isstring(fonction)
        fonction = matlibre_poignee_depuis_texte(char(fonction));
    end
    if nargin(fonction) == 2
        H = fimplicit(fonction, intervalle);
    else
        H = fplot(fonction, intervalle);
    end
    if nargout == 0
        clear H;
    end
end
