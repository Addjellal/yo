function pics = houghpeaks(H, nombre, varargin)
%HOUGHPEAKS Pics de l'accumulateur de Hough.
%   PICS = HOUGHPEAKS(H,N) rend au plus N pics, une ligne par pic donnant
%   sa ligne et sa colonne dans H. Après chaque pic retenu, son voisinage
%   est mis à zéro : sans cela, un même pic large serait compté
%   plusieurs fois.
%
%   HOUGHPEAKS(...,'Threshold',T) ignore les pics sous T (la moitié du
%   maximum par défaut), 'NHoodSize',[L C] donne la taille du voisinage
%   effacé.
%
%   Exemple :
%      [H, theta, rho] = hough(BW);
%      pics = houghpeaks(H, 3);
%
%   Voir aussi HOUGH, HOUGHLINES, IMREGIONALMAX.
    if nargin < 2 || isempty(nombre)
        nombre = 1;
    end
    H = double(H);
    seuil = 0.5 * max(H(:));
    voisinage = 2 * floor(size(H) / 50) + 1;
    voisinage = max(voisinage, [1 1]);
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'threshold', seuil = double(varargin{k+1});
            case 'nhoodsize', voisinage = round(double(varargin{k+1}));
            otherwise
                error('images:houghpeaks:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    voisinage = max(voisinage(:).', [1 1]);
    demi = (voisinage - 1) / 2;
    travail = H;
    pics = zeros(0, 2);
    for compte = 1:nombre
        [valeur, position] = max(travail(:));
        if isempty(valeur) || valeur <= seuil || valeur == 0
            break;
        end
        [i, j] = ind2sub(size(travail), position);
        pics(end + 1, :) = [i, j];   %#ok<AGROW>
        lignes = max(1, i - demi(1)):min(size(travail, 1), i + demi(1));
        colonnes = max(1, j - demi(2)):min(size(travail, 2), j + demi(2));
        travail(lignes, colonnes) = 0;
    end
end
