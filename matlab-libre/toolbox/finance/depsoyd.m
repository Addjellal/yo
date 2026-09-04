function annuites = depsoyd(cout, valeurResiduelle, duree)
%DEPSOYD Amortissement par la somme des numéros d'années.
%   A = DEPSOYD(COUT,RESIDUELLE,DUREE) répartit la valeur à amortir
%   proportionnellement au nombre d'années restantes : la première annuité
%   vaut DUREE parts, la dernière une seule, sur un total de
%   DUREE*(DUREE+1)/2 parts.
%
%   C'est un amortissement dégressif qui atteint exactement la valeur
%   résiduelle à la fin, ce que l'amortissement à taux constant ne fait
%   pas.
%
%   Exemple :
%      depsoyd(10000, 1000, 5)      % 3000 2400 1800 1200 600
%
%   Voir aussi DEPSTLN, DEPFIXDB, DEPGENDB, DEPRDV.
    duree = round(duree);
    parts = duree:-1:1;
    annuites = (cout - valeurResiduelle) .* parts ./ sum(parts);
end
