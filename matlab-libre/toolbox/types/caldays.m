function r = caldays(x)
%CALDAYS Durée de calendrier en jours, ou nombre de jours d'une durée.
%   D = CALDAYS(N) construit une durée de calendrier de N jours.
%   N = CALDAYS(D) rend le nombre de jours d'une durée de calendrier.
%
%   Une durée de calendrier n'est pas une durée exacte : ajouter un mois
%   au 31 janvier donne le 28 ou le 29 février, et un jour de calendrier
%   compte 23 ou 25 heures les jours de changement d'heure. C'est
%   précisément pourquoi ces durées existent à côté de DAYS et HOURS.
%
%   Exemple :
%      caldays(3)                          % trois jours
%      caldays(caldays(3))                    % 3
%      datetime(2024,1,31) + calmonths(1) % le 29 fevrier
%
%   Voir aussi CALMONTHS, CALYEARS, CALENDARDURATION, DAYS.
    if isa(x, 'calendarDuration')
        r = fix(x.Jours / 1);
    else
        r = calendarDuration.depuis(zeros(size(x)), double(x) * 1, zeros(size(x)));
    end
end
