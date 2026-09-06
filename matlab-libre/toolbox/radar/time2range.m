function R = time2range(t, c)
%TIME2RANGE Distance correspondant à un temps d'aller-retour.
%   R = TIME2RANGE(T) rend c T / 2, la distance d'une cible dont l'écho
%   revient après T secondes. TIME2RANGE(T,C) impose une autre célérité —
%   celle du son dans l'eau, par exemple, pour un sonar.
%
%   Le facteur deux est le trajet aller-retour : c'est l'erreur la plus
%   commune du domaine, et elle double toutes les distances.
%
%   Une microseconde vaut environ cent cinquante mètres : c'est le repère
%   qu'on garde en tête pour lire un écran radar.
%
%   Exemple :
%      time2range(1e-6)                % environ 150 m
%      time2range(range2time(30e3))    % 30000
%
%   Voir aussi RANGE2TIME, RADAREQRNG.
    if nargin < 2
        c = 299792458;
    end
    R = c * t / 2;
end
