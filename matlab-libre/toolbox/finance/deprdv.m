function reste = deprdv(cout, valeurResiduelle, amortissements)
%DEPRDV Valeur restant à amortir.
%   R = DEPRDV(COUT,RESIDUELLE,AMORTISSEMENTS) rend ce qu'il reste à
%   amortir une fois retranchés les amortissements déjà pratiqués.
%
%   Exemple :
%      deprdv(10000, 1000, depsoyd(10000, 1000, 5)(1:2))    % 4600
%
%   Voir aussi DEPSTLN, DEPSOYD, DEPFIXDB, DEPGENDB.
    reste = cout - valeurResiduelle - sum(amortissements(:));
end
