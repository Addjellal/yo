function versement = payuni(taux, periodes, flux)
%PAYUNI Versement constant équivalant à une série de flux.
%   V = PAYUNI(TAUX,N,FLUX) rend le versement constant, sur N périodes,
%   dont la valeur actuelle est celle de FLUX. C'est la façon de comparer
%   deux investissements aux échéanciers différents : on les ramène tous
%   deux à une suite de versements égaux.
%
%   Exemple :
%      payuni(0.08, 5, [-5000 1000 2000 3000 4000])
%
%   Voir aussi PVVAR, PAYPER, PAYADV, PAYODD.
    valeur = pvvar(flux, taux);
    versement = payper(taux, periodes, valeur, 0, 0);
end
