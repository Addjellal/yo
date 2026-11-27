function assignation = trackAssign(pistes, mesures, seuil)
%TRACKASSIGN Association mesures / pistes par plus proche voisin global.
%   A = TRACKASSIGN(PISTES,MESURES,SEUIL) rend, pour chaque piste, l'indice
%   de la mesure qui lui est attribuée, ou zéro si aucune ne convient.
%   PISTES et MESURES ont une ligne par objet et une colonne par
%   coordonnée. SEUIL est la distance au-delà de laquelle on préfère ne
%   rien attribuer ; il vaut l'infini par défaut.
%
%   Suivre plusieurs objets demande d'abord de savoir quelle mesure va à
%   quelle piste. Sans cette étape, deux objets qui se croisent échangent
%   leurs identités et les deux trajectoires deviennent fausses.
%
%   L'affectation est celle du plus proche voisin global (Blackman, 1986) :
%   la somme des distances des couples retenus est la plus petite
%   possible, chaque mesure servant au plus une fois. Elle est calculée
%   exactement par l'algorithme hongrois de Kuhn et Munkres, celui de
%   ASSIGNDETECTIONSTOTRACKS : laisser une piste ou une mesure seule coûte
%   SEUIL/2, si bien qu'aucun couple plus éloigné que SEUIL n'est retenu.
%   Servir les pistes l'une après l'autre, chacune prenant la mesure libre
%   la plus proche, ne donnerait pas l'optimum : une piste peut prendre la
%   mesure dont une autre avait davantage besoin.
%
%   Le seuil est ce qui distingue le suivi de l'invention : sans lui, une
%   piste dont l'objet a disparu s'accroche à n'importe quoi.
%
%   Exemple :
%      pistes  = [0 0; 10 0];
%      mesures = [10.2 0.3; 0.1 -0.2];
%      trackAssign(pistes, mesures)          % [2 1]
%      trackAssign(pistes, [0.1 -0.2; 50 50], 3)   % [1 0]
%      % Le plus proche d'abord prendrait 0.4 pour la première piste :
%      trackAssign([0 0; 1 0], [0.4 0; -0.7 0])    % [2 1], total 1.3 et non 2.1
%
%   Voir aussi ASSIGNDETECTIONSTOTRACKS, ASSIGNMUNKRES, KALMANFILTER.
    if nargin < 3 || isempty(seuil)
        seuil = inf;
    end
    nPistes = size(pistes, 1);
    assignation = zeros(nPistes, 1);
    if nPistes == 0 || isempty(mesures)
        return
    end
    if size(pistes, 2) ~= size(mesures, 2)
        error('fusion:trackAssign:Dimension', ...
              'Tracks and detections must have the same number of coordinates.');
    end
    distances = zeros(nPistes, size(mesures, 1));
    for k = 1:nPistes
        distances(k, :) = sqrt(sum((mesures - pistes(k, :)) .^ 2, 2)).';
    end
    if isfinite(seuil)
        cout = seuil / 2;
    else
        % Sans seuil, tout couple vaut mieux que deux objets seuls.
        cout = max(distances(:)) * (nPistes + size(mesures, 1)) + 1;
    end
    appariements = assignDetectionsToTracks(distances, cout);
    if ~isempty(appariements)
        assignation(appariements(:, 1)) = appariements(:, 2);
    end
end
