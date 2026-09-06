function aire = areaint(latitudes, longitudes, rayon)
%AREAINT Aire d'un polygone tracé sur la sphère.
%   A = AREAINT(LATITUDES,LONGITUDES) rend l'aire en mètres carrés sur
%   une sphère de rayon terrestre ; AREAINT(...,RAYON) impose le rayon.
%   Le polygone se referme tout seul : le dernier sommet est relié au
%   premier.
%
%   Le calcul se fait dans la projection cylindrique équivalente — celle
%   où l'ordonnée est le sinus de la latitude — par la formule
%
%      A = R^2 / 2 * |somme (lon(j) - lon(k)) (sin lat(k) + sin lat(j))|
%
%   Cette projection conserve les aires, si bien que l'aire du polygone
%   projeté est celle du polygone sur la sphère — à condition que ses
%   côtés soient droits dans la projection. C'est le cas des côtés à
%   latitude constante et des méridiens, donc de tout rectangle en
%   latitude-longitude : pour ceux-là le résultat est exact.
%
%   Ce n'est pas le cas d'un côté qui suit un arc de grand cercle : cet
%   arc se courbe dans la projection, et l'aire rendue est celle du
%   polygone à côtés droits, non celle du polygone à côtés géodésiques.
%   Un triangle sphérique à sommet au pôle en donne un exemple net : la
%   formule rend la moitié de son aire véritable.
%
%   Exemple :
%      % Un rectangle de dix degres sur dix, a l'equateur.
%      areaint([0 0 10 10], [0 10 10 0])
%      % Son aire exacte : R^2 (lon2-lon1) (sin lat2 - sin lat1)
%      6371000 ^ 2 * (10 * pi / 180) * sind(10)
%
%   Voir aussi DISTANCEGC, RECKON, DEG2UTM.
    if nargin < 3
        rayon = 6371000;
    end
    lat = latitudes(:) * pi/180;
    lon = longitudes(:) * pi/180;
    n = numel(lat);
    somme = 0;
    for k = 1:n
        j = mod(k, n) + 1;
        somme = somme + (lon(j) - lon(k)) * (2 + sin(lat(k)) + sin(lat(j)));
    end
    aire = abs(somme * rayon^2 / 2);
end
