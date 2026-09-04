function ecart = cdsspread(donneesTaux, probabilites, reglement, echeance, recuperation, frequence, base)
%CDSSPREAD Écart d'équilibre d'un contrat de protection contre le défaut.
%   E = CDSSPREAD(TAUX,PROBABILITES,REGLEMENT,ECHEANCE) rend, en points
%   de base, la prime annuelle qui rend le contrat de valeur nulle.
%
%   PROBABILITES est une matrice [dates probabilité cumulée de défaut],
%   telle que la rend CDSBOOTSTRAP.
%
%   L'écart est le rapport de deux valeurs actuelles : celle du
%   versement attendu en cas de défaut, et celle d'une prime unitaire
%   payée tant qu'il n'y a pas défaut.
%
%   Exemple :
%      cdsspread(taux, probabilites, '01-Jan-2024', '01-Jan-2029')
%
%   Voir aussi CDSBOOTSTRAP, CDSPRICE.
    if nargin < 5 || isempty(recuperation), recuperation = 0.4; end
    if nargin < 6 || isempty(frequence),    frequence = 4;      end
    if nargin < 7 || isempty(base),         base = 2;           end
    reglement = matlibre_dates(reglement);
    courbe = matlibre_cds_courbe(donneesTaux, reglement);
    [hasard, datesHasard] = matlibre_cds_hasard(probabilites, reglement);
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    ecart = zeros(numel(echeance), 1);
    for k = 1:numel(echeance)
        ecart(k) = 10000 * matlibre_cds_ecart(courbe, reglement, echeance(k), ...
            hasard, datesHasard, recuperation, frequence, base);
    end
end
