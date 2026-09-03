function [centres, rayons, forces] = imfindcircles(I, plage, varargin)
%IMFINDCIRCLES Cherche des cercles par la transformée de Hough.
%   [CENTRES,RAYONS] = IMFINDCIRCLES(I,[RMIN RMAX]) cherche les cercles
%   dont le rayon est compris entre RMIN et RMAX. CENTRES a une ligne par
%   cercle, en [x y].
%
%   [CENTRES,RAYONS] = IMFINDCIRCLES(I,R) cherche les cercles de rayon R.
%   [CENTRES,RAYONS,FORCES] = IMFINDCIRCLES(...) rend la force de chaque
%   détection, entre 0 et 1.
%
%   Chaque point de contour vote pour les centres possibles — ceux qui
%   sont à la distance R de lui —, et un cercle apparaît là où les votes
%   se rassemblent.
%
%   IMFINDCIRCLES(...,'Sensitivity',S) abaisse le seuil de détection
%   quand S monte vers 1 (0,85 par défaut) ; 'EdgeThreshold',T règle le
%   seuil du gradient ; 'ObjectPolarity','dark' cherche des objets
%   sombres sur fond clair.
%
%   Exemple :
%      I = zeros(100, 100);
%      [X, Y] = meshgrid(1:100, 1:100);
%      I((X - 50) .^ 2 + (Y - 50) .^ 2 < 400) = 1;
%      [centres, rayons] = imfindcircles(I, [15 25]);
%
%   Voir aussi HOUGH, HOUGHPEAKS, EDGE, REGIONPROPS, VISCIRCLES.
    sensibilite = 0.85;
    seuilContour = [];
    polarite = 'bright';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'sensitivity',    sensibilite = double(varargin{k+1});
            case 'edgethreshold',  seuilContour = double(varargin{k+1});
            case 'objectpolarity', polarite = lower(char(varargin{k+1}));
            case {'method', 'filtersize'}
                % Acceptées et sans effet : MatLibre n'a que la méthode
                % par accumulation à deux étapes.
            otherwise
                error('images:imfindcircles:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    I = im2double(I);
    if size(I, 3) > 1
        I = im2gray(I);
    end
    if strcmp(polarite, 'dark')
        I = 1 - I;
    end
    if isscalar(plage)
        rayonsEssayes = round(plage);
    else
        rayonsEssayes = round(plage(1)):round(plage(2));
    end
    if isempty(seuilContour)
        BW = edge(I, 'canny');
    else
        BW = edge(I, 'canny', seuilContour);
    end
    [lignes, colonnes] = find(BW);
    [m, n] = size(I);
    centres = zeros(0, 2);
    rayons = zeros(0, 1);
    forces = zeros(0, 1);
    if isempty(lignes)
        return;
    end
    angles = linspace(0, 2 * pi, 72);
    angles(end) = [];
    cosinus = cos(angles);
    sinus = sin(angles);
    meilleurs = zeros(0, 4);   % x, y, rayon, votes
    for r = rayonsEssayes
        % Chaque point de contour vote pour les centres à la distance r :
        % le cercle des centres possibles. Les votes se comptent d'un
        % coup, par accumarray, plutôt qu'un par un.
        cx = round(repmat(colonnes(:), 1, numel(angles)) + r * repmat(cosinus, numel(colonnes), 1));
        cy = round(repmat(lignes(:), 1, numel(angles)) + r * repmat(sinus, numel(lignes), 1));
        garde = cx >= 1 & cx <= n & cy >= 1 & cy <= m;
        indices = (cx(garde) - 1) * m + cy(garde);
        accumulateur = reshape(accumarray(indices(:), 1, [m * n, 1]), m, n);
        % On ne garde que le haut de l'accumulateur : chercher tous les
        % maxima locaux coûterait davantage que le vote lui-même, et le
        % tri qui suit départage de toute façon les candidats.
        sommet = max(accumulateur(:));
        if sommet <= 0
            continue;
        end
        [pl, pc] = find(accumulateur >= 0.8 * sommet);
        for j = 1:numel(pl)
            meilleurs(end + 1, :) = [pc(j), pl(j), r, accumulateur(pl(j), pc(j))];   %#ok<AGROW>
        end
    end
    if isempty(meilleurs)
        return;
    end
    % La force : les votes rapportés au nombre de points d'un cercle
    % parfait de ce rayon. Le classement, lui, se fait sur les votes
    % bruts : la force sature à un, et départagerait mal.
    force = min(meilleurs(:, 4) ./ min(numel(angles), 2 * pi * meilleurs(:, 3)), 1);
    seuil = 1 - sensibilite;
    garde = force >= seuil;
    meilleurs = meilleurs(garde, :);
    force = force(garde);
    if isempty(meilleurs)
        return;
    end
    [~, ordre] = sort(meilleurs(:, 4), 'descend');
    meilleurs = meilleurs(ordre, :);
    force = force(ordre);
    % Un pic bien plus faible que le meilleur n'est pas un cercle : c'est
    % le bruit de l'accumulateur.
    plancher = 0.5 * meilleurs(1, 4);
    garde = meilleurs(:, 4) >= plancher;
    meilleurs = meilleurs(garde, :);
    force = force(garde);
    % Deux détections proches désignent le même cercle : on ne garde que
    % la plus forte.
    for k = 1:size(meilleurs, 1)
        if isempty(centres)
            distinct = true;
        else
            distances = hypot(centres(:, 1) - meilleurs(k, 1), centres(:, 2) - meilleurs(k, 2));
            distinct = all(distances > meilleurs(k, 3));
        end
        if distinct
            centres(end + 1, :) = meilleurs(k, 1:2);   %#ok<AGROW>
            rayons(end + 1, 1) = meilleurs(k, 3);      %#ok<AGROW>
            forces(end + 1, 1) = force(k);             %#ok<AGROW>
        end
    end
end
