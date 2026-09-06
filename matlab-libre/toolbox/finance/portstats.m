function [rendement, risque] = portstats(rendements, covariance, poids)
%PORTSTATS Rendement et écart type d'un portefeuille.
%   [RENDEMENT,RISQUE] = PORTSTATS(RENDEMENTS,COVARIANCE,POIDS) rend
%   l'espérance de rendement du portefeuille, w'*mu, et son écart type,
%   sqrt(w'*C*w).
%
%   Les deux formules ne se ressemblent pas, et c'est tout le propos de
%   Markowitz : le rendement est linéaire en les poids, le risque ne
%   l'est pas. Deux actifs de même rendement et de même écart type, mal
%   corrélés, donnent un portefeuille de même rendement et d'écart type
%   moindre — la diversification ne coûte rien en espérance et retire du
%   risque, ce qui n'arrive qu'à cause de ce terme croisé.
%
%   La covariance doit être symétrique et semi-définie positive, faute de
%   quoi la racine porte sur un nombre négatif. POIDS n'est pas normalisé
%   ici : leur somme vaut un pour un portefeuille pleinement investi, plus
%   pour un portefeuille à effet de levier.
%
%   Exemple :
%      C = [0.04 0.01; 0.01 0.09];
%      [r, s] = portstats([0.08 0.12], C, [0.5 0.5]);
%
%   Voir aussi SHARPE, PORTALLOC, MAXDRAWDOWN.
    poids = poids(:);
    rendement = rendements(:).' * poids;
    risque = sqrt(poids.' * covariance * poids);
end
