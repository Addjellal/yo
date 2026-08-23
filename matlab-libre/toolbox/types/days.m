function d = days(x)
%DAYS Durée en jours, ou jours d'une durée.
%   D = DAYS(X) construit une durée dont le format d'affichage est 'd'.
%   X = DAYS(D) rend le nombre de jours d'une durée.
    if isa(x, 'duration')
        d = x.Secondes / 86400;
    elseif isa(x, 'calendarDuration')
        d = days(time(x));
    else
        d = duration.avec(double(x) * 86400, 'd');
    end
end
