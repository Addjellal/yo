function d = time(cd)
%TIME Partie horaire d'une durée de calendrier, sous forme de duration.
    if isa(cd, 'calendarDuration')
        d = duration.avec(cd.Temps, 'hh:mm:ss');
    else
        d = duration(cd);
    end
end
