function d = days(x)
%DAYS Durée en jours, ou jours d'une durée.
%   D = DAYS(X) construit une durée dont le format d'affichage est 'd'.
%   X = DAYS(D) rend le nombre de jours d'une durée.
%
%   Une durée calendaire n'a de longueur en jours que si elle ne porte
%   pas de mois : un mois vaut vingt-huit à trente et un jours selon
%   lequel, et DAYS refuse plutôt que de choisir.
%
%   Exemple :
%      days(1.5)                   % une duree d'un jour et demi
%      hours(days(1))              % 24
%      days(caldays(3))            % 3
%
%   Voir aussi HOURS, MINUTES, SECONDS, YEARS, DURATION.
    if isa(x, 'duration')
        d = x.Secondes / 86400;
    elseif isa(x, 'calendarDuration')
        % Les jours et le temps d'une durée calendaire ont une longueur
        % fixe ; les mois n'en ont pas. Rendre le seul temps — ce qui se
        % faisait — donnait zéro pour CALDAYS(3), et rendre une longueur
        % pour un mois serait pire : c'est vingt-huit à trente et un jours
        % selon le mois, et l'on ne sait pas lequel.
        if any([x.Mois] ~= 0)
            error('MATLAB:days:moisIndetermine', ...
                  ['Un mois n''a pas de longueur fixe : DAYS ne sait pas ' ...
                   'le convertir. Employez SPLIT ou une date de depart.']);
        end
        d = zeros(size(x));
        for k = 1:numel(x)
            d(k) = x(k).Jours + x(k).Temps / 86400;
        end
    else
        d = duration.avec(double(x) * 86400, 'd');
    end
end
