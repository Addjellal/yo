function jour = nweekdate(rang, jourSemaine, annee, mois, memeSemaine)
%NWEEKDATE Date du n-ième jour de la semaine d'un mois.
%   D = NWEEKDATE(N,J,ANNEE,MOIS) rend la date du N-ième jour J du mois.
%   J vaut 1 pour dimanche, 2 pour lundi, jusqu'à 7 pour samedi. N va de
%   un à cinq ; si le mois ne compte pas N occurrences, le résultat est
%   NaN.
%
%   NWEEKDATE(N,J,ANNEE,MOIS,K) demande de plus que le jour tombe dans la
%   même semaine que le K-ième jour de semaine du mois — c'est ainsi que
%   se définissent certaines échéances de contrats.
%
%   Exemple :
%      datestr(nweekdate(3, 2, 2024, 1))   % 15-Jan-2024, Martin Luther King
%
%   Voir aussi LWEEKDATE, THIRDWEDNESDAY, HOLIDAYS, WEEKDAY.
    if nargin < 5
        memeSemaine = 0;
    end
    [annee, mois] = matlibre_diffuser_dates(annee, mois);
    [annee, rang] = matlibre_diffuser_dates(annee, rang);
    [mois, rang] = matlibre_diffuser_dates(mois, rang);
    [annee, jourSemaine] = matlibre_diffuser_dates(annee, jourSemaine);
    [mois, jourSemaine] = matlibre_diffuser_dates(mois, jourSemaine);
    [rang, jourSemaine] = matlibre_diffuser_dates(rang, jourSemaine);
    jour = zeros(size(annee));
    for k = 1:numel(annee)
        jour(k) = une(rang(k), jourSemaine(k), annee(k), mois(k), memeSemaine);
    end
end

function d = une(rang, jourSemaine, annee, mois, memeSemaine)
    premier = datenum(annee, mois, 1);
    dernier = datenum(annee, mois, eomday(annee, mois));
    % Premier jour du mois qui tombe le jour de semaine demandé.
    ecart = mod(jourSemaine - weekday(premier), 7);
    candidat = premier + ecart + 7 * (round(rang) - 1);
    if candidat > dernier
        d = NaN;
        return
    end
    if memeSemaine > 0
        % La semaine visée est celle du jour de référence ; le résultat
        % doit y tomber, sinon il n'y a pas de date.
        reference = premier + mod(memeSemaine - weekday(premier), 7);
        debutSemaine = reference - weekday(reference) + 1;
        if candidat < debutSemaine || candidat > debutSemaine + 6
            d = NaN;
            return
        end
    end
    d = candidat;
end
