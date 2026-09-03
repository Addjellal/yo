function [H, theta, rho] = hough(BW, varargin)
%HOUGH Transformée de Hough d'une image binaire.
%   [H,THETA,RHO] = HOUGH(BW) rend l'accumulateur de Hough : chaque point
%   allumé de BW vote pour toutes les droites qui passent par lui, et
%   H(i,j) compte les votes de la droite d'angle THETA(j) et de distance
%   RHO(i). Une droite de l'image apparaît alors comme un pic.
%
%   Une droite s'écrit x cos(theta) + y sin(theta) = rho, ce qui la
%   décrit sans cas particulier — la forme y = ax+b ne sait pas dire
%   « verticale ».
%
%   HOUGH(...,'Theta',T) donne les angles en degrés (-90 à 89 par pas
%   d'un degré par défaut), 'RhoResolution',R le pas des distances.
%
%   Exemple :
%      BW = false(50, 50);
%      BW(20, 5:45) = true;                % une droite horizontale
%      [H, theta, rho] = hough(BW);
%      pics = houghpeaks(H, 1);
%
%   Voir aussi HOUGHPEAKS, HOUGHLINES, EDGE, IMFINDCIRCLES, RADON.
    BW = logical(BW);
    theta = -90:89;
    pasRho = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'theta',         theta = double(varargin{k+1}(:)).';
            case 'rhoresolution', pasRho = double(varargin{k+1});
            otherwise
                error('images:hough:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    [m, n] = size(BW);
    diagonale = sqrt(m ^ 2 + n ^ 2);
    rhoMax = pasRho * ceil(diagonale / pasRho);
    rho = -rhoMax:pasRho:rhoMax;
    H = zeros(numel(rho), numel(theta));
    [lignes, colonnes] = find(BW);
    if isempty(lignes)
        return;
    end
    cosinus = cosd(theta);
    sinus = sind(theta);
    for k = 1:numel(lignes)
        % Les coordonnées de l'image : x est la colonne, y la ligne.
        distances = colonnes(k) * cosinus + lignes(k) * sinus;
        indices = round((distances + rhoMax) / pasRho) + 1;
        for j = 1:numel(theta)
            i = indices(j);
            if i >= 1 && i <= numel(rho)
                H(i, j) = H(i, j) + 1;
            end
        end
    end
end
