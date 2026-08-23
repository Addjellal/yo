function d = years(x)
%YEARS Durée en années (365,2425 jours), ou années d'une durée.
%   D = YEARS(X) construit une durée dont le format d'affichage est 'y'.
%   X = YEARS(D) rend le nombre de années d'une durée.
    if isa(x, 'duration')
        d = x.Secondes / 31556952;
    elseif isa(x, 'calendarDuration')
        d = years(time(x));
    else
        d = duration.avec(double(x) * 31556952, 'y');
    end
end
