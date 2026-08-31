function H = pie(x, decoller, etiquettes)
%PIE Diagramme circulaire.
%   PIE(X) trace un disque découpé en secteurs proportionnels aux
%   éléments de X. Si la somme de X vaut un ou moins, les valeurs sont
%   prises pour des fractions et le disque reste incomplet ; sinon elles
%   sont normalisées.
%
%   PIE(X,DECOLLER) écarte du centre les secteurs dont l'élément de
%   DECOLLER n'est pas nul : c'est ainsi qu'on met en avant une part.
%
%   PIE(X,DECOLLER,ETIQUETTES) nomme les secteurs. Sans étiquettes, ce
%   sont les pourcentages qui sont écrits.
%
%   H = PIE(...) rend les poignées des secteurs et des textes.
%
%   Le premier secteur commence en haut et les suivants tournent dans le
%   sens des aiguilles d'une montre, comme dans MATLAB.
%
%   Un diagramme circulaire se lit mal dès qu'il compte plus de cinq ou
%   six parts : l'œil compare les angles beaucoup moins bien que les
%   longueurs. Un BAR trié, ou un PARETO, dit souvent la même chose plus
%   clairement.
%
%   Exemples :
%      pie([3 1 1]);
%      pie([30 20 50], [0 0 1], {'nord', 'sud', 'est'});
%
%   Voir aussi PIE3, BAR, PARETO, FILL, LEGEND.
    x = double(x(:));
    x = x(~isnan(x));
    if any(x < 0)
        error('MATLAB:pie:NegativeData', 'PIE needs nonnegative values.');
    end
    total = sum(x);
    if total <= 1
        fractions = x;             % deja des fractions : le disque reste ouvert
    else
        fractions = x / total;
    end
    n = numel(fractions);
    if nargin < 2 || isempty(decoller)
        decoller = zeros(n, 1);
    end
    decoller = decoller(:);
    if nargin < 3
        etiquettes = {};
    end

    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    debut = pi / 2;                % le premier secteur part du haut
    for k = 1:n
        angle = 2 * pi * fractions(k);
        fin = debut - angle;       % sens des aiguilles d'une montre
        t = linspace(debut, fin, max(3, ceil(abs(angle) * 60 / pi)));
        milieu = (debut + fin) / 2;
        if k <= numel(decoller) && decoller(k) ~= 0
            centreX = 0.12 * cos(milieu);
            centreY = 0.12 * sin(milieu);
        else
            centreX = 0;
            centreY = 0;
        end
        H(end + 1) = fill([centreX, centreX + cos(t), centreX], ...
                          [centreY, centreY + sin(t), centreY], ...
                          'FaceColor', matlibre_couleur_secteur(k));  %#ok<AGROW>
        % L'etiquette, posee un peu au-dela du bord.
        if isempty(etiquettes)
            texte = sprintf('%.0f%%', 100 * fractions(k));
        elseif k <= numel(etiquettes)
            texte = char(etiquettes{k});
        else
            texte = '';
        end
        if ~isempty(texte) && fractions(k) > 0
            H(end + 1) = text(centreX + 1.15 * cos(milieu), ...
                              centreY + 1.15 * sin(milieu), texte, ...
                              'HorizontalAlignment', 'center');       %#ok<AGROW>
        end
        debut = fin;
    end
    if ~aEffacer
        hold('off');
    end
    xlim([-1.5 1.5]);
    ylim([-1.4 1.4]);
    axis('equal');
    % Un camembert n'a pas d'axes gradues : ils n'ont rien a dire ici.
    axis('off');
    if nargout == 0
        clear H;
    end
end
