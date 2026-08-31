function H = ezsurf(fonction, intervalle)
%EZSURF Trace une surface (nom historique).
%   EZSURF(F) trace F sur [-2*pi 2*pi] x [-2*pi 2*pi]. F est une poignée
%   de deux variables, ou une chaîne comme 'x^2 - y^2'.
%
%   EZSURF(F,[A B]) ou EZSURF(F,[A B C D]) fixe le domaine.
%
%   H = EZSURF(...) rend la poignée.
%
%   Depuis R2016b, MATLAB recommande FSURF ; MatLibre garde les deux.
%
%   Exemples :
%      ezsurf('x^2 - y^2');
%      ezsurf(@(x, y) sin(x) .* cos(y), [-pi pi]);
%
%   Voir aussi FSURF, EZMESH, EZCONTOUR, EZPLOT, SURF.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-2 * pi, 2 * pi];
    end
    if ischar(fonction) || isstring(fonction)
        fonction = matlibre_poignee_depuis_texte(char(fonction));
    end
    H = fsurf(fonction, intervalle);
    if nargout == 0
        clear H;
    end
end
