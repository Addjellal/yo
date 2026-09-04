function annuite = depstln(cout, valeurResiduelle, duree)
%DEPSTLN Amortissement linéaire.
%   A = DEPSTLN(COUT,RESIDUELLE,DUREE) rend l'annuité constante : la
%   valeur à amortir, divisée par le nombre d'années.
%
%   Exemple :
%      depstln(10000, 1000, 5)      % 1800 par an
%
%   Voir aussi DEPSOYD, DEPFIXDB, DEPGENDB, DEPRDV.
    annuite = (cout - valeurResiduelle) ./ duree;
end
