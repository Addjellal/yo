function [perte, debut, fin] = maxdrawdown(cours)
%MAXDRAWDOWN Perte maximale depuis un sommet.
%   PERTE = MAXDRAWDOWN(COURS) rend la plus forte baisse relative subie
%   entre un sommet et un creux postérieur, en fraction du sommet.
%   [PERTE,DEBUT,FIN] = MAXDRAWDOWN(COURS) rend en plus les indices du
%   sommet et du creux qui la réalisent.
%
%   Le parcours se fait en une passe : on tient le maximum courant, et la
%   baisse mesurée depuis lui. C'est bien la plus grande perte qu'aurait
%   subie quelqu'un entré au pire moment et sorti au pire moment suivant —
%   l'ordre compte, un creux antérieur au sommet ne compte pas.
%
%   L'écart type traite symétriquement hausses et baisses ; cette mesure
%   ne regarde que le mauvais côté, et dit combien il aurait fallu de
%   sang-froid pour tenir. Une stratégie de rendement moyen honorable mais
%   de perte maximale de 60 % est en pratique intenable, quel que soit son
%   ratio de Sharpe.
%
%   Exemple :
%      [p, d, f] = maxdrawdown([100 120 90 95 130]);
%
%   Voir aussi SHARPE, RET2TICK, PORTSTATS.
    cours = cours(:);
    sommet = cours(1);
    indiceSommet = 1;
    perte = 0;
    debut = 1;
    fin = 1;
    for k = 1:numel(cours)
        if cours(k) > sommet
            sommet = cours(k);
            indiceSommet = k;
        end
        baisse = (sommet - cours(k)) / sommet;
        if baisse > perte
            perte = baisse;
            debut = indiceSommet;
            fin = k;
        end
    end
end
