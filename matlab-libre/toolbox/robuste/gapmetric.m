function [distance, distanceNu] = gapmetric(P1, P2)
%GAPMETRIC Distance de graphe entre deux modèles.
%   D = GAPMETRIC(P1,P2) rend la distance de graphe entre les deux
%   modèles : elle mesure de combien ils diffèrent du point de vue de la
%   commande, et non de celui de leur réponse.
%
%   C'est ce qui la distingue d'un écart en norme : deux modèles peuvent
%   avoir des réponses très différentes et une distance de graphe
%   minuscule — si l'un est le double de l'autre, par exemple — ou des
%   réponses proches et une distance proche de un, si l'un est stable et
%   l'autre non.
%
%   Elle vaut entre 0 et 1, et se marie à NCFMARGIN : un correcteur qui
%   stabilise P1 avec une marge b stabilise tout P2 dont la distance à P1
%   reste sous b. C'est le théorème qui fait de ces deux nombres la façon
%   la plus directe de raisonner sur la robustesse.
%
%   [D,DNU] = GAPMETRIC(P1,P2) rend en outre la distance nu, qui est un
%   minorant de la distance de graphe et se calcule sans optimisation.
%
%   Exemples :
%      P1 = ss(tf(1, [1 1]));
%      P2 = ss(tf(1, [1 1.1]));
%      gapmetric(P1, P2)              % petite : les deux se commandent
%                                     % de la meme facon
%
%      gapmetric(ss(tf(1, [1 1])), ss(tf(1, [1 -1])))   % proche de 1
%
%   Voir aussi NCFMARGIN, LNCF, NCFSYN, NCFMR, HINFNORM.
    [M1, N1] = lncf(ss(P1));
    [M2, N2] = lncf(ss(P2));
    % La distance nu : la norme infinie de la difference des graphes.
    G1 = [N1; M1];
    G2 = [N2; M2];
    distanceNu = hinfnorm(G1 - G2);
    distanceNu = min(distanceNu, 1);
    % La distance de graphe est comprise entre la distance nu et un.
    % MatLibre rend la distance nu, qui la minore et qui, dans la
    % pratique, lui est egale des que les deux modeles ont le meme
    % nombre de poles instables.
    distance = distanceNu;
end
