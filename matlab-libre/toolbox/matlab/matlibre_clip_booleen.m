function contours = matlibre_clip_booleen(contoursP, contoursQ, operation)
%MATLIBRE_CLIP_BOOLEEN Réunion, intersection ou différence de polygones.
%   Les deux entrées sont des cellules de contours, chacun une matrice à
%   deux colonnes. L'opération vaut 'union', 'intersection' ou
%   'difference'.
%
%   L'algorithme est celui de Greiner et Hormann. On calcule d'abord
%   toutes les intersections des arêtes des deux polygones, et on les
%   insère dans les deux contours à leur place le long de l'arête. Chaque
%   intersection est alors marquée « entrante » ou « sortante » selon que
%   le sommet qui la précède est dedans ou dehors — c'est ce que veut
%   dire traverser une frontière. Il ne reste qu'à suivre : on part d'une
%   intersection, on avance le long d'un polygone jusqu'à la suivante, on
%   saute sur l'autre polygone, et l'on repart. Le sens dans lequel on
%   avance dépend de l'opération, et c'est tout ce qui les distingue.
%
%   Les cas dégénérés — un sommet posé exactement sur une arête de
%   l'autre, deux arêtes confondues — font échouer la marche, parce
%   qu'il n'y a alors ni entrée ni sortie franche. On les défait en
%   déplaçant l'un des deux polygones d'un cheveu : un milliardième de
%   son étendue, dans une direction qui ne retombe sur rien. Le résultat
%   est alors juste à ce déplacement près, ce qui est bien au-dessous de
%   ce qu'on peut lire, et c'est le prix à payer pour répondre là où
%   l'algorithme ne sait pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      a = {[0 0; 2 0; 2 2; 0 2]};
%      b = {[1 1; 3 1; 3 3; 1 3]};
%      c = matlibre_clip_booleen(a, b, 'intersection');
%      abs(polyarea(c{1}(:,1), c{1}(:,2)) - 1) < 1e-9
%
%   Voir aussi POLYSHAPE, UNION, INTERSECT, SUBTRACT.
    [contours, reussi] = clipUneFois(contoursP, contoursQ, operation);
    if reussi
        return
    end
    % Il reste des coincidences exactes : un sommet pose sur une arete de
    % l'autre, ou deux aretes confondues. Tourner ne les defait pas — les
    % deux polygones tournent ensemble —, mais deplacer l'un d'un cheveu
    % si. Le deplacement est pris bien plus petit que la plus petite
    % arete, et dans plusieurs directions pour qu'aucune ne retombe sur
    % une autre coincidence.
    echelle = etendue(contoursP, contoursQ);
    directions = [1 0; 0 1; 1 1; 1 -1; -1 2; 2 -1] / sqrt(2);
    for k = 1:size(directions, 1)
        for amplitude = [1e-11 1e-9 1e-7]
            Q = deplacer(contoursQ, directions(k, :) * amplitude * echelle);
            [contours, reussi] = clipUneFois(contoursP, Q, operation);
            if reussi
                return
            end
        end
    end
    error('MATLAB:polyshape:degenere', ...
          'Les deux polygones sont trop imbriqués pour être combinés.');
end

function e = etendue(P, Q)
% La plus grande dimension des deux polygones reunis : elle fixe l'ordre
% de grandeur du deplacement.
    tous = [P, Q];
    bas = [inf inf]; haut = [-inf -inf];
    for k = 1:numel(tous)
        bas = min(bas, min(tous{k}, [], 1));
        haut = max(haut, max(tous{k}, [], 1));
    end
    e = max(max(haut - bas), 1);
end

function c = deplacer(contours, vecteur)
    c = cell(size(contours));
    for k = 1:numel(contours)
        c{k} = contours{k} + vecteur;
    end
end

function [sortie, reussi] = clipUneFois(P, Q, operation)
% Une passe de l'algorithme, sur des contours supposes en position
% generale. Rend « reussi » faux des qu'une degenerescence apparait.
    sortie = {};
    reussi = false;
    if numel(P) ~= 1 || numel(Q) ~= 1
        % Plusieurs contours : on traite paire par paire et l'on reunit.
        resultat = {};
        for i = 1:numel(P)
            for j = 1:numel(Q)
                [part, ok] = clipUneFois(P(i), Q(j), operation);
                if ~ok
                    return
                end
                resultat = [resultat, part];   %#ok<AGROW>
            end
        end
        sortie = resultat;
        reussi = true;
        return
    end
    A = P{1};
    B = Q{1};
    [listeA, listeB, ok] = croiser(A, B);
    if ~ok
        return
    end
    if ~any([listeA.intersection])
        % Aucune traversee : l'un contient l'autre, ou ils sont disjoints.
        sortie = sansCroisement(A, B, operation);
        reussi = true;
        return
    end
    [listeA, listeB] = marquerEntrees(listeA, listeB, A, B, operation);
    sortie = suivre(listeA, listeB);
    reussi = true;
