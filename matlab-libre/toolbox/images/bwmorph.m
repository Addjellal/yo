function sortie = bwmorph(bw, operation, n)
%BWMORPH Opérations morphologiques sur une image binaire.
%   BW2 = BWMORPH(BW,OPERATION) applique une fois l'opération nommée ;
%   BWMORPH(BW,OPERATION,N) la répète N fois, ou jusqu'à stabilité si N
%   vaut Inf.
%
%   Opérations reconnues : 'clean' (retire les pixels isolés), 'fill'
%   (bouche les trous d'un pixel), 'bridge' (relie deux pixels séparés
%   par un seul), 'remove' (ne garde que le bord), 'majority' (garde le
%   pixel si cinq voisins sur neuf sont allumés), 'erode', 'dilate',
%   'open', 'close', 'diag' (comble les liaisons diagonales),
%   'endpoints', 'branchpoints', 'thin', 'skel', 'spur', 'thicken',
%   'hbreak', 'tophat', 'bothat'.
%
%   Exemple :
%      bw = false(5); bw(3,3) = true;
%      bwmorph(bw, 'clean')   % le pixel isolé disparaît
    if nargin < 3 || isempty(n), n = 1; end
    bw = logical(bw);
    operation = lower(char(operation));
    sortie = bw;
    tour = 0;
    while tour < n
        tour = tour + 1;
        avant = sortie;
        sortie = unTour(sortie, operation);
        if isequal(sortie, avant)
            break
        end
    end
end

function bw = unTour(bw, operation)
    voisins = compterVoisins(bw);
    switch operation
        case 'clean'
            bw = bw & voisins > 0;
        case 'fill'
            bw = bw | (~bw & voisins == 8);
        case 'bridge'
            bw = bw | (~bw & pontPossible(bw));
        case 'remove'
            interieur = bw & compterVoisins4(bw) == 4;
            bw = bw & ~interieur;
        case 'majority'
            bw = (voisins + bw) >= 5;
        case 'erode'
            bw = logical(imerode(bw, ones(3)));
        case 'dilate'
            bw = logical(imdilate(bw, ones(3)));
        case 'open'
            bw = logical(imopen(bw, ones(3)));
        case 'close'
            bw = logical(imclose(bw, ones(3)));
        case 'diag'
            bw = combleDiagonales(bw);
        case 'endpoints'
            bw = bw & voisins == 1;
        case 'branchpoints'
            % Compter les voisins ne suffit pas : sur une croix, les
            % pixels voisins du centre en ont quatre eux aussi. Ce qui
            % distingue un embranchement, c'est le nombre de branches
            % distinctes autour du pixel, soit le nombre de passages de
            % zéro à un en tournant.
            bw = bw & nombreBranches(bw) >= 3;
        case {'thin', 'skel'}
            bw = amincirZhangSuen(bw);
        case 'spur'
            bw = bw & ~(bw & voisins == 1);
        case 'thicken'
            bw = ~amincirZhangSuen(~bw);
        case 'hbreak'
            bw = casserH(bw);
        case 'tophat'
            bw = bw & ~logical(imopen(bw, ones(3)));
        case 'bothat'
            bw = logical(imclose(bw, ones(3))) & ~bw;
        otherwise
            error('images:bwmorph:UnknownOperation', ...
                  'Opération inconnue : %s.', operation);
    end
end

function c = compterVoisins(bw)
%COMPTERVOISINS Nombre de voisins allumés parmi les huit.
    c = zeros(size(bw));
    for di = -1:1
        for dj = -1:1
            if di == 0 && dj == 0
                continue
            end
            c = c + decaler(bw, di, dj);
        end
    end
end

function c = compterVoisins4(bw)
    c = decaler(bw, -1, 0) + decaler(bw, 1, 0) + decaler(bw, 0, -1) + decaler(bw, 0, 1);
end

