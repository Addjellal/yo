function [risques, rendements, poids] = frontcon(rendementsAttendus, covariance, nombrePoints, rendementsCibles, bornes, groupes, bornesGroupes)
%FRONTCON Frontière efficiente avec bornes par actif et par groupe.
%   [R,M,W] = FRONTCON(MU,SIGMA,N) rend N portefeuilles efficients, les
%   poids étant positifs et sommant à un.
%
%   FRONTCON(...,BORNES) donne une matrice à deux lignes, minimums puis
%   maximums, une colonne par actif. FRONTCON(...,GROUPES,BORNESGROUPES)
%   ajoute des bornes par groupe.
%
%   C'est l'interface ancienne ; PORTOPT accepte des contraintes
%   quelconques.
%
%   Exemple :
%      mu = [0.10 0.15 0.12];
%      s = [0.04 0.01 0.00; 0.01 0.09 0.02; 0.00 0.02 0.06];
%      [r, m, w] = frontcon(mu, s, 5, [], [0 0 0; 0.5 0.5 0.5])
%
%   Voir aussi PORTOPT, PORTCONS, PORTSTATS.
    n = numel(rendementsAttendus);
    if nargin < 3, nombrePoints = []; end
    if nargin < 4, rendementsCibles = []; end
    contraintes = pcpval(1, n);
    if nargin >= 5 && ~isempty(bornes)
        bornes = double(bornes);
        contraintes = [contraintes; pcalims(bornes(1, :), bornes(2, :), n)];
    end
    if nargin >= 7 && ~isempty(groupes) && ~isempty(bornesGroupes)
        bornesGroupes = double(bornesGroupes);
        contraintes = [contraintes; ...
                       pcglims(groupes, bornesGroupes(:, 1), bornesGroupes(:, 2))];
    end
    [risques, rendements, poids] = portopt(rendementsAttendus, covariance, ...
                                           nombrePoints, rendementsCibles, contraintes);
end
