% test_geometrie.m — géométrie du plan et de l'espace, interpolants.
% Chaque objet est vérifié sur la propriété qui le définit : le cercle
% vide pour Delaunay, la convexité pour l'enveloppe, l'exactitude sur une
% fonction affine pour un interpolant linéaire.
disp('--- geometrie ---');

%% ------------------------------------------------------------ POLYAREA
assert(abs(polyarea([0 1 1 0], [0 0 1 1]) - 1) < 1e-14);
assert(abs(polyarea([0 4 4 0], [0 0 3 3]) - 12) < 1e-14);
% Un L non convexe : la formule du lacet ne suppose pas la convexité.
assert(abs(polyarea([0 2 2 1 1 0], [0 0 1 1 2 2]) - 3) < 1e-14);
% Le sens de parcours ne change rien : l'aire rendue est positive.
assert(abs(polyarea([0 0 1 1], [0 1 1 0]) - 1) < 1e-14);
% Une colonne par polygone.
assert(max(abs(polyarea([0 0; 1 2; 1 2; 0 0], [0 0; 0 0; 1 2; 1 2]) - [1 4])) < 1e-14);
% Un cercle finement échantillonné tend vers pi.
t = 0:0.001:2*pi;
assert(abs(polyarea(cos(t), sin(t)) - pi) < 1e-3);
% Translater ne change pas l'aire : la formule est invariante par
% translation, ce qui n'a rien d'évident à la lire.
assert(abs(polyarea([0 1 1 0] + 100, [0 0 1 1] - 50) - 1) < 1e-12);

%% ------------------------------------------------------------- RECTINT
assert(abs(rectint([0 0 2 2], [1 1 2 2]) - 1) < 1e-14);
assert(rectint([0 0 1 1], [3 3 1 1]) == 0);
% Un rectangle avec lui-même rend sa propre aire.
assert(abs(rectint([2 3 4 5], [2 3 4 5]) - 20) < 1e-14);
M = rectint([0 0 2 2; 5 5 1 1], [1 1 2 2; 0 0 1 1]);
assert(isequal(size(M), [2 2]));
assert(abs(M(1, 1) - 1) < 1e-14 && abs(M(1, 2) - 1) < 1e-14);
assert(M(2, 1) == 0 && M(2, 2) == 0);

%% ------------------------------------------------------------ DELAUNAY
% La propriété du cercle vide : aucun point du nuage n'est à l'intérieur
% du cercle circonscrit d'un triangle. C'est la définition, et rien
% d'autre ne caractérise la triangulation de Delaunay.
rand('seed', 11);
P = rand(40, 2);
T = delaunay(P(:, 1), P(:, 2));
tr = triangulation(T, P);
c = circumcenter(tr);
pire = 0;
for e = 1:size(T, 1)
    rayon = norm(P(T(e, 1), :) - c(e, :));
    pire = max(pire, rayon - min(sqrt(sum((P - c(e, :)) .^ 2, 2))));
end
assert(pire < 1e-9);
% Les triangles pavent exactement l'enveloppe convexe : ni trou, ni
% recouvrement. La somme de leurs aires le dit.
aireT = 0;
for e = 1:size(T, 1)
    s = T(e, :);
    aireT = aireT + abs((P(s(2),1) - P(s(1),1)) * (P(s(3),2) - P(s(1),2)) - ...
                        (P(s(3),1) - P(s(1),1)) * (P(s(2),2) - P(s(1),2))) / 2;
end
k = convhull(P(:, 1), P(:, 2));
assert(abs(aireT - polyarea(P(k, 1), P(k, 2))) < 1e-12);

% Des points cocycliques sont le cas dégénéré : le test du cercle rend
% zéro, et si on le laisse à l'arrondi, la triangulation se recouvre.
tc = linspace(0, 2*pi, 41)'; tc(end) = [];
xc = cos(tc); yc = sin(tc);
Tc = delaunay(xc, yc);
assert(size(Tc, 1) == numel(tc) - 2);      % un polygone convexe à n sommets
aireC = 0;                                  % se triangule en n-2 triangles
for e = 1:size(Tc, 1)
    s = Tc(e, :);
    aireC = aireC + abs((xc(s(2)) - xc(s(1))) * (yc(s(3)) - yc(s(1))) - ...
                        (xc(s(3)) - xc(s(1))) * (yc(s(2)) - yc(s(1)))) / 2;
end
assert(abs(aireC - polyarea(xc, yc)) < 1e-12);

