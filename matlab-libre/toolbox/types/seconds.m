function d = seconds(x)
%SECONDS Durée en secondes, ou secondes d'une durée.
%   D = SECONDS(X) construit une durée dont le format d'affichage est 's'.
%   X = SECONDS(D) rend le nombre de secondes d'une durée.
    if isa(x, 'duration')
        d = x.Secondes / 1;
    elseif isa(x, 'calendarDuration')
        d = seconds(time(x));
    else
        d = duration.avec(double(x) * 1, 's');
    end
end
