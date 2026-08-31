function [H, effectifs, centres] = rose(theta, classes)
%ROSE Histogramme angulaire.
%   ROSE(THETA) répartit les angles THETA — en radians — en vingt
%   secteurs et trace, pour chacun, un secteur dont le rayon est
%   l'effectif. C'est l'histogramme des directions : il montre si les
%   angles se concentrent quelque part.
%
%   ROSE(THETA,N) emploie N secteurs.
%   ROSE(THETA,BORDS) emploie les bords donnés.
%
%   [H,N,C] = ROSE(THETA,...) rend les poignées, les effectifs et les
%   centres des secteurs.
%
%   Exemples :
%      rose(randn(500, 1));                   % concentre autour de zero
%      rose(2 * pi * rand(500, 1), 12);       % a peu pres uniforme
%      [~, n, c] = rose([0 0 0 pi pi], 4);
%
%   Voir aussi POLARPLOT, COMPASS, HISTOGRAM, HISTCOUNTS.
    if nargin < 2 || isempty(classes)
        classes = 20;
    end
    theta = mod(theta(:), 2 * pi);
    if isscalar(classes)
        bords = linspace(0, 2 * pi, classes + 1);
    else
        bords = classes(:)';
    end
    n = numel(bords) - 1;
    effectifs = zeros(1, n);
    for k = 1:n
        if k < n
            effectifs(k) = sum(theta >= bords(k) & theta < bords(k + 1));
        else
            effectifs(k) = sum(theta >= bords(k) & theta <= bords(k + 1));
        end
    end
    centres = (bords(1:end - 1) + bords(2:end)) / 2;

    aEffacer = ishold();
    if ~aEffacer
        cla;
        matlibre_grille_polaire(max(effectifs));
    end
    hold('on');
    H = [];
    for k = 1:n
        if effectifs(k) == 0
            continue;
        end
        t = linspace(bords(k), bords(k + 1), 20);
        r = effectifs(k);
        H(end + 1) = fill([0, r * cos(t), 0], [0, r * sin(t), 0], ...
                          'FaceColor', matlibre_couleur_secteur(1));   %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
