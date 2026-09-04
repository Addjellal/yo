function [dureeModifiee, dureeAnnees, dureePeriodes] = bnddury(rendement, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BNDDURY Sensibilité d'une obligation, à partir de son rendement.
%   [DM,DA,DP] = BNDDURY(RENDEMENT,TAUX,REGLEMENT,ECHEANCE) rend la
%   sensibilité modifiée, la duration de Macaulay en années et la même en
%   périodes.
%
%   La duration de Macaulay est la date moyenne des flux, pondérée par
%   leur valeur actuelle : c'est la durée au bout de laquelle un
%   détenteur récupère en moyenne son argent. La sensibilité modifiée en
%   est la duration divisée par un plus le rendement par période : elle
%   dit de combien de pour cent le prix baisse quand le rendement monte
%   d'un point.
%
%   Exemple :
%      bnddury(0.06, 0.05, '01-Feb-2024', '01-Feb-2034')
%
%   Voir aussi BNDDURP, BNDCONVY, BNDPRICE, CFDUR.
    if nargin < 5,  periode = [];       end
    if nargin < 6,  base = [];          end
    if nargin < 7,  regleFinMois = [];  end
    if nargin < 8,  emission = [];      end
    if nargin < 9,  premierCoupon = []; end
    if nargin < 10, dernierCoupon = []; end
    if nargin < 11, debut = [];         end
    if nargin < 12, valeurFaciale = []; end
    if isempty(periode), periode = 2; end
    [montants, ~, facteurs] = cfamounts(tauxCoupon, reglement, echeance, periode, ...
        base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale);
    escompte = (1 + rendement / periode) .^ (-facteurs(2:end));
    valeurs = montants(2:end) .* escompte;
    total = sum(valeurs);
    dureePeriodes = sum(facteurs(2:end) .* valeurs) / total;
    dureeAnnees = dureePeriodes / periode;
    dureeModifiee = dureeAnnees / (1 + rendement / periode);
end