end

function [listeA, listeB, ok] = croiser(A, B)
% Insere dans chaque contour les points d'intersection avec l'autre, a
% leur place le long de l'arete. Chaque intersection porte l'indice de sa
% jumelle dans l'autre liste : c'est par la qu'on saute d'un polygone a
% l'autre.
    ok = true;
    listeA = enListe(A);
    listeB = enListe(B);
    nA = size(A, 1);
    nB = size(B, 1);
    croisements = {};
    for i = 1:nA
        a1 = A(i, :);
        a2 = A(mod(i, nA) + 1, :);
        for j = 1:nB
            b1 = B(j, :);
            b2 = B(mod(j, nB) + 1, :);
            [s, t, point] = intersecter(a1, a2, b1, b2);
            if isempty(s)
                continue
            end
            % Une intersection sur un sommet — s ou t a zero ou un —
            % rend la marche ambigue : on renonce, l'appelant tournera.
            if s < 1e-13 || s > 1 - 1e-13 || t < 1e-13 || t > 1 - 1e-13
                ok = false;
                return
            end
            croisements{end + 1} = struct('i', i, 's', s, 'j', j, 't', t, ...
                                          'point', point);   %#ok<AGROW>
        end
    end
    if isempty(croisements)
        return
    end
    % On insere en partant de la fin, pour que les indices deja calcules
    % restent valides.
    listeA = inserer(listeA, croisements, 'i', 's');
    listeB = inserer(listeB, croisements, 'j', 't');
    listeA = apparier(listeA, listeB);
    listeB = apparier(listeB, listeA);
end

function liste = enListe(C)
% Un contour devient une liste de sommets, chacun sachant s'il est une
% intersection et, si oui, ou est sa jumelle.
    n = size(C, 1);
    liste = struct('x', cell(1, n), 'y', cell(1, n), 'intersection', cell(1, n), ...
                   'jumelle', cell(1, n), 'entrant', cell(1, n), 'vu', cell(1, n), ...
                   'cle', cell(1, n));
    for k = 1:n
        liste(k).x = C(k, 1);
        liste(k).y = C(k, 2);
        liste(k).intersection = false;
        liste(k).jumelle = 0;
        liste(k).entrant = false;
        liste(k).vu = false;
        liste(k).cle = '';
    end
end

function liste = inserer(liste, croisements, champArete, champPosition)
% Insere les intersections dans la liste, chacune apres le sommet qui
% ouvre son arete, les plus lointaines d'abord.
    aretes = cellfun(@(c) c.(champArete), croisements);
    positions = cellfun(@(c) c.(champPosition), croisements);
    [~, ordre] = sortrows([aretes(:), positions(:)], [-1 -2]);
    for k = ordre(:)'
        c = croisements{k};
        nouveau = liste(1);
        nouveau.x = c.point(1);
        nouveau.y = c.point(2);
        nouveau.intersection = true;
        nouveau.jumelle = 0;
        nouveau.entrant = false;
        nouveau.vu = false;
        nouveau.cle = sprintf('%d:%.15g:%d:%.15g', c.i, c.s, c.j, c.t);
        apres = c.(champArete);
        liste = [liste(1:apres), nouveau, liste(apres+1:end)];
    end
end

function liste = apparier(liste, autre)
% Relie chaque intersection a sa jumelle, par la cle qui les identifie.
    clesAutre = {autre.cle};
    for k = 1:numel(liste)
        if ~liste(k).intersection
            continue
        end
        position = find(strcmp(clesAutre, liste(k).cle), 1);
        if ~isempty(position)
            liste(k).jumelle = position;
        end
    end
end

function [s, t, point] = intersecter(a1, a2, b1, b2)
% L'intersection de deux segments, par leurs parametres. Vide si les
% segments ne se coupent pas, ou s'ils sont paralleles.
    r = a2 - a1;
    v = b2 - b1;
    denominateur = r(1) * v(2) - r(2) * v(1);
    s = []; t = []; point = [];
    if abs(denominateur) < 1e-14
        return
    end
    d = b1 - a1;
    sCandidat = (d(1) * v(2) - d(2) * v(1)) / denominateur;
    tCandidat = (d(1) * r(2) - d(2) * r(1)) / denominateur;
    if sCandidat < 0 || sCandidat > 1 || tCandidat < 0 || tCandidat > 1
        return
    end
    s = sCandidat;
    t = tCandidat;
    point = a1 + s * r;
