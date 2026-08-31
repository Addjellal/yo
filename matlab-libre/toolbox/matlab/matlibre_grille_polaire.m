function matlibre_grille_polaire(rayonMaximal)
%MATLIBRE_GRILLE_POLAIRE Les cercles et les rayons d'un tracé polaire.
%   Fonction interne : elle n'existe pas dans MATLAB, qui a de vrais axes
%   polaires. POLARPLOT, COMPASS et ROSE la posent sous leur courbe pour
%   que les rayons se lisent.
    if ~isfinite(rayonMaximal) || rayonMaximal <= 0
        rayonMaximal = 1;
    end
    % Un rayon arrondi vers le haut, pour que les cercles tombent juste.
    pas = 10 ^ floor(log10(rayonMaximal));
    while rayonMaximal / pas > 5
        pas = pas * 2;
    end
    while rayonMaximal / pas < 2
        pas = pas / 2;
    end
    borne = ceil(rayonMaximal / pas) * pas;
    t = linspace(0, 2 * pi, 200);
    aEffacer = ishold();
    hold('on');
    for r = pas:pas:borne
        plot(r * cos(t), r * sin(t), 'Color', [0.8 0.8 0.8]);
    end
    for angle = 0:pi/6:pi - 0.01
        plot([-borne, borne] * cos(angle), [-borne, borne] * sin(angle), ...
             'Color', [0.88 0.88 0.88]);
    end
    for r = pas:pas:borne
        text(r, 0.03 * borne, num2str(r), 'Color', [0.45 0.45 0.45]);
    end
    if ~aEffacer
        hold('off');
    end
    xlim([-borne * 1.1, borne * 1.1]);
    ylim([-borne * 1.1, borne * 1.1]);
    axis('equal');
end
