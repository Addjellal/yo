function modele = oe(donnees, ordres, varargin)
%OE Estimation d'un modèle sortie-erreur.
%   M = OE(Z,[nb nf nk]) ajuste
%
%      y(t) = [B(q)/F(q)] u(t-nk) + e(t)
%
%   Le bruit s'ajoute à la sortie sans passer par la dynamique : le modèle
%   ne décrit donc que la relation de l'entrée à la sortie, et il la décrit
%   sans biais quel que soit le bruit — c'est sa vertu. En revanche il ne
%   dit rien de la couleur de ce bruit, et sa prédiction à un pas n'utilise
%   pas les sorties passées.
%
%   Exemple :
%      rng(2);
%      u = sign(randn(600, 1));
%      y = filter([0 0.5], [1 -0.8], u) + 0.1 * randn(600, 1);
%      m = oe(iddata(y, u), [1 1 1]);
%      m.F      % environ 1 -0.8
%
%   Voir aussi ARX, ARMAX, BJ, POLYEST, TFEST.
    ordres = matlibre_id_ordres_famille(ordres, 'oe');
    modele = matlibre_id_estimer(donnees, ordres, 'oe', varargin);
end
