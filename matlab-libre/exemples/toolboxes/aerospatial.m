% aerospatial.m — Aerospace Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/aerospatial.m
%
% Le cas : un avion en montée. L'atmosphère change avec l'altitude, et
% avec elle tout ce qui dépend de l'air — la portance, la traînée, la
% vitesse du son, donc le nombre de Mach.

fprintf('=== Aerospatial : l''atmosphere change tout avec l''altitude ===\n\n');

%% 1. L'atmosphère standard
% Un modèle conventionnel de l'atmosphère : température, pression, masse
% volumique et vitesse du son en fonction de l'altitude. Il ne décrit
% aucun jour en particulier — c'est une référence commune, qui permet de
% comparer des essais faits à des dates différentes.
altitudes = [0 5000 11000 15000];
fprintf('Atmosphere standard :\n');
fprintf('  %8s %10s %12s %10s %10s\n', 'z (m)', 'T (K)', 'P (Pa)', 'rho', 'a (m/s)');
for z = altitudes
    [T, a, P, rho] = atmosisa(z);
    fprintf('  %8d %10.2f %12.1f %10.4f %10.2f\n', z, T, P, rho, a);
end
% Au niveau de la mer : les valeurs de reference.
[T0, a0, P0, rho0] = atmosisa(0);
assert(abs(T0 - 288.15) < 0.1, 'quinze degres au niveau de la mer');
assert(abs(P0 - 101325) < 1, 'une atmosphere');
assert(abs(rho0 - 1.225) < 0.001);
assert(abs(a0 - 340.3) < 0.5, 'la vitesse du son y vaut 340 m/s');
% La temperature decroit de 6.5 degres par kilometre dans la troposphere.
[T5, ~, ~, ~] = atmosisa(5000);
gradient = (T0 - T5) / 5;
fprintf('\n  gradient troposhperique : %.4f K par km (attendu 6.5)\n', gradient);
assert(abs(gradient - 6.5) < 0.01);
% Au-dessus de onze kilometres, elle cesse de decroitre : c'est la
% tropopause, et c'est pourquoi les avions de ligne y volent.
[T11, ~, ~, ~] = atmosisa(11000);
[T15, ~, ~, ~] = atmosisa(15000);
fprintf('  a 11 km : %.2f K, a 15 km : %.2f K (la stratosphere est isotherme)\n', ...
        T11, T15);
assert(abs(T11 - T15) < 0.5, 'la temperature ne bouge plus au-dessus de 11 km');
% La pression et la masse volumique, elles, continuent de tomber.
[~, ~, P11, rho11] = atmosisa(11000);
[~, ~, P15, rho15] = atmosisa(15000);
assert(P15 < P11 && rho15 < rho11);
fprintf('  la pression, elle, tombe encore : %.0f Pa -> %.0f Pa\n', P11, P15);
% A onze kilometres, il ne reste qu'un quart de la pression du sol.
fprintf('  a 11 km il reste %.1f %% de la pression du sol\n', P11 / P0 * 100);
assert(P11 / P0 < 0.3);

%% 2. Le nombre de Mach
% Le rapport de la vitesse à celle du son. Ce n'est pas une vitesse : le
% même Mach correspond à des vitesses différentes selon l'altitude,
% puisque la vitesse du son suit la température.
vitesse = 250;                        % m/s
fprintf('\nA %g m/s :\n', vitesse);
for z = [0 11000]
    [~, a] = atmosisa(z);
    M = machnumber(vitesse, a);
    fprintf('  a %5d m : son a %.1f m/s, Mach %.4f\n', z, a, M);
end
[~, aSol] = atmosisa(0);
[~, aCroisiere] = atmosisa(11000);
machSol = machnumber(vitesse, aSol);
machCroisiere = machnumber(vitesse, aCroisiere);
assert(machCroisiere > machSol, ...
       'en altitude, la meme vitesse fait un Mach plus eleve');
assert(abs(machSol - vitesse / aSol) < 1e-12);
% Mach 1 est atteint a la vitesse du son, par definition.
assert(abs(machnumber(aSol, aSol) - 1) < 1e-12);
% La vitesse pour un Mach donne : elle baisse avec l'altitude.
vitesseMach08Sol = 0.8 * aSol;
vitesseMach08Croisiere = 0.8 * aCroisiere;
fprintf('  Mach 0.8 vaut %.1f m/s au sol, %.1f m/s a 11 km\n', ...
        vitesseMach08Sol, vitesseMach08Croisiere);
assert(vitesseMach08Croisiere < vitesseMach08Sol);

%% 3. La pression dynamique
% La grandeur qui commande la portance et la traînée : un demi rho v
% carré. Elle explique pourquoi un avion vole plus vite en altitude à
% effort structural égal — l'air y est plus rare.
fprintf('\nPression dynamique a %g m/s :\n', vitesse);
for z = altitudes
    [~, ~, ~, rho] = atmosisa(z);
    q = dpressure(rho, vitesse);
    fprintf('  a %5d m : rho %.4f, q = %8.1f Pa\n', z, rho, q);
