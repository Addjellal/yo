function d = hours(x)
%HOURS Durée en heures, ou heures d'une durée.
%   D = HOURS(X) construit une durée dont le format d'affichage est 'h'.
%   X = HOURS(D) rend le nombre de heures d'une durée.
    if isa(x, 'duration')
        d = x.Secondes / 3600;
    elseif isa(x, 'calendarDuration')
        d = hours(time(x));
    else
        d = duration.avec(double(x) * 3600, 'h');
    end
end
