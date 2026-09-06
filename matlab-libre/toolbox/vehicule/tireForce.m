function F = tireForce(glissement, chargeVerticale, B, C, D, E)
%TIREFORCE Force du pneu par la formule magique de Pacejka.
%   F = TIREFORCE(GLISSEMENT,CHARGEVERTICALE,B,C,D,E) rend la force
%   transmise par le pneu. B, C, D et E sont les quatre coefficients de la
%   formule ; leurs valeurs par défaut décrivent un pneu de tourisme sur
%   route sèche.
%
%   La formule est dite magique parce qu'elle n'a pas de fondement
%   physique : c'est une forme qui s'ajuste bien aux mesures, et rien de
%   plus. Elle en reproduit néanmoins tout ce qui compte.
%
%   La force ne croît pas indéfiniment avec le glissement : elle passe par
%   un maximum vers dix à vingt pour cent, puis retombe. Ce maximum est la
%   limite d'adhérence, et la zone au-delà est instable — c'est là que la
%   roue se bloque ou patine. Tout l'ABS et tout le contrôle de traction
%   consistent à ne pas y entrer.
%
%   Près de zéro la relation est linéaire : c'est la rigidité de dérive,
%   celle qu'emploient les modèles linéarisés. La formule est impaire, et
%   proportionnelle à la charge verticale — d'où l'intérêt de charger
%   l'essieu moteur au démarrage.
%
%   Exemple :
%      g = linspace(0, 0.6, 601);
%      [Fmax, k] = max(arrayfun(@(x) tireForce(x, 4000), g));
%      g(k)                            % le glissement optimal
%      Fmax / 4000                     % le coefficient d'adherence
%
%   Voir aussi LONGITUDINAL, BICYCLEMODEL.
    if nargin < 3, B = 10; end
    if nargin < 4, C = 1.9; end
    if nargin < 5, D = 1.0; end
    if nargin < 6, E = 0.97; end
    F = chargeVerticale * D * sin(C * atan(B * glissement - ...
        E * (B * glissement - atan(B * glissement))));
end
