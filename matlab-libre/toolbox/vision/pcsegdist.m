function [etiquettes, nombre] = pcsegdist(entree, distanceMin, varargin)
%PCSEGDIST Sépare un nuage en groupes, par distance.
%   [L,N] = PCSEGDIST(P,D) donne à chaque point le numéro de son groupe :
%   deux points appartiennent au même groupe s'il existe une chaîne de
%   points consécutifs distants de moins de D.
%
%   C'est la segmentation la plus simple qui soit, et souvent la bonne :
%   dans une scène, les objets sont séparés par du vide.
%
%   PCSEGDIST(...,'NumClusterPoints',[MIN MAX]) écarte les groupes trop
%   petits ou trop gros, dont les points reçoivent l'étiquette zéro.
%
%   Exemple :
%      p = pointCloud([randn(200,3); randn(200,3) + 20]);
%      [l, n] = pcsegdist(p, 2);      % n = 2
%
%   Voir aussi PCFITPLANE, PCDENOISE, POINTCLOUD.
    bornes = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numclusterpoints', bornes = double(varargin{k+1});
            case 'parallel'   % le calcul est déjà séquentiel
            otherwise
                error('vision:pcsegdist:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    points = matlibre_nuage_points(entree);
    n = size(points, 1);
    etiquettes = zeros(n, 1);
    nombre = 0;
    carreMin = distanceMin ^ 2;
    normes = sum(points .^ 2, 2);
    for depart = 1:n
        if etiquettes(depart) ~= 0
            continue
        end
        nombre = nombre + 1;
        % Parcours en largeur : la pile contient les points dont on n'a
        % pas encore regardé le voisinage.
        pile = depart;
        etiquettes(depart) = nombre;
        while ~isempty(pile)
            courant = pile(end);
            pile(end) = [];
            carres = normes + normes(courant) - 2 * (points * points(courant, :).');
            proches = find(carres <= carreMin & etiquettes == 0);
            if ~isempty(proches)
                etiquettes(proches) = nombre;
                pile = [pile; proches];   %#ok<AGROW>
            end
        end
    end
    if ~isempty(bornes)
        tailles = zeros(nombre, 1);
        for k = 1:nombre
            tailles(k) = sum(etiquettes == k);
        end
        minimum = bornes(1);
        if numel(bornes) > 1
            maximum = bornes(2);
        else
            maximum = inf;
        end
        rejetes = find(tailles < minimum | tailles > maximum);
        etiquettes(ismember(etiquettes, rejetes)) = 0;
        % Renumérotation, pour que les étiquettes restent consécutives.
        restants = unique(etiquettes(etiquettes > 0));
        nouvelles = zeros(size(etiquettes));
        for k = 1:numel(restants)
            nouvelles(etiquettes == restants(k)) = k;
        end
        etiquettes = nouvelles;
        nombre = numel(restants);
    end
end
