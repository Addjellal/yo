function jour = lweekdate(jourSemaine, annee, mois, memeSemaine)
%LWEEKDATE Date du dernier jour de la semaine d'un mois.
%   D = LWEEKDATE(J,ANNEE,MOIS) rend la date du dernier jour J du mois. J
%   vaut 1 pour dimanche, jusqu'à 7 pour samedi.
%
%   LWEEKDATE(J,ANNEE,MOIS,K) demande de plus que le jour tombe dans la
%   même semaine que le K-ième jour de semaine du mois.
%
%   Exemple :
%      datestr(lweekdate(2, 2024, 5))    % 27-May-2024, jour du Souvenir
%
%   Voir aussi NWEEKDATE, THIRDWEDNESDAY, HOLIDAYS, WEEKDAY.
    if nargin < 4
        memeSemaine = 0;
    end
    [annee, mois] = matlibre_diffuser_dates(annee, mois);
    [annee, jourSemaine] = matlibre_diffuser_dates(annee, jourSemaine);
    [mois, jourSemaine] = matlibre_diffuser_dates(mois, jourSemaine);
    jour = zeros(size(annee));
    for k = 1:numel(annee)
        dernier = datenum(annee(k), mois(k), eomday(annee(k), mois(k)));
        candidat = dernier - mod(weekday(dernier) - jourSemaine(k), 7);
        if memeSemaine > 0
            premier = datenum(annee(k), mois(k), 1);
            reference = dernier - mod(weekday(dernier) - memeSemaine, 7);
            debutSemaine = reference - weekday(reference) + 1;
            if candidat < debutSemaine || candidat > debutSemaine + 6 || candidat < premier
                candidat = NaN;
            end
        end
        jour(k) = candidat;
    end
end
