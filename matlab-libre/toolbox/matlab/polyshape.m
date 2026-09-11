classdef polyshape
%POLYSHAPE Région du plan délimitée par des polygones.
%   PG = POLYSHAPE(X,Y) construit la région bordée par le polygone de
%   sommets (X,Y). PG = POLYSHAPE(P) où P a deux colonnes fait de même.
%   Plusieurs contours se donnent séparés par des NaN, ou en cellules :
%   POLYSHAPE({X1,X2},{Y1,Y2}).
%
%   Un contour parcouru dans le sens direct est plein ; un contour
%   parcouru dans l'autre sens et contenu dans un plein est un trou.
%   C'est la convention de MATLAB, et elle suffit à décrire une région
%   percée sans rien ajouter à la structure.
%
%   Ce qu'on lui demande : AREA, PERIMETER, CENTROID, BOUNDINGBOX,
%   ISINTERIOR, BOUNDARY, NUMSIDES, NUMBOUNDARIES, NUMREGIONS, HOLES,
%   ISHOLE, REGIONS, TRANSLATE, SCALE, ROTATE, ADDBOUNDARY, RMBOUNDARY,
%   OVERLAPS, CONVHULL, PLOT, et les opérations booléennes UNION,
%   INTERSECT, SUBTRACT et XOR.
%
%   Ce qui n'est pas fait : la simplification automatique d'un contour
%   qui se recoupe lui-même. MATLAB la fait à la construction ; ici le
%   contour est pris tel quel, et une aire calculée sur un contour croisé
%   compte les régions selon leur enlacement.
%
%   Quand deux régions se touchent exactement — une arête commune, un
%   sommet posé sur une arête —, l'algorithme de découpage n'a ni entrée
%   ni sortie franche à suivre. Le cas est résolu en déplaçant l'une des
%   deux d'un cheveu : cent milliardièmes de son étendue. Le résultat est
%   alors juste à ce déplacement près, soit une dizaine de chiffres
%   significatifs, et non à la précision machine comme dans les autres
%   cas.
%
%   Exemple :
%      carre = polyshape([0 2 2 0], [0 0 2 2]);
%      area(carre)                     % 4
%      autre = polyshape([1 3 3 1], [1 1 3 3]);
%      area(intersect(carre, autre))   % 1 : le carre commun
%      area(union(carre, autre))       % 7 : 4 + 4 - 1
%
%   Voir aussi POLYAREA, INPOLYGON, CONVHULL, BOUNDARY, ALPHASHAPE.
    properties
        Vertices = zeros(0, 2)
    end

    methods
        function pg = polyshape(varargin)
            if isempty(varargin)
                return
            end
            contours = matlibre_poly_entree(varargin);
            pg.Vertices = matlibre_poly_assembler(contours);
        end

        function c = matlibre_contours(pg)
        %MATLIBRE_CONTOURS Les contours, un par élément de cellule.
            c = matlibre_poly_separer(pg.Vertices);
        end

        function a = area(pg, indice)
        %AREA Aire de la région.
        %   Les contours pleins comptent en positif, les trous en
        %   négatif : c'est la formule du lacet, dont le signe suit le
        %   sens de parcours, qui le fait toute seule.
            contours = matlibre_poly_separer(pg.Vertices);
            if nargin > 1
                contours = contours(indice);
            end
            a = 0;
            for k = 1:numel(contours)
                a = a + matlibre_poly_aire_signee(contours{k});
            end
            a = abs(a);
        end

        function p = perimeter(pg, indice)
        %PERIMETER Longueur totale du bord, trous compris.
            contours = matlibre_poly_separer(pg.Vertices);
            if nargin > 1
                contours = contours(indice);
            end
            p = 0;
            for k = 1:numel(contours)
                c = contours{k};
                ecarts = c([2:end 1], :) - c;
                p = p + sum(sqrt(sum(ecarts .^ 2, 2)));
            end
        end

        function [x, y] = centroid(pg, indice)
        %CENTROID Centre de gravité de la région.
        %   Le barycentre de la surface, non celui des sommets : c'est
        %   l'intégrale de x sur la région divisée par son aire, que la
        %   formule du lacet donne aussi. Un trou y contribue en négatif,
        %   ce qui déplace le centre du bon côté.
            contours = matlibre_poly_separer(pg.Vertices);
            if nargin > 1
                contours = contours(indice);
            end
            aire = 0;
            somme = [0 0];
            for k = 1:numel(contours)
                [a, cx, cy] = matlibre_poly_moments(contours{k});
                aire = aire + a;
                somme = somme + a * [cx, cy];
            end
            if abs(aire) < eps
                resultat = [NaN NaN];
            else
                resultat = somme / aire;
            end
            if nargout <= 1
                x = resultat;
            else
                x = resultat(1);
                y = resultat(2);
            end
        end

        function b = boundingbox(pg)
        %BOUNDINGBOX Le rectangle qui enferme la région : [xmin xmax; ymin ymax].
            v = pg.Vertices(~isnan(pg.Vertices(:, 1)), :);
            if isempty(v)
                b = [NaN NaN; NaN NaN];
            else
                b = [min(v(:, 1)) max(v(:, 1)); min(v(:, 2)) max(v(:, 2))];
            end
        end

        function dedans = isinterior(pg, xq, yq)
        %ISINTERIOR Points intérieurs à la région.
        %   Un point est dedans s'il est dans un contour plein et dans
        %   aucun trou : c'est la définition d'une région percée.
            if nargin == 2
                Q = double(xq);
            else
                Q = [double(xq(:)), double(yq(:))];
            end
            contours = matlibre_poly_separer(pg.Vertices);
            dedans = false(size(Q, 1), 1);
            for k = 1:numel(contours)
                c = contours{k};
                dansCelui = inpolygon(Q(:, 1), Q(:, 2), c(:, 1), c(:, 2));
                if matlibre_poly_aire_signee(c) >= 0
                    dedans = dedans | dansCelui;
                else
                    dedans = dedans & ~dansCelui;
                end
            end
        end

        function [x, y] = boundary(pg, indice)
        %BOUNDARY Sommets d'un contour, ou de tous.
            contours = matlibre_poly_separer(pg.Vertices);
            if nargin > 1
                c = contours{indice};
            else
                c = pg.Vertices;
            end
            if nargout <= 1
                x = c;
            else
                x = c(:, 1);
                y = c(:, 2);
            end
        end

        function n = numsides(pg, indice)
        %NUMSIDES Nombre de côtés.
            contours = matlibre_poly_separer(pg.Vertices);
            if nargin > 1
                n = size(contours{indice}, 1);
            else
                n = 0;
                for k = 1:numel(contours)
                    n = n + size(contours{k}, 1);
                end
            end
        end

        function n = numboundaries(pg)
        %NUMBOUNDARIES Nombre de contours, trous compris.
            n = numel(matlibre_poly_separer(pg.Vertices));
        end

        function n = numregions(pg)
        %NUMREGIONS Nombre de morceaux pleins.
            contours = matlibre_poly_separer(pg.Vertices);
            n = 0;
            for k = 1:numel(contours)
                if matlibre_poly_aire_signee(contours{k}) >= 0
                    n = n + 1;
                end
            end
        end

        function t = ishole(pg, indice)
        %ISHOLE Vrai pour les contours qui sont des trous.
            contours = matlibre_poly_separer(pg.Vertices);
            t = false(numel(contours), 1);
            for k = 1:numel(contours)
                t(k) = matlibre_poly_aire_signee(contours{k}) < 0;
            end
            if nargin > 1
                t = t(indice);
            end
        end

        function h = holes(pg)
        %HOLES Les trous, rendus comme une région à part entière.
            contours = matlibre_poly_separer(pg.Vertices);
            garde = {};
            for k = 1:numel(contours)
                if matlibre_poly_aire_signee(contours{k}) < 0
                    garde{end + 1} = contours{k}(end:-1:1, :);   %#ok<AGROW>
                end
            end
            h = polyshape();
            h.Vertices = matlibre_poly_assembler(garde);
        end

        function r = regions(pg)
        %REGIONS Les morceaux pleins, un POLYSHAPE chacun.
        %   Chaque trou va au morceau qui le contient.
            contours = matlibre_poly_separer(pg.Vertices);
            pleins = {};
            trous = {};
            for k = 1:numel(contours)
                if matlibre_poly_aire_signee(contours{k}) >= 0
                    pleins{end + 1} = contours{k};   %#ok<AGROW>
                else
                    trous{end + 1} = contours{k};    %#ok<AGROW>
                end
            end
            r = polyshape.empty(0, 1);
            for k = 1:numel(pleins)
                morceau = {pleins{k}};
                for j = 1:numel(trous)
                    centre = mean(trous{j}, 1);
                    if inpolygon(centre(1), centre(2), pleins{k}(:, 1), pleins{k}(:, 2))
                        morceau{end + 1} = trous{j};   %#ok<AGROW>
                    end
                end
                un = polyshape();
                un.Vertices = matlibre_poly_assembler(morceau);
                r(k, 1) = un;
            end
        end

        function pg = translate(pg, deplacement, dy)
        %TRANSLATE Déplace la région.
            if nargin == 3
                deplacement = [deplacement, dy];
            end
            valides = ~isnan(pg.Vertices(:, 1));
            pg.Vertices(valides, :) = pg.Vertices(valides, :) + deplacement(:)';
        end

        function pg = scale(pg, facteur, centre)
        %SCALE Dilate la région autour d'un point, l'origine par défaut.
            if nargin < 3, centre = [0 0]; end
            if isscalar(facteur), facteur = [facteur facteur]; end
            valides = ~isnan(pg.Vertices(:, 1));
            pg.Vertices(valides, :) = (pg.Vertices(valides, :) - centre(:)') ...
                                      .* facteur(:)' + centre(:)';
        end

        function pg = rotate(pg, degres, centre)
        %ROTATE Tourne la région autour d'un point, l'origine par défaut.
            if nargin < 3, centre = [0 0]; end
            angle = degres * pi / 180;
            R = [cos(angle) -sin(angle); sin(angle) cos(angle)];
            valides = ~isnan(pg.Vertices(:, 1));
            centres = pg.Vertices(valides, :) - centre(:)';
            pg.Vertices(valides, :) = (R * centres')' + centre(:)';
        end

        function pg = addboundary(pg, varargin)
        %ADDBOUNDARY Ajoute un contour à la région.
            contours = matlibre_poly_separer(pg.Vertices);
            nouveaux = matlibre_poly_entree(varargin);
            pg.Vertices = matlibre_poly_assembler([contours, nouveaux]);
        end

        function pg = rmboundary(pg, indice)
        %RMBOUNDARY Retire un contour.
            contours = matlibre_poly_separer(pg.Vertices);
            contours(indice) = [];
            pg.Vertices = matlibre_poly_assembler(contours);
        end

        function r = union(pg, autre)
        %UNION Réunion de deux régions.
            r = matlibre_poly_booleen(pg, autre, 'union');
        end

        function r = intersect(pg, autre)
        %INTERSECT Partie commune à deux régions.
            r = matlibre_poly_booleen(pg, autre, 'intersection');
        end

        function r = subtract(pg, autre)
        %SUBTRACT Ce qui reste de la première après avoir ôté la seconde.
            r = matlibre_poly_booleen(pg, autre, 'difference');
        end

        function r = xor(pg, autre)
        %XOR Ce qui appartient à l'une ou à l'autre, mais pas aux deux.
            r = union(subtract(pg, autre), subtract(autre, pg));
        end

        function t = overlaps(pg, autre)
        %OVERLAPS Vrai si les deux régions ont une partie commune.
            t = area(intersect(pg, autre)) > 1e-12;
        end

        function r = convhull(pg)
        %CONVHULL Enveloppe convexe des sommets de la région.
            v = pg.Vertices(~isnan(pg.Vertices(:, 1)), :);
            k = matlibre_poly_enveloppe(v);
            r = polyshape(v(k(1:end-1), :));
        end

        function h = plot(pg, varargin)
        %PLOT Trace la région, remplie.
            contours = matlibre_poly_separer(pg.Vertices);
            tenu = ishold;
            h = [];
            for k = 1:numel(contours)
                c = contours{k};
                h = fill(c(:, 1), c(:, 2), [0.4 0.6 0.9], varargin{:});
                hold on
            end
            if ~tenu
                hold off
            end
            if nargout == 0
                clear h;
            end
        end
    end
end
