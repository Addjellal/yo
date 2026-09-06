% cartographie.m — Mapping Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/cartographie.m
%
% Le cas : mesurer sur une sphère. Toutes les difficultés de la
% cartographie viennent de là — la Terre est courbe, une carte est plate,
% et aucune projection ne conserve à la fois les distances, les angles et
% les surfaces.

fprintf('=== Cartographie : mesurer sur une sphere, dessiner sur un plan ===\n\n');

rayonTerre = 6371000;

%% 1. La distance orthodromique
% Le plus court chemin entre deux points d'une sphère n'est pas une
% droite sur la carte : c'est un arc de grand cercle. C'est pourquoi un
% vol Paris–Tokyo passe par la Sibérie.
paris = [48.8566, 2.3522];
tokyo = [35.6762, 139.6503];
newYork = [40.7128, -74.0060];
[distanceParisTokyo, capParisTokyo] = distanceGC(paris(1), paris(2), ...
                                                 tokyo(1), tokyo(2), rayonTerre);
fprintf('Paris - Tokyo :\n');
fprintf('  distance %.1f km, cap initial %.1f degres\n', ...
        distanceParisTokyo / 1000, capParisTokyo);
% La distance reelle est d'environ 9700 km.
assert(abs(distanceParisTokyo / 1000 - 9714) < 60);
% Le cap initial pointe vers le nord-est, non vers l'est : c'est
% exactement ce qui surprend sur une carte plate.
fprintf('  le cap est au nord-est, non plein est : %s\n', ...
        matlibre_essai_verdict(capParisTokyo < 90 && capParisTokyo > 0));
assert(capParisTokyo > 0 && capParisTokyo < 90);

% La formule de haversine donne la meme chose : elle est simplement plus
% stable quand les deux points sont proches.
parHaversine = haversine(paris(1), paris(2), tokyo(1), tokyo(2), rayonTerre);
fprintf('  par haversine : %.1f km (ecart %.3f m)\n', ...
        parHaversine / 1000, abs(parHaversine - distanceParisTokyo));
assert(abs(parHaversine - distanceParisTokyo) < 1);

% Une distance est nulle entre un point et lui-meme, et symetrique.
assert(distanceGC(paris(1), paris(2), paris(1), paris(2), rayonTerre) < 1e-6);
retour = distanceGC(tokyo(1), tokyo(2), paris(1), paris(2), rayonTerre);
assert(abs(retour - distanceParisTokyo) < 1e-6, 'la distance est symetrique');
% Elle respecte l'inegalite triangulaire.
directe = distanceGC(paris(1), paris(2), tokyo(1), tokyo(2), rayonTerre);
parNewYork = distanceGC(paris(1), paris(2), newYork(1), newYork(2), rayonTerre) + ...
             distanceGC(newYork(1), newYork(2), tokyo(1), tokyo(2), rayonTerre);
fprintf('  Paris-Tokyo direct %.0f km, via New York %.0f km\n', ...
        directe / 1000, parNewYork / 1000);
assert(directe <= parNewYork, 'l''inegalite triangulaire doit tenir');

%% 2. L'azimut
% La direction à suivre au départ. Sur un grand cercle elle change en
% route : partir plein est ne mène pas plein est.
capParisNewYork = azimuthTo(paris(1), paris(2), newYork(1), newYork(2));
fprintf('\nCap initial Paris - New York : %.1f degres\n', capParisNewYork);
assert(capParisNewYork > 270 || capParisNewYork < 300);
% Le cap vers l'ouest est bien dans le quadrant ouest-nord-ouest.
assert(capParisNewYork > 260 && capParisNewYork < 300);
% Un point plein nord a un cap de zero, plein sud de cent quatre-vingts.
assert(abs(azimuthTo(0, 0, 10, 0)) < 1e-6, 'plein nord : cap nul');
assert(abs(azimuthTo(0, 0, -10, 0) - 180) < 1e-6, 'plein sud : cap 180');
assert(abs(azimuthTo(0, 0, 0, 10) - 90) < 1e-6, 'plein est : cap 90');

%% 3. Le point d'arrivée
% Partir d'un point, suivre un cap sur une distance : où arrive-t-on ?
% C'est le problème inverse du précédent, et les deux doivent se
% recomposer exactement.
[latArrivee, lonArrivee] = reckon(paris(1), paris(2), distanceParisTokyo, ...
                                  capParisTokyo, rayonTerre);
fprintf('\nDepuis Paris, cap %.1f sur %.0f km :\n', ...
        capParisTokyo, distanceParisTokyo / 1000);
fprintf('  arrivee (%.4f, %.4f), Tokyo est en (%.4f, %.4f)\n', ...
        latArrivee, lonArrivee, tokyo(1), tokyo(2));
ecart = distanceGC(latArrivee, lonArrivee, tokyo(1), tokyo(2), rayonTerre);
fprintf('  ecart : %.1f m sur %.0f km\n', ecart, distanceParisTokyo / 1000);
assert(ecart < 1000, 'les deux problemes doivent se recomposer');
% Une distance nulle laisse sur place.
[latSurPlace, lonSurPlace] = reckon(paris(1), paris(2), 0, 45, rayonTerre);
assert(abs(latSurPlace - paris(1)) < 1e-9 && abs(lonSurPlace - paris(2)) < 1e-9);
% Aller plein nord de cent kilometres augmente la latitude d'environ
% 0.9 degre : un degre de latitude vaut cent onze kilometres partout.
[latNord, lonNord] = reckon(0, 0, 100000, 0, rayonTerre);
fprintf('  100 km plein nord depuis l''equateur : latitude %.4f degre\n', latNord);
assert(abs(latNord - 100000 / rayonTerre * 180 / pi) < 1e-6);
assert(abs(lonNord) < 1e-9, 'plein nord ne change pas la longitude');

