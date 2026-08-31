function [marge, frequence] = ncfmargin(P, C, signe)
%NCFMARGIN Marge de stabilité des facteurs premiers normalisés.
%   B = NCFMARGIN(P,C) rend la marge de stabilité de la boucle formée par
%   le procédé P et le correcteur C, en contre-réaction négative :
%
%      b = 1 / || [I ; C] (I + P C)^-1 [I  P] ||_inf
%
%   C'est la plus grande perturbation, mesurée sur les facteurs premiers
%   normalisés de P, que la boucle supporte sans devenir instable. Elle
%   vaut entre 0 et 1 ; au-dessus de 0.25 la boucle est robuste, en
%   dessous de 0.1 elle est fragile.
%
%   [B,W] = NCFMARGIN(P,C) rend en outre la fréquence où le pire arrive.
%
%   NCFMARGIN(P,C,SIGNE) prend SIGNE = +1 pour une contre-réaction
%   positive ; le défaut est -1, la contre-réaction négative.
%
%   Cette marge dit d'un seul nombre ce que les marges de gain et de
%   phase disent séparément, et elle vaut aussi pour les systèmes à
%   plusieurs entrées et sorties, où celles-ci ne suffisent pas.
%
%   Exemples :
%      P = ss(tf(1, [1 -1]));         % procede instable
%      C = ss(tf([2 1], [1 0]));
%      [b, w] = ncfmargin(P, C)
%
%   Voir aussi LNCF, NCFSYN, GAPMETRIC, LOOPMARGIN, HINFNORM, DISKMARGIN.
    if nargin < 3 || isempty(signe)
        signe = -1;
    end
    Pss = ss(P);
    Css = ss(C);
    if signe > 0
        Css = -Css;
    end
    % Les quatre transmittances de la boucle, prises par LOOPSENS : les
    % assembler a la main donnait une realisation non minimale, dont les
    % modes caches instables faisaient rendre l'infini.
    L = loopsens(Pss, Css);
    boucle = [L.So, L.PSi; L.CSo, L.Ti];
    [pire, frequence] = hinfnorm(boucle);
    if ~isfinite(pire) || pire <= 0
        marge = 0;
        frequence = 0;
        return;
    end
    marge = 1 / pire;
end
