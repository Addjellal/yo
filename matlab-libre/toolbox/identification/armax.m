function modele = armax(donnees, ordres, varargin)
%ARMAX Estimation d'un modèle ARMAX.
%   M = ARMAX(Z,[na nb nc nk]) ajuste
%
%      A(q) y(t) = B(q) u(t-nk) + C(q) e(t)
%
%   Le polynôme C décrit la couleur du bruit. C'est ce qui distingue
%   ARMAX de ARX : ce dernier suppose que le bruit entre par le même
%   dénominateur que l'entrée, ce qui est rarement vrai et biaise ses
%   coefficients. ARMAX laisse au bruit son propre numérateur, au prix
%   d'un critère qui n'est plus quadratique.
%
%   Exemple :
%      rng(1);
%      u = sign(randn(600, 1));
%      e = 0.1 * randn(600, 1);
%      y = filter([0 0.5], [1 -0.8], u) + filter([1 0.6], [1 -0.8], e);
%      m = armax(iddata(y, u), [1 1 1 1]);
%      m.C      % environ 1 0.6
%
%   Voir aussi ARX, OE, BJ, POLYEST, PEM.
    ordres = matlibre_id_ordres_famille(ordres, 'armax');
    modele = matlibre_id_estimer(donnees, ordres, 'armax', varargin);
end
