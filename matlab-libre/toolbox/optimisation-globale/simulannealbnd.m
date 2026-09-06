function [x, valeur] = simulannealbnd(fonction, x0, bas, haut, iterations)
%SIMULANNEALBND Recuit simulé avec bornes.
%   [X,VALEUR] = SIMULANNEALBND(F,X0,BAS,HAUT,ITERATIONS) minimise en
%   acceptant parfois de remonter, avec une probabilité qui décroît au
%   long du refroidissement.
%
%   C'est cette acceptation des mauvais pas qui distingue le recuit d'une
%   descente : elle permet de sortir d'un minimum local. La température
%   règle sa fréquence — haute, la marche est presque aléatoire ; basse,
%   c'est une descente pure.
%
%   La décroissance de température est le seul vrai réglage. Refroidir
%   trop vite fige la solution dans le premier bassin rencontré ; trop
%   lentement gaspille les évaluations. La convergence vers l'optimum
%   global n'est garantie que pour une décroissance logarithmique, trop
%   lente pour être employée en pratique.
%
%   Exemple :
%      f = @(x) sum(x.^2 - 10 * cos(2*pi*x) + 10);
%      [x, v] = simulannealbnd(f, zeros(1,3), -5*ones(1,3), 5*ones(1,3));
%
%   Voir aussi PARTICLESWARM, GA, MULTISTART.
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
