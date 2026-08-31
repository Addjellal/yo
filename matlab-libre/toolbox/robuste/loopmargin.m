function [entree, sortie, boucle] = loopmargin(G, K)
%LOOPMARGIN Toutes les marges d'une boucle, en entrée et en sortie.
%   [EM,SM,BM] = LOOPMARGIN(G,K) rend les marges de stabilité de la
%   boucle formée du procédé G et du correcteur K, en contre-réaction
%   négative, mesurées à trois endroits :
%
%      EM  en entrée du procédé, en ouvrant la boucle après K ;
%      SM  en sortie du procédé, en ouvrant la boucle après G ;
%      BM  aux deux à la fois — la marge multiboucle, qui tient compte
%          de perturbations simultanées.
%
%   Chaque structure porte :
%      GainMargin     les marges de gain, en valeur absolue ;
%      PhaseMargin    les marges de phase, en degrés ;
%      DelayMargin    le retard pur admissible, en secondes ;
%      Frequency      les pulsations où elles sont atteintes ;
%      Stable         vrai si la boucle est stable.
%
%   BM porte en outre DiskMargin, la marge de disque : elle mesure ce que
%   la boucle supporte en gain et en phase à la fois, ce qu'aucune des
%   deux marges classiques ne dit.
%
%   Sur un système monovariable, les marges en entrée et en sortie sont
%   égales ; c'est en multivariable qu'elles diffèrent, et une boucle
%   peut avoir d'excellentes marges voie par voie et céder à une
%   perturbation simultanée. C'est ce que BM montre.
%
%   Exemples :
%      G = ss(tf(1, [1 1 0]));
%      K = ss(tf(2, 1));
%      [em, sm, bm] = loopmargin(G, K);
%      em.PhaseMargin
%      bm.DiskMargin
%
%   Voir aussi MARGIN, ALLMARGIN, NCFMARGIN, STABILITYMARGIN, LOOPSENS.
    G = ss(G);
    K = ss(K);
    L = loopsens(G, K);
    entree = margesEn(K * G, L.Stable);
    sortie = margesEn(G * K, L.Stable);
    % La marge multiboucle : l'inverse du plus grand pic de sensibilite,
    % en entree comme en sortie.
    picEntree = hinfnorm(L.Si);
    picSortie = hinfnorm(L.So);
    pic = max(picEntree, picSortie);
    if ~isfinite(pic) || pic <= 0
        marge = 0;
    else
        marge = 1 / pic;
    end
    boucle = struct('GainMargin', [1 / (1 + marge), 1 / max(1 - marge, eps)], ...
                    'PhaseMargin', 2 * asin(min(marge / 2, 1)) * 180 / pi, ...
                    'DiskMargin', marge, ...
                    'Stable', L.Stable, ...
                    'Frequency', NaN, ...
                    'PeakSensitivity', pic);
end

function m = margesEn(L, stable)
%MARGESEN Les marges classiques d'une boucle ouverte.
    [gm, pm, wg, wp] = margin(L);
    if isfinite(pm) && isfinite(wp) && wp > 0
        retard = (pm * pi / 180) / wp;
    else
        retard = Inf;
    end
    m = struct('GainMargin', gm, 'PhaseMargin', pm, ...
               'DelayMargin', retard, 'Frequency', [wg, wp], ...
               'Stable', stable);
end
