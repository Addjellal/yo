function jour = datemnth(depart, nombreMois, drapeau, base, regleFinMois)
%DATEMNTH Date située un nombre de mois plus loin.
%   D = DATEMNTH(DEPART,N) rend la date qui tombe N mois après DEPART. Si
%   le mois d'arrivée est trop court — le 31 mars plus un mois —, la date
%   est ramenée au dernier jour du mois.
%
%   DATEMNTH(...,DRAPEAU) choisit le jour du mois d'arrivée : 0 garde
%   celui du départ (défaut), 1 prend le premier du mois, 2 le dernier,
%   3 le dernier si le départ était lui-même un dernier jour de mois.
%   DATEMNTH(...,BASE,REGLE) : la règle de fin de mois vaut un par
%   défaut, ce qui ramène au dernier jour ; zéro l'annule.
%
%   Exemple :
%      datestr(datemnth('31-Jan-2024', 1))    % 29-Feb-2024
%      datestr(datemnth('15-Jan-2024', 3))    % 15-Apr-2024
%
%   Voir aussi DATEWRKDY, EOMDAY, ADDTODATE, CFDATES.
    if nargin < 3 || isempty(drapeau),      drapeau = 0;      end
    if nargin < 4 || isempty(base),         base = 0;         end   %#ok<NASGU>
    if nargin < 5 || isempty(regleFinMois), regleFinMois = 1; end
    [debut, nombreMois] = matlibre_diffuser_dates(matlibre_dates(depart), nombreMois);
    [annee, mois, jourDepart] = matlibre_jours_composants(debut);
    jour = zeros(size(debut));
    for k = 1:numel(debut)
        total = mois(k) + round(nombreMois(k));
        anneeArrivee = annee(k) + floor((total - 1) / 12);
        moisArrivee = mod(total - 1, 12) + 1;
        longueur = eomday(anneeArrivee, moisArrivee);
        etaitFinDeMois = jourDepart(k) == eomday(annee(k), mois(k));
        switch round(drapeau)
            case 1, choisi = 1;
            case 2, choisi = longueur;
            case 3
                if etaitFinDeMois
                    choisi = longueur;
                else
                    choisi = min(jourDepart(k), longueur);
                end
            otherwise
                choisi = jourDepart(k);
                if regleFinMois && etaitFinDeMois
                    choisi = longueur;
                end
                choisi = min(choisi, longueur);
        end
        jour(k) = datenum(anneeArrivee, moisArrivee, choisi);
    end
end
