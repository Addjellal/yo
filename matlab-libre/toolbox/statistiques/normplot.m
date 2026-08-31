function H = normplot(x)
%NORMPLOT Droite de Henry : les données sont-elles normales ?
%   NORMPLOT(X) place les observations triées de X en regard des
%   quantiles de la loi normale, et trace la droite qui passe par les
%   deux quartiles. Si X est normal, les points s'alignent sur cette
%   droite ; la façon dont ils s'en écartent dit ce qui cloche :
%
%      une courbure en S      des queues plus lourdes que la normale ;
%      un arc                 une dissymétrie ;
%      un point isolé au bout une valeur aberrante.
%
%   Pour une matrice, chaque colonne donne sa propre série de points.
%
%   L'axe des ordonnées est gradué en probabilités et non en quantiles :
%   c'est ce qui permet de lire directement la proportion d'observations
%   sous un seuil.
%
%   H = NORMPLOT(X) rend les poignées des traits.
%
%   Le tracé est un examen, non un test : quand il faut une réponse
%   chiffrée, LILLIETEST ou JBTEST la donnent.
%
%   Exemples :
%      normplot(randn(200, 1));            % aligne
%      normplot(exprnd(1, 200, 1));        % courbe : dissymetrique
%      normplot(trnd(2, 200, 1));          % un S : queues lourdes
%
%   Voir aussi PROBPLOT, HISTFIT, LILLIETEST, JBTEST, QQPLOT.
    H = probplot('normal', x);
    if nargout == 0
        clear H;
    end
end
