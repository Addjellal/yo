function c = crossentropy(predit, cible)
%CROSSENTROPY Entropie croisée moyenne par observation.
%   C = CROSSENTROPY(PREDIT,CIBLE) rend -somme(CIBLE .* log(PREDIT))
%   divisée par le nombre d'observations, c'est-à-dire les colonnes de
%   CIBLE. CIBLE est codée un-parmi-N : une seule ligne vaut 1 par
%   observation, et l'entropie croisée se réduit alors à -log de la
%   probabilité accordée à la bonne réponse. Minimiser l'entropie croisée,
%   c'est maximiser la vraisemblance des étiquettes.
%
%   C'est ce qui la distingue de l'erreur quadratique pour classer. Se
%   tromper avec assurance coûte arbitrairement cher, puisque log tend
%   vers moins l'infini ; et derrière une sigmoïde saturée le gradient de
%   l'erreur quadratique s'annule alors même que la réponse est fausse,
%   tandis que celui de l'entropie croisée reste proportionnel à l'écart.
%
%   PREDIT est borné à 1e-12 près de zéro et de un : sans cette borne une
%   probabilité nulle sur la bonne classe rendrait l'infini.
%
%   Exemple :
%      cible = [1 0; 0 1];
%      crossentropy([0.9 0.2; 0.1 0.8], cible)
%
%   Voir aussi MSE, L1LOSS, L2LOSS, SOFTMAXLAYER.
    p = max(min(predit, 1 - 1e-12), 1e-12);
    c = -sum(sum(cible .* log(p))) / size(cible, 2);
end
