function R = time2range(t, c)
%TIME2RANGE Distance correspondant à un temps d'aller-retour.
    if nargin < 2
        c = 299792458;
    end
    R = c * t / 2;
end
