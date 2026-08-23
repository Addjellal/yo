function r = calmonths(x)
%CALMONTHS Durée de calendrier en calmonths, ou nombre de calmonths d'une durée.
%   CD = CALMONTHS(N) construit une durée de calendrier.
%   N = CALMONTHS(CD) rend le nombre entier correspondant.
    if isa(x, 'calendarDuration')
        r = fix(x.Mois / 1);
    else
        r = calendarDuration.depuis(double(x) * 1, zeros(size(x)), zeros(size(x)));
    end
end
