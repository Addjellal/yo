function v = fv(taux, n, versement, valeurInitiale)
%FV Valeur future d'un placement à versements constants.
    if nargin < 4
        valeurInitiale = 0;
    end
    if taux == 0
        v = valeurInitiale + versement * n;
    else
        v = valeurInitiale * (1 + taux) ^ n + versement * ((1 + taux) ^ n - 1) / taux;
    end
end