%% ------------------------------------------------------- TRIANGULATION
Pc = [0 0; 1 0; 1 1; 0 1];
carre = triangulation([1 2 3; 1 3 4], Pc);
assert(size(edges(carre), 1) == 5);        % quatre côtés et la diagonale
assert(size(freeBoundary(carre), 1) == 4);
% Euler pour une triangulation du plan sans trou : V - E + F = 1.
assert(4 - size(edges(carre), 1) + size(carre.ConnectivityList, 1) == 1);
% Les voisins sont symétriques, et NaN là où il n'y a personne.
N = neighbors(carre);
assert(isequal(size(N), [2 3]));
assert(sum(~isnan(N(:))) == 2);
% Le centre circonscrit est équidistant des trois sommets : c'est sa
% définition, et elle se vérifie sans le calculer autrement.
cc = circumcenter(carre);
for e = 1:2
    s = carre.ConnectivityList(e, :);
    rayons = sqrt(sum((Pc(s, :) - cc(e, :)) .^ 2, 2));
    assert(max(rayons) - min(rayons) < 1e-14);
end
% Le centre inscrit est équidistant des trois côtés.
ci = incenter(carre);
for e = 1:2
    s = carre.ConnectivityList(e, :);
    distances = zeros(3, 1);
    for j = 1:3
        a = Pc(s(j), :); b = Pc(s(mod(j, 3) + 1), :);
        distances(j) = abs((b(1)-a(1)) * (a(2)-ci(e,2)) - (a(1)-ci(e,1)) * (b(2)-a(2))) ...
                       / norm(b - a);
    end
    assert(max(distances) - min(distances) < 1e-14);
end
% Les coordonnées barycentriques somment à un, et l'aller-retour revient.
B = cartesianToBarycentric(carre, [1; 2], [0.6 0.3; 0.3 0.6]);
assert(max(abs(sum(B, 2) - 1)) < 1e-14);
assert(max(max(abs(barycentricToCartesian(carre, [1; 2], B) - ...
                   [0.6 0.3; 0.3 0.6]))) < 1e-13);
% Les attachements : le sommet 1 et le sommet 3 portent les deux triangles.
A = vertexAttachments(carre, [1; 2]);
assert(numel(A{1}) == 2 && numel(A{2}) == 1);
assert(isConnected(carre, 1, 3));          % la diagonale existe
assert(~isConnected(carre, 2, 4));         % l'autre diagonale, non

% En trois dimensions, la normale d'une facette est unitaire et
% orthogonale à ses deux côtés.
tetra = triangulation([1 2 3], [0 0 0; 1 0 0; 0 1 0]);
n3 = faceNormal(tetra);
assert(abs(norm(n3) - 1) < 1e-14);
assert(abs(dot(n3, [1 0 0])) < 1e-14 && abs(dot(n3, [0 1 0])) < 1e-14);

%% ------------------------------------------ DELAUNAYTRIANGULATION, isa
Pd = [0 0; 1 0; 1 1; 0 1; 0.5 0.5];
dt = delaunayTriangulation(Pd);
% Elle dérive de TRIANGULATION : l'héritage doit être réel, pas recopié.
assert(isa(dt, 'triangulation'));
assert(isa(dt, 'delaunayTriangulation'));
assert(any(strcmp(superclasses(dt), 'triangulation')));
assert(size(dt.ConnectivityList, 1) == 4);
% Le bord libre d'une triangulation de Delaunay est l'enveloppe convexe :
% conséquence directe de la propriété du cercle vide.
assert(isequal(sort(unique(freeBoundary(dt))), sort(unique(dt.convexHull))));
[indices, poids] = pointLocation(dt, [0.6 0.4; 5 5]);
assert(~isnan(indices(1)) && isnan(indices(2)));
assert(abs(sum(poids(1, :)) - 1) < 1e-14);
assert(nearestNeighbor(dt, [0.9 0.9]) == 3);
% Les méthodes héritées marchent telles quelles.
assert(size(circumcenter(dt), 1) == 4);
assert(size(edges(dt), 1) == 8);

