function [ratio, erreurSuivi] = inforatio(actif, reference)
%INFORATIO Ratio d'information d'un portefeuille.
%   [R,E] = INFORATIO(ACTIF,REFERENCE) rend le rendement moyen en excès
%   de la référence, divisé par son écart type, ainsi que cet écart type
%   — l'erreur de suivi.
%
%   Le ratio de Sharpe mesure le rendement par unité de risque total ; le
%   ratio d'information mesure le rendement par unité de risque pris
%   contre la référence. C'est la bonne mesure pour un gérant dont le
%   mandat est de battre un indice.
%
%   Exemple :
%      inforatio(actif, indice)
%
%   Voir aussi SHARPE, PORTALPHA, MAXDRAWDOWN.
    actif = double(actif);
    reference = double(reference);
    if size(actif, 1) == 1, actif = actif.'; end
    if size(reference, 1) == 1, reference = reference.'; end
    if size(reference, 2) == 1 && size(actif, 2) > 1
        reference = repmat(reference, 1, size(actif, 2));
    end
    excedent = actif - reference;
    erreurSuivi = std(excedent, 0, 1);
    ratio = mean(excedent, 1) ./ erreurSuivi;
end
