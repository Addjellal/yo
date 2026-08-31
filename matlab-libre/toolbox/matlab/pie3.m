function H = pie3(x, decoller, etiquettes)
%PIE3 Diagramme circulaire en perspective.
%   PIE3(X) trace le même diagramme que PIE, vu de biais. Le rendu de
%   MatLibre est plan : le disque est simplement aplati verticalement,
%   ce qui donne l'ellipse que la perspective produirait, sans épaisseur.
%
%   PIE3(X,DECOLLER) et PIE3(X,DECOLLER,ETIQUETTES) suivent la même
%   règle que PIE.
%
%   La perspective d'un diagramme circulaire fausse la lecture : les
%   secteurs du devant paraissent plus grands que ceux du fond, à surface
%   égale. PIE existe pour cette raison, et vaut mieux.
%
%   Exemples :
%      pie3([3 1 1]);
%      pie3([30 20 50], [0 0 1], {'nord', 'sud', 'est'});
%
%   Voir aussi PIE, BAR3, PARETO, FILL.
    if nargin < 2
        decoller = [];
    end
    if nargin < 3
        etiquettes = {};
    end
    H = pie(x, decoller, etiquettes);
    % L'aplatissement : on ecrase les ordonnees de moitie.
    for k = 1:numel(H)
        y = get(H(k), 'YData');
        if ~isempty(y)
            set(H(k), 'YData', y * 0.55);
        end
    end
    ylim([-0.85 0.85]);
    axis('off');
    if nargout == 0
        clear H;
    end
end