%% 4. La surface
% Sur une sphère, l'aire ne se calcule pas comme sur un plan. AREAINT
% passe par la projection cylindrique équivalente — celle où l'ordonnée
% est le sinus de la latitude —, qui conserve les aires.
%
% Le résultat est exact pour un rectangle en latitude-longitude, dont les
% côtés restent droits dans cette projection.
latitudes = [0 0 10 10];
longitudes = [0 10 10 0];
aire = areaint(latitudes, longitudes, rayonTerre);
exacte = rayonTerre ^ 2 * (10 * pi / 180) * (sind(10) - sind(0));
fprintf('\nAire d''un rectangle de 10 degres sur 10, a l''equateur :\n');
fprintf('  %.6e m2, exacte %.6e m2, ecart relatif %.2e\n', ...
        aire, exacte, abs(aire - exacte) / exacte);
assert(abs(aire - exacte) / exacte < 1e-12, ...
       'la projection equivalente rend l''aire exacte d''un rectangle');
% Une aire est positive quel que soit le sens de parcours.
assert(areaint(fliplr(latitudes), fliplr(longitudes), rayonTerre) > 0);
% Le meme rectangle plus au nord couvre moins de surface : les meridiens
% s'y rapprochent.
aireNord = areaint([60 60 70 70], longitudes, rayonTerre);
fprintf('  le meme rectangle entre 60 et 70 degres nord : %.6e m2\n', aireNord);
assert(aireNord < aire, 'les meridiens se resserrent vers les poles');
% Toute la sphere : quatre rectangles de 180 degres de longitude.
aireHemisphere = areaint([0 0 90 90], [0 180 180 0], rayonTerre);
fprintf('  un quart de sphere : %.6f de 4 pi R2 (attendu 0.25)\n', ...
        aireHemisphere / (4 * pi * rayonTerre ^ 2));
assert(abs(aireHemisphere / (4 * pi * rayonTerre ^ 2) - 0.25) < 1e-12);
%
% En revanche, un polygone dont les cotes suivent des arcs de grand
% cercle n'est pas rendu exactement : ces arcs se courbent dans la
% projection. Le triangle equateur-pole en est le cas d'ecole — son aire
% vraie est le huitieme de la sphere, la formule en rend le seizieme.
% C'est une limite de la methode, non une erreur de calcul, et elle est
% dite dans l'aide d'AREAINT.
triangle = areaint([0 0 90], [0 90 0], rayonTerre);
fprintf('  triangle equateur-pole : %.6f de la sphere (aire vraie 0.125)\n', ...
        triangle / (4 * pi * rayonTerre ^ 2));
assert(abs(triangle / (4 * pi * rayonTerre ^ 2) - 0.0625) < 1e-9);

%% 5. La projection UTM
% Passer de la sphère au plan. UTM découpe le globe en soixante fuseaux
% de six degrés et projette chacun séparément : c'est ce découpage qui
% garde la déformation sous un millième à l'intérieur d'un fuseau.
[xParis, yParis, fuseauParis] = deg2utm(paris(1), paris(2));
fprintf('\nProjection UTM de Paris :\n');
fprintf('  fuseau %d, x = %.1f m, y = %.1f m\n', fuseauParis, xParis, yParis);
% Paris est dans le fuseau 31 : la longitude 2.35 tombe entre 0 et 6.
assert(fuseauParis == 31);
% L'abscisse est decalee de 500 km pour rester positive dans tout le
% fuseau : c'est la convention, et elle evite les signes.
assert(xParis > 0 && xParis < 1e6);
assert(yParis > 5e6, 'l''ordonnee compte depuis l''equateur');
% Deux points proches gardent leur distance : c'est ce que la projection
% promet a l'interieur d'un fuseau.
voisin = [paris(1) + 0.1, paris(2) + 0.1];
[xVoisin, yVoisin] = deg2utm(voisin(1), voisin(2));
distancePlane = hypot(xVoisin - xParis, yVoisin - yParis);
distanceSphere = distanceGC(paris(1), paris(2), voisin(1), voisin(2), rayonTerre);
fprintf('  distance a un voisin : %.1f m sur le plan, %.1f m sur la sphere\n', ...
        distancePlane, distanceSphere);
fprintf('  ecart relatif : %.5f\n', abs(distancePlane - distanceSphere) / distanceSphere);
assert(abs(distancePlane - distanceSphere) / distanceSphere < 0.01, ...
       'UTM conserve les distances locales a un pour cent pres');
% Un point d'un autre fuseau tombe dans un autre numero.
[~, ~, fuseauTokyo] = deg2utm(tokyo(1), tokyo(2));
fprintf('  Tokyo est dans le fuseau %d\n', fuseauTokyo);
assert(fuseauTokyo ~= fuseauParis);
assert(fuseauTokyo == floor((tokyo(2) + 180) / 6) + 1);

fprintf('\nToutes les verifications passent.\n');

function texte = matlibre_essai_verdict(condition)
    if condition
        texte = 'confirme';
    else
        texte = 'non';
    end
end
