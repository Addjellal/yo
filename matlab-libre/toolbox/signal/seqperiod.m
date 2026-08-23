function [p, erreur_] = seqperiod(x)
%SEQPERIOD Période la plus courte qui explique une séquence.
%   P = SEQPERIOD(X) cherche le plus petit P tel que X(k+P) = X(k) pour
%   tout k possible. Sans période exacte, rend celle qui minimise l'écart.
%
%   Exemple :  seqperiod([1 2 1 2 1 2])   % 2
    x = x(:);
    n = numel(x);
    meilleur = n;
    meilleureErreur = inf;
    for p = 1:n
        comparables = n - p;
        if comparables <= 0
            e = 0;
        else
            e = sum((x(1:comparables) - x(p+1:n)).^2) / comparables;
        end
        if e < meilleureErreur - 1e-12
            meilleureErreur = e;
            meilleur = p;
        end
        if meilleureErreur == 0, break, end
    end
    p = meilleur;
    erreur_ = meilleureErreur;
end
