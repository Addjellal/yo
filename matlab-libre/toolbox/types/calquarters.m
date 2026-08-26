function r = calquarters(x)
%CALQUARTERS Durée de calendrier en calquarters, ou nombre de calquarters d'une durée.
%   CD = CALQUARTERS(N) construit une durée de calendrier.
%   N = CALQUARTERS(CD) rend le nombre entier correspondant.
    if isa(x, 'calendarDuration')
        r = fix(x.Mois / 3);
    else
        r = calendarDuration.depuis(double(x) * 3, zeros(size(x)), zeros(size(x)));
    end
end
