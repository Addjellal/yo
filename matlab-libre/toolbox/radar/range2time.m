function t = range2time(R, c)
%RANGE2TIME Temps d'aller-retour pour une distance donnée.
%   T = RANGE2TIME(R) rend 2 R / c ; RANGE2TIME(R,C) impose une autre
%   célérité.
%
%   C'est ce temps qui fixe la cadence de répétition d'un radar : deux
%   impulsions ne doivent pas se chevaucher, sans quoi on ne sait plus
%   laquelle a produit l'écho. La portée non ambiguë est donc la distance
%   correspondant à la période de répétition.
%
%   Exemple :
%      range2time(30e3)                % 200 microsecondes
%      1 / range2time(150e3)           % cadence maximale non ambigue
%
%   Voir aussi TIME2RANGE, RADAREQRNG.
    if nargin < 2
        c = 299792458;
    end
    t = 2 * R / c;
end