%% ----------------------------------------------------------- CONVHULLN
% En deux dimensions : le point du milieu est dedans, donc il n'est pas
% sur l'enveloppe.
[K2, aire2] = convhulln([0 0; 1 0; 1 1; 0 1; 0.5 0.5]);
assert(size(K2, 1) == 4);
assert(abs(aire2 - 1) < 1e-14);
% Un tétraèdre : quatre faces, volume 1/6.
[K3, v3] = convhulln([0 0 0; 1 0 0; 0 1 0; 0 0 1]);
assert(size(K3, 1) == 4);
assert(abs(v3 - 1/6) < 1e-14);
% Un cube : douze triangles — deux par face carrée —, volume 1. C'est le
% cas dégénéré des points coplanaires : quatre coins par face.
cube = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
[Kc, vc] = convhulln(cube);
assert(size(Kc, 1) == 12);
assert(abs(vc - 1) < 1e-12);
% Un point intérieur ne change rien.
[Ki, vi] = convhulln([cube; 0.5 0.5 0.5]);
assert(size(Ki, 1) == 12);
assert(abs(vi - 1) < 1e-12);
% Sur une sphère, la relation d'Euler V - E + F = 2 doit tenir : c'est ce
% qui prouve que les facettes forment bien une surface fermée.
randn('seed', 4);
S = randn(80, 3);
S = S ./ sqrt(sum(S .^ 2, 2));
[Ks, vs] = convhulln(S);
aretesS = unique(sort([Ks(:, [1 2]); Ks(:, [2 3]); Ks(:, [3 1])], 2), 'rows');
assert(80 - size(aretesS, 1) + size(Ks, 1) == 2);
% Tous les points sont sur la sphère, donc sur l'enveloppe : le nombre de
% facettes vaut 2n - 4 pour un polytope simplicial.
assert(size(Ks, 1) == 2 * 80 - 4);
% Le volume d'un polytope inscrit est inférieur à celui de la sphère, et
% s'en approche quand on ajoute des points : c'est la seule chose qu'on
% puisse affirmer sans connaître le tirage.
assert(vs < 4 * pi / 3);
S2 = randn(200, 3);
S2 = S2 ./ sqrt(sum(S2 .^ 2, 2));
[~, vs2] = convhulln(S2);
assert(vs2 < 4 * pi / 3 && vs2 > vs);

%% ------------------------------------------------- BOUNDARY, ALPHASHAPE
tb = linspace(0, 2*pi, 41)'; tb(end) = [];
xb = cos(tb); yb = sin(tb);
% À serrage nul, le contour est l'enveloppe convexe : aucun triangle n'est
% retiré, donc le bord est celui de la triangulation entière.
[kb, ab] = boundary(xb, yb, 0);
assert(isequal(unique(kb), unique(convhull(xb, yb))));
assert(abs(ab - polyarea(xb, yb)) < 1e-12);
% Sur un demi-anneau, le serrage doit creuser le trou que l'enveloppe
% convexe comble.
th = linspace(pi, 2*pi, 25)';
xa = [cos(th); 0.5 * cos(th)];
ya = [sin(th); 0.5 * sin(th)];
[~, aireConvexe] = boundary(xa, ya, 0);
[~, aireSerree] = boundary(xa, ya, 1);
assert(aireSerree < aireConvexe);
assert(abs(aireSerree - pi / 2 * (1 - 0.25)) < 0.05);

shp = alphaShape(xb, yb, 2);
assert(abs(area(shp) - polyarea(xb, yb)) < 1e-9);
assert(abs(perimeter(shp) - 40 * 2 * sin(pi / 40)) < 1e-9);
assert(inShape(shp, 0, 0));
assert(~inShape(shp, 5, 5));
assert(numRegions(shp) == 1);
assert(size(boundaryFacets(shp), 1) == 40);
% Deux amas éloignés font deux régions tant que le rayon reste petit, une
% seule dès qu'il est assez grand pour les relier.
rand('seed', 13);
amas = [rand(15, 2); rand(15, 2) + 4];
assert(numRegions(alphaShape(amas, 0.5)) == 2);
assert(numRegions(alphaShape(amas, 100)) == 1);
% À rayon infini, aucun triangle n'est retiré : la forme est exactement
% l'enveloppe convexe. Un rayon seulement grand ne suffit pas — deux amas
% éloignés se relient par des triangles très plats, dont le cercle
% circonscrit est énorme.
grande = alphaShape(amas, inf);
kAmas = convhull(amas(:, 1), amas(:, 2));
assert(abs(area(grande) - polyarea(amas(kAmas, 1), amas(kAmas, 2))) < 1e-10);

%% --------------------------------------------------------- INTERPOLANTS
% Un interpolant linéaire sur données dispersées est exact sur tout plan :
% trois points définissent un plan, et le barycentre y reste.
xs = [0; 1; 0; 1; 0.5];
ys = [0; 0; 1; 1; 0.5];
vs = 2 * xs + 3 * ys + 1;
F = scatteredInterpolant(xs, ys, vs);
assert(abs(F(0.25, 0.75) - (2 * 0.25 + 3 * 0.75 + 1)) < 1e-12);
assert(abs(F(0.7, 0.2) - (2 * 0.7 + 3 * 0.2 + 1)) < 1e-12);
% Il repasse exactement par les données : c'est ce qui distingue
% interpoler d'ajuster.
assert(max(abs(F(xs, ys) - vs)) < 1e-12);
% Dehors, c'est de l'extrapolation, et elle est refusée plutôt que devinée.
assert(isnan(F(5, 5)));
G = scatteredInterpolant(xs, ys, vs, 'linear', 'nearest');
assert(~isnan(G(5, 5)));
Nn = scatteredInterpolant(xs, ys, vs, 'nearest');
assert(abs(Nn(0.05, 0.05) - vs(1)) < 1e-14);
assert(isequal(size(F([0.2 0.3; 0.4 0.5], [0.2 0.3; 0.4 0.5])), [2 2]));