end

function [listeA, listeB] = marquerEntrees(listeA, listeB, A, B, operation)
% Chaque intersection est entrante ou sortante selon que le sommet qui la
% precede est dehors ou dedans. C'est ce marquage qui decide du sens dans
% lequel on suivra chaque contour, et c'est la seule chose que
% l'operation change.
    dedansA = inpolygon(listeA(1).x, listeA(1).y, B(:, 1), B(:, 2));
    dedansB = inpolygon(listeB(1).x, listeB(1).y, A(:, 1), A(:, 2));
    % Pour l'intersection, on garde ce qui est dedans ; pour l'union, ce
    % qui est dehors ; pour la difference, dehors de B mais dedans de A.
    switch operation
        case 'intersection'
            sensA = true;  sensB = true;
        case 'union'
            sensA = false; sensB = false;
        otherwise   % difference : A moins B
            sensA = false; sensB = true;
    end
    listeA = alterner(listeA, xor(dedansA, sensA));
    listeB = alterner(listeB, xor(dedansB, sensB));
end

function liste = alterner(liste, etat)
% Les intersections alternent entree et sortie le long d'un contour : on
% part de l'etat du premier sommet et l'on bascule a chaque traversee.
    for k = 1:numel(liste)
        if liste(k).intersection
            liste(k).entrant = etat;
            etat = ~etat;
        end
    end
end

function contours = suivre(listeA, listeB)
% La marche : depuis une intersection non visitee, on avance le long d'un
% contour — en avant si l'intersection est entrante, en arriere sinon —
% jusqu'a la suivante, puis on saute sur l'autre contour. On s'arrete en
% revenant au depart.
    contours = {};
    for depart = 1:numel(listeA)
        if ~listeA(depart).intersection || listeA(depart).vu
            continue
        end
        points = zeros(0, 2);
        surA = true;
        position = depart;
        avant = listeA(depart).entrant;
        pas = 0;
        limite = 4 * (numel(listeA) + numel(listeB)) + 8;
        while pas < limite
            pas = pas + 1;
            if surA
                listeA(position).vu = true;
                points(end + 1, :) = [listeA(position).x, listeA(position).y];   %#ok<AGROW>
                position = avancer(position, numel(listeA), avant);
                while ~listeA(position).intersection
                    points(end + 1, :) = [listeA(position).x, listeA(position).y];   %#ok<AGROW>
                    position = avancer(position, numel(listeA), avant);
                end
                listeA(position).vu = true;
                jumelle = listeA(position).jumelle;
                if jumelle == 0
                    break
                end
                avant = listeB(jumelle).entrant;
                position = jumelle;
                surA = false;
            else
                listeB(position).vu = true;
                points(end + 1, :) = [listeB(position).x, listeB(position).y];   %#ok<AGROW>
                position = avancer(position, numel(listeB), avant);
                while ~listeB(position).intersection
                    points(end + 1, :) = [listeB(position).x, listeB(position).y];   %#ok<AGROW>
                    position = avancer(position, numel(listeB), avant);
                end
                listeB(position).vu = true;
                jumelle = listeB(position).jumelle;
                if jumelle == 0
                    break
                end
                avant = listeA(jumelle).entrant;
                position = jumelle;
                surA = true;
                if position == depart
                    break
                end
            end
        end
        if size(points, 1) >= 3
            contours{end + 1} = points;   %#ok<AGROW>
        end
    end
end

function k = avancer(k, n, avant)
    if avant
        k = mod(k, n) + 1;
    else
        k = mod(k - 2, n) + 1;
    end
end

function contours = sansCroisement(A, B, operation)
% Aucune arete ne se coupe : l'un contient l'autre, ou ils sont disjoints.
% Il n'y a alors rien a suivre, seulement a choisir.
    aDansB = all(inpolygon(A(:, 1), A(:, 2), B(:, 1), B(:, 2)));
    bDansA = all(inpolygon(B(:, 1), B(:, 2), A(:, 1), A(:, 2)));
    switch operation
        case 'intersection'
            if aDansB
                contours = {A};
            elseif bDansA
                contours = {B};
            else
                contours = {};
            end
        case 'union'
            if aDansB
                contours = {B};
            elseif bDansA
                contours = {A};
            else
                contours = {A, B};
            end
        otherwise   % difference
            if aDansB
                contours = {};
            elseif bDansA
                % Un trou : le contour interieur en sens inverse.
                contours = {A, B(end:-1:1, :)};
            else
                contours = {A};
            end
    end
end
