function d = minutes(x)
%MINUTES Durée en minutes, ou minutes d'une durée.
%   D = MINUTES(X) construit une durée dont le format d'affichage est 'm'.
%   X = MINUTES(D) rend le nombre de minutes d'une durée.
    if isa(x, 'duration')
        d = x.Secondes / 60;
    elseif isa(x, 'calendarDuration')
        d = minutes(time(x));
    else
        d = duration.avec(double(x) * 60, 'm');
    end
end
