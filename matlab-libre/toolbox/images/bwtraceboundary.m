function contour = bwtraceboundary(bw, depart, direction, connexite, nombre, sens)
%BWTRACEBOUNDARY Suit le contour d'un objet à partir d'un point.
%   C = BWTRACEBOUNDARY(BW,P,DIR) part du pixel P = [ligne colonne] en
%   cherchant d'abord dans la direction DIR ('N', 'NE', 'E'…) et suit le
%   bord de l'objet jusqu'à revenir au départ.
%
%   L'algorithme est celui de Moore : on tourne autour du pixel courant à
%   partir du voisin d'où l'on vient, et l'on saute sur le premier pixel
%   allumé rencontré.
    if nargin < 3 || isempty(direction), direction = 'N'; end
    if nargin < 4 || isempty(connexite), connexite = 8; end
    if nargin < 5 || isempty(nombre), nombre = Inf; end
    if nargin < 6 || isempty(sens), sens = 'clockwise'; end
    bw = logical(bw);
    [h, l] = size(bw);
    voisinage = [-1 0; -1 1; 0 1; 1 1; 1 0; 1 -1; 0 -1; -1 -1];   % N, NE, E, SE, S, SO, O, NO
    noms = {'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'};
    depart = round(double(depart(:))');
    debut = find(strcmpi(noms, char(direction)), 1);
    if isempty(debut), debut = 1; end
    if strncmpi(char(sens), 'counter', 7)
        voisinage = flipud(voisinage);
        debut = size(voisinage, 1) - debut + 1;
    end
    if connexite == 4
        garde = [1 3 5 7];
    else
        garde = 1:8;
    end
    contour = depart;
    courant = depart;
    entree = debut;
    for pas = 1:1e6
        suivant = [];
        for k = 0:7
            indice = mod(entree - 1 + k, 8) + 1;
            if ~any(garde == indice)
                continue
            end
            candidat = courant + voisinage(indice, :);
            if candidat(1) >= 1 && candidat(1) <= h && candidat(2) >= 1 && ...
                    candidat(2) <= l && bw(candidat(1), candidat(2))
                suivant = candidat;
                % On repart du voisin opposé, tourné d'un cran.
                entree = mod(indice + 4, 8) + 1;
                break
            end
        end
        if isempty(suivant)
            break
        end
        contour(end + 1, :) = suivant;              %#ok<AGROW>
        courant = suivant;
        if size(contour, 1) >= nombre
            break
        end
        if isequal(suivant, depart) && size(contour, 1) > 2
            break
        end
    end
end
