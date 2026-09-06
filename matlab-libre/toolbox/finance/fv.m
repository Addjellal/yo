function v = fv(taux, n, versement, valeurInitiale)
%FV Valeur future d'un placement à versements constants.
%   V = FV(TAUX,N,VERSEMENT) rend la valeur au bout de N périodes d'une
%   suite de N versements constants placés au taux TAUX par période, le
%   versement ayant lieu en fin de période.
%   V = FV(TAUX,N,VERSEMENT,VALEURINITIALE) ajoute un capital placé dès le
%   départ.
%
%   Le résultat vaut VALEURINITIALE*(1+TAUX)^N + VERSEMENT*((1+TAUX)^N-1)/
%   TAUX : le premier terme est la croissance du capital, le second la
%   somme d'une suite géométrique, chaque versement étant capitalisé sur
%   le temps qui lui reste. À taux nul la formule dégénère en une somme
%   simple, cas traité à part parce que la division ne l'est pas.
%
%   La convention de signe est celle des flux : un versement positif et un
%   résultat positif décrivent tous deux de l'argent reçu.
%
%   Exemple :
%      fv(0.05, 10, 100)
%
%   Voir aussi PV, NPV, IRR, EFFRR.
    if nargin < 4
        valeurInitiale = 0;
    end
    if taux == 0
        v = valeurInitiale + versement * n;
    else
        v = valeurInitiale * (1 + taux) ^ n + versement * ((1 + taux) ^ n - 1) / taux;
    end
end
