function r = calweeks(x)
%CALWEEKS Durée de calendrier en calweeks, ou nombre de calweeks d'une durée.
    if isa(x, 'calendarDuration')
        r = fix(x.Jours / 7);
    else
        r = calendarDuration.depuis(zeros(size(x)), double(x) * 7, zeros(size(x)));
    end
end
