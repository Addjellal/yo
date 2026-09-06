function r = calweeks(x)
%CALWEEKS Durée de calendrier en semaines, ou nombre de semaines d'une durée.
%   D = CALWEEKS(N) construit une durée de calendrier de N semaines.
%   N = CALWEEKS(D) rend le nombre de semaines d'une durée de calendrier.
%
%   Une durée de calendrier n'est pas une durée exacte : ajouter un mois
%   au 31 janvier donne le 28 ou le 29 février, et un jour de calendrier
%   compte 23 ou 25 heures les jours de changement d'heure. C'est
%   précisément pourquoi ces durées existent à côté de DAYS et HOURS.
%
%   Exemple :
%      calweeks(3)                          % trois semaines
%      calweeks(calweeks(3))                    % 3
%      datetime(2024,1,31) + calmonths(1) % le 29 fevrier
%
%   Voir aussi CALMONTHS, CALYEARS, CALENDARDURATION, DAYS.
    if isa(x, 'calendarDuration')
        r = fix(x.Jours / 7);
    else
        r = calendarDuration.depuis(zeros(size(x)), double(x) * 7, zeros(size(x)));
    end
end
