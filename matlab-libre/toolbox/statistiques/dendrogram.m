function [H, T, ordre] = dendrogram(Z, p, varargin)
%DENDROGRAM Dessine l'arbre de regroupement.
%   DENDROGRAM(Z) trace l'arbre que rend LINKAGE : chaque fusion est un
%   U dont les deux montants partent des groupes réunis et dont la
%   traverse est à la hauteur de la fusion. Les feuilles sont rangées de
%   façon qu'aucun U n'en croise un autre.
%
%   DENDROGRAM(Z,P) ne montre que P feuilles au plus : les groupes du bas
%   de l'arbre sont réunis en feuilles collectives, dont l'étiquette
%   porte l'effectif entre parenthèses. P = 0 montre toutes les
%   observations. Le défaut est 30, comme dans MATLAB.
%
%   H = DENDROGRAM(...) rend les poignées des traits.
%   [H,T] = DENDROGRAM(...) rend aussi, pour chaque observation, le
%   numéro de la feuille où elle a été rangée.
%   [H,T,OUTPERM] = DENDROGRAM(...) rend l'ordre des feuilles, de gauche
%   à droite.
%
%   DENDROGRAM(...,'Orientation',O) tourne l'arbre : 'top' (défaut),
%   'bottom', 'left' ou 'right'.
%   DENDROGRAM(...,'ColorThreshold',C) colorie en couleurs distinctes les
%   sous-arbres qui se referment sous la hauteur C.
%   DENDROGRAM(...,'Labels',L) remplace les numéros des feuilles par les
%   noms du tableau de cellules L.
%
%   Exemples :
%      X = [1 1; 1.2 1; 5 5; 5.1 5.2; 5 5.3];
%      Z = linkage(X, 'average');
%      dendrogram(Z);
%      dendrogram(Z, 'ColorThreshold', 1);   % les deux grappes colorees
%
%   Voir aussi LINKAGE, CLUSTER, CLUSTERDATA, COPHENET, PDIST.
    if nargin < 2 || isempty(p) || ischar(p) || isstring(p)
        if nargin >= 2 && (ischar(p) || isstring(p))
            varargin = [{p}, varargin];
        end
        p = 30;
    end
    orientation = 'top';
    seuilCouleur = Inf;
    etiquettes = {};
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'orientation'
                orientation = lower(char(varargin{k + 1}));
            case 'colorthreshold'
                seuilCouleur = varargin{k + 1};
                if ischar(seuilCouleur) || isstring(seuilCouleur)
                    % 'default' : les trois quarts de la hauteur totale
                    seuilCouleur = 0.7 * max(Z(:, 3));
                end
            case 'labels'
                etiquettes = varargin{k + 1};
            case 'reorder'
                % accepté et sans effet : MatLibre garde l'ordre naturel
            otherwise
                error('stats:dendrogram:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end

    n = size(Z, 1) + 1;
    if p <= 0 || p >= n
        garde = n;
    else
        garde = p;
    end

    % Les feuilles à montrer : on ne redéfait que les GARDE-1 dernières
    % fusions, les autres deviennent des feuilles collectives.
    T = cluster(Z, 'maxclust', garde);
    [Zr, feuilleDe] = matlibre_arbre_reduit(Z, T, garde);

    m = size(Zr, 1);
    nf = m + 1;
    % Position horizontale des feuilles : l'ordre d'un parcours en
    % profondeur, qui garantit qu'aucun U n'en croise un autre.
    ordre = matlibre_ordre_feuilles(Zr, nf);
    position = zeros(nf + m, 1);
    for i = 1:nf
        position(ordre(i)) = i;
    end

    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = zeros(m, 1);
    couleurs = {'b', 'r', 'g', 'm', 'c', [0.85 0.55 0], [0.5 0 0.7]};
    couleurDe = zeros(nf + m, 1);   % 0 : pas encore attribuée
    suivante = 0;
    for f = 1:m
        a = Zr(f, 1);
        b = Zr(f, 2);
        h = Zr(f, 3);
        xa = position(a);
        xb = position(b);
        position(nf + f) = (xa + xb) / 2;

        % Couleur : le premier sous-arbre entièrement sous le seuil en
        % reçoit une, et la transmet ; au-dessus du seuil, tout est noir.
        if h <= seuilCouleur
            c = couleurDe(a);
            if c == 0
                c = couleurDe(b);
            end
            if c == 0
                suivante = suivante + 1;
                c = suivante;
            end
            couleurDe(nf + f) = c;
            trait = couleurs{mod(c - 1, numel(couleurs)) + 1};
        else
            couleurDe(nf + f) = 0;
            trait = 'k';
        end

        ha = hauteurDe(Zr, a, nf);
        hb = hauteurDe(Zr, b, nf);
        x = [xa, xa, xb, xb];
        y = [ha, h, h, hb];
        if strcmp(orientation, 'left') || strcmp(orientation, 'right')
            H(f) = plot(y, x, 'Color', trait);
        else
            H(f) = plot(x, y, 'Color', trait);
        end
    end
    if ~aEffacer
        hold('off');
    end

    % Les étiquettes : le numéro de la feuille, son effectif si elle en
    % rassemble plusieurs, ou le nom fourni.
    noms = cell(nf, 1);
    for i = 1:nf
        combien = sum(feuilleDe == i);
        if ~isempty(etiquettes) && combien == 1
            j = find(feuilleDe == i, 1);
            noms{i} = char(etiquettes{j});
        elseif combien == 1
            noms{i} = num2str(find(feuilleDe == i, 1));
        else
            noms{i} = sprintf('(%d)', combien);
        end
    end
    rangees = cell(nf, 1);
    for i = 1:nf
        rangees{i} = noms{ordre(i)};
    end
    if strcmp(orientation, 'left') || strcmp(orientation, 'right')
        yticks(1:nf);
        yticklabels(rangees);
        xlim([0, max(Zr(:, 3)) * 1.05 + eps]);
        ylim([0.5, nf + 0.5]);
    else
        xticks(1:nf);
        xticklabels(rangees);
        xlim([0.5, nf + 0.5]);
        ylim([0, max(Zr(:, 3)) * 1.05 + eps]);
    end
    T = feuilleDe;
    if nargout == 0
        clear H;
    end
end

function h = hauteurDe(Z, noeud, nf)
%HAUTEURDE La hauteur d'un nœud : 0 pour une feuille.
    if noeud <= nf
        h = 0;
    else
        h = Z(noeud - nf, 3);
    end
end
