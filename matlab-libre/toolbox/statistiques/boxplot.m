function H = boxplot(y, groupe, varargin)
%BOXPLOT Boîtes à moustaches.
%   BOXPLOT(Y) dessine une boîte à moustaches par colonne de Y. Pour un
%   vecteur, une seule boîte.
%
%   BOXPLOT(Y,GROUPE) dessine une boîte par groupe, GROUPE prenant l'une
%   des formes qu'accepte GRP2IDX — des nombres, des noms, un tableau de
%   cellules.
%
%   Chaque boîte se lit ainsi :
%      la boîte va du premier au troisième quartile ;
%      le trait à l'intérieur est la médiane ;
%      les moustaches vont jusqu'à l'observation la plus éloignée qui
%      reste à moins de 1,5 écart interquartile de la boîte ;
%      les points au-delà sont marqués d'une croix : ce sont les valeurs
%      qu'on qualifie d'aberrantes, sans que cela préjuge de rien.
%
%   BOXPLOT(...,'Labels',L) nomme les boîtes avec les chaînes de L.
%   BOXPLOT(...,'Whisker',W) change le facteur 1,5 en W. W = 0 fait
%   partir les moustaches jusqu'aux extrêmes, sans aucune valeur
%   aberrante.
%   BOXPLOT(...,'Orientation','horizontal') couche les boîtes.
%   BOXPLOT(...,'Notch','on') creuse la boîte autour de la médiane, d'une
%   profondeur qui donne un intervalle de confiance approché : deux
%   encoches qui ne se recouvrent pas signalent des médianes différentes.
%
%   Exemples :
%      boxplot(randn(100, 3));
%
%      y = [1 2 3 3 4 20 10 11 12 13];
%      g = [1 1 1 1 1 1 2 2 2 2];
%      boxplot(y, g);              % la valeur 20 sort en croix
%
%      boxplot(randn(50, 2), 'Labels', {'avant', 'apres'});
%
%   Voir aussi HISTOGRAM, PRCTILE, IQR, MEDIAN, GRPSTATS, ANOVA1.
    facteurMoustache = 1.5;
    etiquettes = {};
    orientation = 'vertical';
    encoche = false;
    if nargin >= 2 && (ischar(groupe) || isstring(groupe))
        varargin = [{groupe}, varargin];
        groupe = [];
    elseif nargin < 2
        groupe = [];
    end
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'labels'
                etiquettes = varargin{k + 1};
                if ischar(etiquettes)
                    etiquettes = {etiquettes};
                end
            case 'whisker'
                facteurMoustache = varargin{k + 1};
            case 'orientation'
                orientation = lower(char(varargin{k + 1}));
            case 'notch'
                encoche = strcmpi(char(varargin{k + 1}), 'on');
            case {'symbol', 'colors', 'widths', 'positions'}
                % acceptés et sans effet
            otherwise
                error('stats:boxplot:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end

    % Les échantillons : une cellule par boîte.
    if isempty(groupe)
        if isvector(y)
            echantillons = {y(:)};
            noms = {'1'};
        else
            echantillons = cell(size(y, 2), 1);
            noms = cell(size(y, 2), 1);
            for j = 1:size(y, 2)
                echantillons{j} = y(:, j);
                noms{j} = num2str(j);
            end
        end
    else
        [indices, noms] = grp2idx(groupe);
        y = y(:);
        echantillons = cell(numel(noms), 1);
        for g = 1:numel(noms)
            echantillons{g} = y(indices == g);
        end
    end
    if ~isempty(etiquettes)
        noms = etiquettes(:);
    end
    nb = numel(echantillons);

    horizontal = strncmp(orientation, 'horiz', 5);
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    largeur = 0.35;
    H = [];
    for j = 1:nb
        v = echantillons{j};
        v = v(~isnan(v));
        if isempty(v)
            continue;
        end
        q1 = prctile(v, 25);
        q2 = median(v);
        q3 = prctile(v, 75);
        interquartile = q3 - q1;
        if facteurMoustache > 0
            basse = min(v(v >= q1 - facteurMoustache * interquartile));
            haute = max(v(v <= q3 + facteurMoustache * interquartile));
        else
            basse = min(v);
            haute = max(v);
        end
        if isempty(basse)
            basse = q1;
        end
        if isempty(haute)
            haute = q3;
        end
        aberrantes = v(v < basse | v > haute);

        gauche = j - largeur;
        droite = j + largeur;
        if encoche
            % L'encoche de McGill : la médiane plus ou moins
            % 1,57 * IQR / racine(n).
            demi = 1.57 * interquartile / sqrt(numel(v));
            bas = max(q1, q2 - demi);
            haut = min(q3, q2 + demi);
            milieu = j;
            bx = [gauche, gauche, milieu - largeur / 3, gauche, gauche, ...
                  droite, droite, milieu + largeur / 3, droite, droite, gauche];
            by = [q1, bas, q2, haut, q3, q3, haut, q2, bas, q1, q1];
        else
            bx = [gauche, droite, droite, gauche, gauche];
            by = [q1, q1, q3, q3, q1];
        end
        tracerForme(bx, by, horizontal, '#0072BD', 1);
        tracerForme([gauche, droite], [q2, q2], horizontal, '#D95319', 2);
        tracerForme([j, j], [q3, haute], horizontal, '#000000', 1);
        tracerForme([j, j], [basse, q1], horizontal, '#000000', 1);
        tracerForme([j - largeur / 2, j + largeur / 2], [haute, haute], ...
                    horizontal, '#000000', 1);
        tracerForme([j - largeur / 2, j + largeur / 2], [basse, basse], ...
                    horizontal, '#000000', 1);
        for i = 1:numel(aberrantes)
            if horizontal
                plot(aberrantes(i), j, '+r');
            else
                plot(j, aberrantes(i), '+r');
            end
        end
    end
    if ~aEffacer
        hold('off');
    end
    if horizontal
        yticks(1:nb);
        yticklabels(noms);
        ylim([0.5, nb + 0.5]);
    else
        xticks(1:nb);
        xticklabels(noms);
        xlim([0.5, nb + 0.5]);
    end
    if nargout == 0
        clear H;
    end
end

function tracerForme(x, y, horizontal, couleur, epaisseur)
%TRACERFORME Un segment ou un contour, couché ou debout.
    if horizontal
        line(y, x, 'Color', couleur, 'LineWidth', epaisseur);
    else
        line(x, y, 'Color', couleur, 'LineWidth', epaisseur);
    end
end
