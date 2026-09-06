function lisse = smoothPath(chemin, poidsDonnees, poidsLissage, tolerance)
%SMOOTHPATH Lissage d'une trajectoire par descente de gradient.
%   LISSE = SMOOTHPATH(CHEMIN,POIDSDONNEES,POIDSLISSAGE,TOLERANCE) arrondit
%   les angles d'un chemin en arbitrant entre deux exigences : rester près
%   des points d'origine, et minimiser la courbure.
%
%   Un chemin issu d'un planificateur en grille est fait d'angles droits :
%   impraticable tel quel, parce qu'aucun véhicule ne tourne sur place.
%   Le lissage le rend suivable, et un chemin lissé demande moins de
%   braquage — c'est la vérification qui compte.
%
%   Les extrémités ne bougent pas et le nombre de points ne change pas :
%   la fonction déplace les points intérieurs, elle n'en ajoute ni n'en
%   retire.
%
%   Les deux poids règlent le compromis : plus de lissage donne moins de
%   courbure mais plus d'écart aux points d'origine. Un chemin déjà droit
%   reste droit — le lissage n'invente rien.
%
%   L'angle le plus vif s'arrondit nettement ; la courbure cumulée, elle,
%   se conserve à peu près : le virage est étalé, non supprimé.
%
%   Exemple :
%      brut = [0 0; 1 0; 2 0; 3 0; 3 1; 3 2; 3 3];
%      lisse = smoothPath(brut, 0.5, 0.3);
%      max(vecnorm(diff(lisse, 2), 2, 2))   % bien moins que sqrt(2)
%
%   Voir aussi PUREPURSUIT, ASTAR, LANEOFFSET.
    if nargin < 2, poidsDonnees = 0.5; end
    if nargin < 3, poidsLissage = 0.3; end
    if nargin < 4, tolerance = 1e-6; end
    lisse = chemin;
    changement = tolerance + 1;
    while changement >= tolerance
        changement = 0;
        for i = 2:size(chemin, 1) - 1
            for j = 1:size(chemin, 2)
                ancien = lisse(i, j);
                lisse(i, j) = lisse(i, j) + poidsDonnees * (chemin(i, j) - lisse(i, j)) ...
                    + poidsLissage * (lisse(i-1, j) + lisse(i+1, j) - 2 * lisse(i, j));
                changement = changement + abs(ancien - lisse(i, j));
            end
        end
    end
end