function y = decaler(bw, di, dj)
%DECALER Translate l'image, en complétant par des zéros.
    [h, l] = size(bw);
    y = zeros(h, l);
    lignesSource = max(1, 1 - di):min(h, h - di);
    colonnesSource = max(1, 1 - dj):min(l, l - dj);
    y(lignesSource + di, colonnesSource + dj) = double(bw(lignesSource, colonnesSource));
end

function m = pontPossible(bw)
%PONTPOSSIBLE Pixels éteints qui séparent deux voisins opposés allumés.
    m = (decaler(bw, -1, 0) & decaler(bw, 1, 0)) | ...
        (decaler(bw, 0, -1) & decaler(bw, 0, 1)) | ...
        (decaler(bw, -1, -1) & decaler(bw, 1, 1)) | ...
        (decaler(bw, -1, 1) & decaler(bw, 1, -1));
end

function bw = combleDiagonales(bw)
%COMBLEDIAGONALES Ajoute le pixel qui rend une liaison diagonale épaisse.
    ajout = (decaler(bw, -1, 0) & decaler(bw, 0, -1) & ~decaler(bw, -1, -1)) | ...
            (decaler(bw, -1, 0) & decaler(bw, 0, 1) & ~decaler(bw, -1, 1)) | ...
            (decaler(bw, 1, 0) & decaler(bw, 0, -1) & ~decaler(bw, 1, -1)) | ...
            (decaler(bw, 1, 0) & decaler(bw, 0, 1) & ~decaler(bw, 1, 1));
    bw = bw | (ajout & ~bw);
end

function bw = casserH(bw)
%CASSERH Retire le pixel central d'un motif en H.
    haut = decaler(bw, -1, -1) & decaler(bw, -1, 0) & decaler(bw, -1, 1);
    bas = decaler(bw, 1, -1) & decaler(bw, 1, 0) & decaler(bw, 1, 1);
    cotes = ~decaler(bw, 0, -1) & ~decaler(bw, 0, 1);
    bw = bw & ~(bw & haut & bas & cotes);
end

function bw = amincirZhangSuen(bw)
%AMINCIRZHANGSUEN Une passe de l'amincissement de Zhang et Suen.
%   Les deux demi-passes retirent les pixels de bord qui ne rompent pas
%   la connexité : le squelette garde la topologie de l'objet.
    for demi = 0:1
        p2 = decaler(bw, -1, 0);
        p3 = decaler(bw, -1, 1);
        p4 = decaler(bw, 0, 1);
        p5 = decaler(bw, 1, 1);
        p6 = decaler(bw, 1, 0);
        p7 = decaler(bw, 1, -1);
        p8 = decaler(bw, 0, -1);
        p9 = decaler(bw, -1, -1);
        B = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
        A = transitions(p2, p3, p4, p5, p6, p7, p8, p9);
        if demi == 0
            condition3 = (p2 .* p4 .* p6) == 0;
            condition4 = (p4 .* p6 .* p8) == 0;
        else
            condition3 = (p2 .* p4 .* p8) == 0;
            condition4 = (p2 .* p6 .* p8) == 0;
        end
        aRetirer = bw & B >= 2 & B <= 6 & A == 1 & condition3 & condition4;
        bw = bw & ~aRetirer;
    end
end

function n = nombreBranches(bw)
%NOMBREBRANCHES Passages de zéro à un autour de chaque pixel.
    n = transitions(decaler(bw, -1, 0), decaler(bw, -1, 1), decaler(bw, 0, 1), ...
                    decaler(bw, 1, 1), decaler(bw, 1, 0), decaler(bw, 1, -1), ...
                    decaler(bw, 0, -1), decaler(bw, -1, -1));
end

function A = transitions(p2, p3, p4, p5, p6, p7, p8, p9)
%TRANSITIONS Nombre de passages 0 -> 1 en tournant autour du pixel.
    A = (p2 == 0 & p3 == 1) + (p3 == 0 & p4 == 1) + (p4 == 0 & p5 == 1) + ...
        (p5 == 0 & p6 == 1) + (p6 == 0 & p7 == 1) + (p7 == 0 & p8 == 1) + ...
        (p8 == 0 & p9 == 1) + (p9 == 0 & p2 == 1);
end
