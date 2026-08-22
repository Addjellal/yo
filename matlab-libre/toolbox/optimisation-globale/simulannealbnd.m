function [x, valeur] = simulannealbnd(fonction, x0, bas, haut, iterations)
%SIMULANNEALBND Recuit simulé avec bornes.
    if nargin < 5
        iterations = 5000;
    end
    x = x0(:).';
    bas = bas(:).';
    haut = haut(:).';
    valeur = fonction(x);
    meilleur = x;
    meilleureValeur = valeur;
    for k = 1:iterations
        temperature = 1 / log(k + 1);
        candidat = x + temperature * (haut - bas) .* (rand(size(x)) - 0.5);
        candidat = min(max(candidat, bas), haut);
        v = fonction(candidat);
        if v < valeur || rand() < exp((valeur - v) / max(temperature, 1e-12))
            x = candidat;
            valeur = v;
        end
        if valeur < meilleureValeur
            meilleureValeur = valeur;
            meilleur = x;
        end
    end
    x = meilleur;
    valeur = meilleureValeur;
end
