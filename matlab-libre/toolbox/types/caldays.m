function r = caldays(x)
%CALDAYS Durée de calendrier en caldays, ou nombre de caldays d'une durée.
    if isa(x, 'calendarDuration')
        r = fix(x.Jours / 1);
    else
        r = calendarDuration.depuis(zeros(size(x)), double(x) * 1, zeros(size(x)));
    end
end
