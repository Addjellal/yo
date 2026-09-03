function droites = houghlines(BW, theta, rho, pics, varargin)
%HOUGHLINES Segments de droite d'après les pics de Hough.
%   DROITES = HOUGHLINES(BW,THETA,RHO,PICS) rend, pour chaque pic, les
%   segments effectivement présents dans l'image : les points alignés
%   sont regroupés, les trous courts comblés, et les segments trop courts
%   écartés.
%
%   Chaque élément porte point1, point2, theta et rho. Les points sont
%   donnés en [x y], c'est-à-dire [colonne ligne].
%
%   HOUGHLINES(...,'FillGap',G) comble les trous de moins de G pixels
%   (20 par défaut), 'MinLength',L écarte les segments plus courts que L
%   (40 par défaut).
%
%   Exemple :
%      [H, theta, rho] = hough(BW);
%      pics = houghpeaks(H, 3);
%      droites = houghlines(BW, theta, rho, pics, 'MinLength', 10);
%
%   Voir aussi HOUGH, HOUGHPEAKS, EDGE, REGIONPROPS.
    combler = 20;
    longueurMin = 40;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'fillgap',   combler = double(varargin{k+1});
            case 'minlength', longueurMin = double(varargin{k+1});
            otherwise
                error('images:houghlines:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    BW = logical(BW);
    [lignesImage, colonnesImage] = find(BW);
    droites = struct('point1', {}, 'point2', {}, 'theta', {}, 'rho', {});
    if isempty(lignesImage)
        return;
    end
    for p = 1:size(pics, 1)
        angle = theta(pics(p, 2));
        distance = rho(pics(p, 1));
        % Les points de l'image qui tombent sur cette droite, à un demi
        % pixel près.
        surDroite = abs(colonnesImage * cosd(angle) + lignesImage * sind(angle) - distance) <= 1;
        if ~any(surDroite)
            continue;
        end
        x = colonnesImage(surDroite);
        y = lignesImage(surDroite);
        % Position le long de la droite : c'est elle qui ordonne les
        % points et fait apparaître les trous.
        position = -x * sind(angle) + y * cosd(angle);
        [position, ordre] = sort(position);
        x = x(ordre);
        y = y(ordre);
        debut = 1;
        for k = 2:(numel(position) + 1)
            trou = false;
            if k > numel(position)
                trou = true;
            elseif position(k) - position(k - 1) > combler
                trou = true;
            end
            if trou
                fin = k - 1;
                if debut > fin
                    % Le point precedent fermait deja un segment : il
                    % n'en reste rien a mesurer.
                    debut = k;
                    continue;
                end
                longueur = hypot(x(fin) - x(debut), y(fin) - y(debut));
                if longueur >= longueurMin
                    droites(end + 1) = struct('point1', [x(debut), y(debut)], ...
                                              'point2', [x(fin), y(fin)], ...
                                              'theta', angle, 'rho', distance);   %#ok<AGROW>
                end
                debut = k;
            end
        end
    end
end
