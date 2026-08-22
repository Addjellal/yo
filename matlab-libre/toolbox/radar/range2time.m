function t = range2time(R, c)
%RANGE2TIME Temps d'aller-retour pour une distance donnée.
    if nargin < 2
        c = 299792458;
    end
    t = 2 * R / c;
end
