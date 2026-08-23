function r = calyears(x)
%CALYEARS Durée de calendrier en calyears, ou nombre de calyears d'une durée.
%   CD = CALYEARS(N) construit une durée de calendrier.
%   N = CALYEARS(CD) rend le nombre entier correspondant.
    if isa(x, 'calendarDuration')
        r = fix(x.Mois / 12);
    else
        r = calendarDuration.depuis(double(x) * 12, zeros(size(x)), zeros(size(x)));
    end
end
