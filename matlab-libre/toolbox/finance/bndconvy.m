function [convexiteAnnees, convexitePeriodes] = bndconvy(rendement, tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%BNDCONVY Convexité d'une obligation, à partir de son rendement.
%   [CA,CP] = BNDCONVY(RENDEMENT,TAUX,REGLEMENT,ECHEANCE) rend la
%   convexité en années au carré et en périodes au carré.
%
%   La sensibilité seule décrit une droite : elle sous-estime le prix
%   quand le rendement baisse et le surestime quand il monte. La
%   convexité est la courbure qui corrige cet écart — la dérivée seconde
%   du prix par rapport au rendement, rapportée au prix.
%
%   Exemple :
%      bndconvy(0.06, 0.05, '01-Feb-2024', '01-Feb-2034')
%
%   Voir aussi BNDCONVP, BNDDURY, CFCONV.
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
    taux = 1 + rendement / periode;
    escompte = taux .^ (-facteurs(2:end));
    valeurs = montants(2:end) .* escompte;
    total = sum(valeurs);
    t = facteurs(2:end);
    convexitePeriodes = sum(t .* (t + 1) .* valeurs) / (total * taux ^ 2);
    convexiteAnnees = convexitePeriodes / periode ^ 2;
end
