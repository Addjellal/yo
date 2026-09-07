function r = calmonths(x)
%CALMONTHS Durée de calendrier en calmonths, ou nombre de calmonths d'une durée.
%   CD = CALMONTHS(N) construit une durée de calendrier.
%   N = CALMONTHS(CD) rend le nombre entier correspondant.
%
%   Exemple :
%      d = calmonths(3);
%      datetime(2024, 1, 31) + calmonths(1)     % le 29 fevrier : les mois n'ont pas la meme longueur
    if isa(x, 'calendarDuration')
        r = fix(x.Mois / 1);
    else
        r = calendarDuration.depuis(double(x) * 1, zeros(size(x)), zeros(size(x)));
    end
end