xg = linspace(0, 1, 11);
Fg = griddedInterpolant(xg, 3 * xg + 1);
assert(abs(Fg(0.35) - (3 * 0.35 + 1)) < 1e-12);
assert(max(abs(Fg(xg) - (3 * xg + 1))) < 1e-12);
assert(isnan(Fg(5)));
Gg = griddedInterpolant(xg, 3 * xg + 1, 'linear', 'linear');
assert(abs(Gg(2) - 7) < 1e-12);
% En deux dimensions, la grille est celle de NDGRID.
xn = linspace(0, 1, 6);
yn = linspace(0, 2, 7);
[Xn, Yn] = ndgrid(xn, yn);
Vn = 2 * Xn + 3 * Yn + 1;
Hg = griddedInterpolant(xn, yn, Vn);
assert(abs(Hg(0.3, 1.4) - (2 * 0.3 + 3 * 1.4 + 1)) < 1e-12);
assert(max(max(abs(Hg(Xn, Yn) - Vn))) < 1e-12);

%% ----------------------------------------- INTERP1 : chaque methode agit
xi = linspace(0, 1, 11);
vi = sin(pi * xi);
% Toutes repassent par les données.
for methode = {'linear', 'nearest', 'spline', 'pchip', 'makima'}
    assert(max(abs(interp1(xi, vi, xi, methode{1}) - vi)) < 1e-14);
end
% Et chacune fait ce qu'elle promet : la spline est la plus précise sur
% une fonction lisse, la linéaire la moins.
ecartLineaire = abs(interp1(xi, vi, 0.37, 'linear') - sin(pi * 0.37));
ecartSpline = abs(interp1(xi, vi, 0.37, 'spline') - sin(pi * 0.37));
assert(ecartSpline < ecartLineaire / 100);
% La spline « not-a-knot » reproduit exactement les polynômes de degré trois.
xcub = 0:4;
assert(max(abs(interp1(xcub, xcub.^3, 0:0.25:4, 'spline') - (0:0.25:4).^3)) < 1e-12);
% PCHIP préserve la forme : sur une marche, il ne dépasse jamais.
xmarche = 0:5;
ymarche = [0 0 0 1 1 1];
p = interp1(xmarche, ymarche, 0:0.05:5, 'pchip');
assert(max(p) <= 1 + 1e-14 && min(p) >= -1e-14);
% La spline, elle, ondule : c'est la différence entre les deux, et ce test
% échouerait si PCHIP se repliait en silence sur autre chose.
sp = interp1(xmarche, ymarche, 0:0.05:5, 'spline');
assert(max(sp) > 1 + 0.01);
% MAKIMA ne dépasse pas non plus sur cette marche.
assert(max(interp1(xmarche, ymarche, 0:0.05:5, 'makima')) <= 1 + 1e-12);
% Et c'est là sa raison d'être : sur un palier suivi d'une pente, l'Akima
% d'origine ondule dans le plat, la modification l'en empêche. Les poids
% croisés de la formule sont ce qui produit cette différence — les
% intervertir la ferait disparaître.
xpalier = 0:7;
ypalier = [0 0 0 0 1 2 3 4];
qp = 0:0.05:7;
plat = qp <= 3;
ondulationAkima = max(abs(interp1(xpalier, ypalier, qp(plat), 'akima')));
ondulationMakima = max(abs(interp1(xpalier, ypalier, qp(plat), 'makima')));
assert(ondulationAkima > 0.05);
assert(ondulationMakima < 1e-12);
% Toutes deux restent exactes sur une droite.
assert(max(abs(interp1(0:5, 2*(0:5) + 1, 0:0.1:5, 'makima') - (2*(0:0.1:5) + 1))) < 1e-12);
% Une méthode inconnue est refusée : se replier sur la linéaire rendrait
% un résultat faux sans que rien ne le dise.
refuse = false;
try
    interp1(xi, vi, 0.5, 'ceciNexistePas');
catch
    refuse = true;
end
assert(refuse);
% PCHIP et MAKIMA s'appellent aussi directement, et rendent la forme par
% morceaux quand on ne leur donne pas de points.
assert(abs(pchip(xi, vi, 0.37) - interp1(xi, vi, 0.37, 'pchip')) < 1e-14);
assert(abs(makima(xi, vi, 0.37) - interp1(xi, vi, 0.37, 'makima')) < 1e-14);
pp = pchip(xi, vi);
assert(strcmp(pp.form, 'pp'));
assert(pp.pieces == numel(xi) - 1);
assert(abs(ppval(pp, 0.37) - pchip(xi, vi, 0.37)) < 1e-14);

disp('geometrie : toutes les verifications passent');
