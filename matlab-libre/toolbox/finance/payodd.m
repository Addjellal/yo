function versement = payodd(taux, periodes, valeurActuelle, valeurFuture, jours)
%PAYODD Versement quand la première période est de longueur inhabituelle.
%   V = PAYODD(TAUX,N,PV,FV,JOURS) traite un prêt dont la première
%   période compte JOURS jours au lieu des trente d'un mois plein. Les
%   jours en trop portent un intérêt simple au prorata, ajouté au capital
%   avant que le versement régulier ne soit déterminé ; avec trente
%   jours, le résultat est celui de PAYPER.
%
%   Exemple :
%      payodd(0.09 / 12, 36, 20000, 0, 45)
%
%   Voir aussi PAYPER, PAYADV, PAYUNI, AMORTIZE.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(jours),        jours = 30;       end
    capitalise = valeurActuelle * (1 + taux * (jours - 30) / 30);
    versement = payper(taux, periodes, capitalise, valeurFuture, 0);
end