end
[~, ~, ~, rhoSol] = atmosisa(0);
[~, ~, ~, rho11km] = atmosisa(11000);
qSol = dpressure(rhoSol, vitesse);
q11km = dpressure(rho11km, vitesse);
assert(abs(qSol - 0.5 * rhoSol * vitesse ^ 2) < 1e-9, ...
       'c''est bien un demi rho v carre');
assert(q11km < qSol, 'l''air rarefie reduit la pression dynamique');
% Elle croit comme le carre de la vitesse : doubler la vitesse la
% quadruple.
assert(abs(dpressure(rhoSol, 2 * vitesse) / qSol - 4) < 1e-12);
% A pression dynamique egale, on vole plus vite en altitude, dans le
% rapport des racines des masses volumiques.
vitesseEquivalente = vitesse * sqrt(rhoSol / rho11km);
fprintf('\n  a q constant, %g m/s au sol correspond a %.1f m/s a 11 km\n', ...
        vitesse, vitesseEquivalente);
assert(abs(dpressure(rho11km, vitesseEquivalente) - qSol) < 1e-6);

%% 4. Les attitudes
% L'orientation d'un aéronef se décrit par trois angles — lacet, tangage,
% roulis — ou par la matrice de rotation correspondante. Les deux
% descriptions doivent être exactement réversibles.
lacet = 0.3;
tangage = 0.2;
roulis = 0.1;
dcm = angle2dcm(lacet, tangage, roulis);
fprintf('\nMatrice de rotation depuis (%.1f, %.1f, %.1f) rad :\n', ...
        lacet, tangage, roulis);
% C'est une rotation : orthogonale, de determinant un.
assert(max(max(abs(dcm' * dcm - eye(3)))) < 1e-12, 'la matrice est orthogonale');
assert(abs(det(dcm) - 1) < 1e-12, 'et de determinant un, non moins un');
fprintf('  orthogonale a %.2e pres, determinant %.12f\n', ...
        max(max(abs(dcm' * dcm - eye(3)))), det(dcm));
% Les angles se relisent sur la matrice.
[r1, r2, r3] = dcm2angle(dcm);
fprintf('  angles relus : (%.4f, %.4f, %.4f)\n', r1, r2, r3);
assert(max(abs([r1 r2 r3] - [lacet tangage roulis])) < 1e-12, ...
       'les deux conversions sont exactement inverses');
% Une rotation conserve les longueurs.
v = [1; 2; 3];
assert(abs(norm(dcm * v) - norm(v)) < 1e-12);
% Et les angles entre vecteurs.
w = [3; -1; 2];
assert(abs(dot(dcm * v, dcm * w) - dot(v, w)) < 1e-12);

%% 5. Les coordonnées géocentriques
% Passer de la latitude, longitude et altitude à un repère cartésien lié
% à la Terre. C'est ce que fait tout récepteur satellitaire avant de
% pouvoir calculer quoi que ce soit.
[x, y, z] = geodetic2ecef(45, 0, 0);
fprintf('\nPoint a 45 degres nord, longitude nulle, au niveau de la mer :\n');
fprintf('  (%.1f, %.1f, %.1f) m\n', x, y, z);
% Longitude nulle : le point est dans le plan xz.
assert(abs(y) < 1e-6, 'longitude nulle : rien sur l''axe y');
% Il est a peu pres a un rayon terrestre de l'origine.
distance = sqrt(x ^ 2 + y ^ 2 + z ^ 2);
fprintf('  distance au centre : %.1f km\n', distance / 1000);
assert(abs(distance - 6367000) < 20000);
% L'equateur est dans le plan z = 0.
[~, ~, zEquateur] = geodetic2ecef(0, 0, 0);
assert(abs(zEquateur) < 1e-6);
% Le pole nord est sur l'axe z.
[xPole, yPole, zPole] = geodetic2ecef(90, 0, 0);
assert(abs(xPole) < 1e-6 && abs(yPole) < 1e-6);
assert(zPole > 6300000);
fprintf('  le pole nord est a (%.1f, %.1f, %.1f) km\n', ...
        xPole / 1000, yPole / 1000, zPole / 1000);
% La Terre est aplatie : le rayon polaire est plus court que
% l'equatorial, d'environ vingt et un kilometres.
[xEquateur, ~, ~] = geodetic2ecef(0, 0, 0);
fprintf('  rayon equatorial %.1f km, polaire %.1f km, ecart %.1f km\n', ...
        xEquateur / 1000, zPole / 1000, (xEquateur - zPole) / 1000);
assert(xEquateur > zPole, 'la Terre est aplatie aux poles');
assert(abs((xEquateur - zPole) / 1000 - 21.4) < 1);
% L'altitude ajoute bien ce qu'on lui demande.
[xHaut, ~, ~] = geodetic2ecef(0, 0, 1000);
assert(abs((xHaut - xEquateur) - 1000) < 1e-6);

fprintf('\nToutes les verifications passent.\n');
