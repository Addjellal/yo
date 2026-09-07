% edp.m — équations aux dérivées partielles, cas d'école.
%
%   matlibre exemples/toolboxes/edp.m
%
% Trois équations, trois comportements. La chaleur lisse et oublie ;
% l'onde transporte et se souvient ; Laplace équilibre. Ce sont les trois
% familles — parabolique, hyperbolique, elliptique — et les distinguer
% est la première chose qu'un cours enseigne.

fprintf('=== EDP : la chaleur lisse, l''onde transporte, Laplace equilibre ===\n\n');

%% 1. La chaleur
% Une barre chauffée au milieu, refroidie aux bouts. La chaleur diffuse :
% le maximum baisse, le profil s'élargit, l'énergie s'échappe par les
% bords.
% La condition initiale se donne par une poignee, et la grille rendue ne
% porte que les points interieurs : les bords sont imposes, non calcules.
longueur = 1;
nx = 51;
alpha = 0.01;
initial = @(x) exp(-((x - 0.5) / 0.1) .^ 2);
[u, x, t] = heat1D(initial, alpha, longueur, 2, nx, 400);
fprintf('Equation de la chaleur (alpha = %g) :\n', alpha);
fprintf('  grille %d points, %d pas de temps\n', numel(x), numel(t));
fprintf('  maximum : %.4f au depart, %.4f a la fin\n', ...
        max(u(:, 1)), max(u(:, end)));
assert(max(u(:, end)) < max(u(:, 1)), 'la chaleur doit s''etaler');
% Le profil s'elargit : sa largeur a mi-hauteur croit.
largeurDe = @(v) sum(v > max(v) / 2) * (x(2) - x(1));
fprintf('  largeur a mi-hauteur : %.4f -> %.4f\n', ...
        largeurDe(u(:, 1)), largeurDe(u(:, end)));
assert(largeurDe(u(:, end)) > largeurDe(u(:, 1)));
% Le maximum decroit de facon monotone : la diffusion ne cree jamais de
% nouveau maximum. C'est le principe du maximum, et c'est ce qui
% distingue cette equation des deux autres.
maxima = max(u, [], 1);
assert(all(diff(maxima) <= 1e-12), ...
       'le principe du maximum interdit toute remontee');
% La grille est interieure : les bords, maintenus a zero, n'y figurent
% pas. Ce qu'on verifie ici est que la solution s'y annule bien en
% s'approchant.
assert(u(1, end) < max(u(:, end)) / 5);
assert(u(end, end) < max(u(:, end)) / 5);
% L'energie totale decroit, puisqu'elle s'echappe par les bords.
energie = sum(u, 1) * (x(2) - x(1));
fprintf('  energie : %.6f -> %.6f\n', energie(1), energie(end));
assert(energie(end) < energie(1));
assert(all(diff(energie) <= 1e-12));

%% 2. L'onde
% La même bosse, mais gouvernée par l'équation des ondes. Elle ne s'étale
% pas : elle se sépare en deux paquets qui partent en sens contraires à
% la vitesse c, et reviennent après réflexion.
c = 1;
[w, xw, tw] = wave1D(initial, c, longueur, 0.3, nx, 600);
fprintf('\nEquation des ondes (c = %g) :\n', c);
fprintf('  maximum : %.4f au depart, %.4f a t = 0.3\n', ...
        max(w(:, 1)), max(w(:, end)));
% Deux paquets d'amplitude moitie, non un paquet etale : le maximum
% tombe pres de la moitie, non vers zero.
assert(max(w(:, end)) > 0.3, 'l''onde ne s''amortit pas comme la chaleur');
% Ils sont partis dans les deux sens : le centre s'est vide.
centre = round(nx / 2);
fprintf('  au centre : %.4f -> %.4f\n', w(centre, 1), w(centre, end));
assert(abs(w(centre, end)) < 0.3 * abs(w(centre, 1)), ...
       'le centre se vide : les paquets sont partis');
% Ils ont parcouru c * t : on les retrouve la ou ils doivent etre.
[~, positionGauche] = max(w(1:centre, end));
distanceParcourue = abs(xw(centre) - xw(positionGauche));
fprintf('  paquet gauche a %.4f du centre (c t = %.4f)\n', ...
        distanceParcourue, c * tw(end));
assert(abs(distanceParcourue - c * tw(end)) < 0.06, ...
       'un paquet parcourt exactement c fois t');

%% 3. Laplace
% Pas de temps du tout : un équilibre. La température en chaque point est
% la moyenne de ses voisines, et c'est tout ce que l'équation dit.
n = 41;
solution = laplace2D(100, 0, 0, 0, n, n);
fprintf('\nEquation de Laplace, bord haut a 100, les trois autres a 0 :\n');
fprintf('  grille %dx%d\n', size(solution, 1), size(solution, 2));
fprintf('  au centre : %.4f\n', solution(round(n / 2), round(n / 2)));
% Le principe du maximum : la solution ne depasse jamais ses bords, et
% n'a aucun extremum a l'interieur.
interieur = solution(2:end-1, 2:end-1);
fprintf('  interieur : de %.4f a %.4f\n', min(interieur(:)), max(interieur(:)));
assert(max(interieur(:)) < 100 + 1e-9);
assert(min(interieur(:)) > -1e-9);
% Chaque point interieur est la moyenne de ses quatre voisins : c'est
% l'equation elle-meme, verifiee sur la solution.
ecart = 0;
for i = 2:(n - 1)
    for j = 2:(n - 1)
        moyenne = (solution(i-1, j) + solution(i+1, j) + ...
                   solution(i, j-1) + solution(i, j+1)) / 4;
        ecart = max(ecart, abs(solution(i, j) - moyenne));
    end
end
fprintf('  ecart a la moyenne des voisins : %.3e\n', ecart);
assert(ecart < 1e-6, 'chaque point est la moyenne de ses voisins');
% La solution est symetrique par rapport a l'axe vertical, puisque le
% probleme l'est.
assert(max(max(abs(solution - fliplr(solution)))) < 1e-9, ...
       'un probleme symetrique a une solution symetrique');

%% 4. Poisson
% Laplace avec un terme source : la solution n'est plus harmonique, elle
% répond à ce qu'on lui impose.
source = @(x, y) ones(size(x));
[p, xp, yp] = poisson2D(source, 31, 31, 1, 1);
fprintf('\nEquation de Poisson, source uniforme :\n');
fprintf('  grille %dx%d, maximum %.6f\n', size(p, 1), size(p, 2), max(p(:)));
% Avec une source positive et des bords a zero, la solution est negative
% partout a l'interieur, ou positive selon la convention de signe : ce
% qui compte est qu'elle ne soit plus nulle.
assert(max(abs(p(:))) > 1e-6, 'la source doit produire une reponse');
% Comme pour la chaleur, la grille rendue est interieure : les bords,
% nuls, n'y figurent pas. La solution y decroit en s'en approchant.
assert(max(abs(p(1, :))) < max(abs(p(:))) / 3);
assert(max(abs(p(end, :))) < max(abs(p(:))) / 3);
assert(max(abs(p(:, 1))) < max(abs(p(:))) / 3);
assert(max(abs(p(:, end))) < max(abs(p(:))) / 3);
% La reponse est symetrique dans les deux directions.
assert(max(max(abs(p - fliplr(p)))) < 1e-9);
assert(max(max(abs(p - flipud(p)))) < 1e-9);
% Le maximum est au centre : c'est la que la source s'accumule le plus
% loin des bords.
[~, indice] = max(abs(p(:)));
[ligne, colonne] = ind2sub(size(p), indice);
fprintf('  extremum a la case (%d,%d), centre attendu (%d,%d)\n', ...
        ligne, colonne, round(size(p, 1) / 2), round(size(p, 2) / 2));
assert(abs(ligne - (size(p, 1) + 1) / 2) <= 1);
assert(abs(colonne - (size(p, 2) + 1) / 2) <= 1);

%% 5. Les éléments finis
% Une autre façon de discrétiser : au lieu d'approcher les dérivées sur
% une grille, on cherche la solution dans un espace de fonctions simples.
% Sur un problème à solution connue, les deux doivent tomber d'accord.
[uf, xf] = fem1D(@(x) ones(size(x)), 1, 40);
% Pour -u'' = 1 sur [0,1] avec u(0) = u(1) = 0, la solution exacte est
% x(1-x)/2.
exacte = xf(:) .* (1 - xf(:)) / 2;
ecartFem = max(abs(uf(:) - exacte));
fprintf('\nElements finis sur -u'''' = 1 :\n');
fprintf('  ecart a la solution exacte x(1-x)/2 : %.3e\n', ecartFem);
assert(ecartFem < 1e-9, ...
       'les elements finis lineaires sont exacts aux noeuds pour ce probleme');
% Les conditions aux bords sont satisfaites exactement.
assert(abs(uf(1)) < 1e-12 && abs(uf(end)) < 1e-12);
% Le maximum est au milieu, et vaut 1/8.
fprintf('  maximum %.10f (exact 0.125)\n', max(uf));
assert(abs(max(uf) - 0.125) < 1e-9);

%% 6. Le solveur general : PDEPE
% Les quatre premieres sections ecrivent leur schema a la main, ce qui les
% rend lisibles mais les enferme dans une equation. PDEPE prend l'equation
% en argument : on lui donne les trois fonctions c, f et s de
%
%     c(x,t,u,u_x) u_t = x^-m (x^m f(x,t,u,u_x))_x + s(x,t,u,u_x)
%
% et il s'occupe du reste. Sur la chaleur, c = 1, f = u_x, s = 0.
chaleurPde = @(x, t, u, dudx) deal(1, dudx, 0);
bordsNuls = @(xl, ul, xr, ur, t) deal(ul, 0, ur, 0);
xp = linspace(0, 1, 41);
tp = linspace(0, 0.1, 6);
solPde = pdepe(0, chaleurPde, @(x) sin(pi * x), bordsNuls, xp, tp);

% sin(pi x) est un mode propre : il ne change pas de forme, il ne fait que
% decroitre en e^{-pi^2 t}. C'est la solution exacte, pour toujours.
exactePde = sin(pi * xp) * exp(-pi^2 * tp(end));
fprintf('\nPDEPE sur la chaleur, mode propre sin(pi x) :\n');
fprintf('  ecart a sin(pi x) e^{-pi^2 t} : %.3e\n', ...
        max(abs(solPde(end, :) - exactePde)));
assert(max(abs(solPde(end, :) - exactePde)) < 5e-4);

% Le meme calcul sur deux fois moins de mailles doit etre quatre fois plus
% faux : le schema est d'ordre deux, et c'est ce qui le definit.
xGros = linspace(0, 1, 21);
solGros = pdepe(0, chaleurPde, @(x) sin(pi * x), bordsNuls, xGros, tp);
ecartGros = max(abs(solGros(end, :) - sin(pi * xGros) * exp(-pi^2 * tp(end))));
ecartFin = max(abs(solPde(end, :) - exactePde));
fprintf('  ordre observe : %.2f (deux attendu)\n', log2(ecartGros / ecartFin));
assert(abs(log2(ecartGros / ecartFin) - 2) < 0.3);

% La geometrie change tout. Avec m = 1 le probleme est cylindrique, avec
% m = 2 spherique : la surface par laquelle la chaleur s'echappe croit
% avec le rayon, donc le centre se refroidit plus vite.
centreQuiRefroidit = @(m) refroidissement(m, chaleurPde);
fprintf('\nLa geometrie decide de la vitesse :\n');
tauxPlan = centreQuiRefroidit(0);
tauxCyl = centreQuiRefroidit(1);
tauxSph = centreQuiRefroidit(2);
fprintf('  plan %.2f, cylindrique %.2f, spherique %.2f\n', ...
        tauxPlan, tauxCyl, tauxSph);
assert(tauxPlan < tauxCyl && tauxCyl < tauxSph);

% PDEVAL interpole entre les noeuds, valeur et derivee ensemble.
[uInterp, duInterp] = pdeval(0, xp, solPde(end, :), 0.3);
fprintf('\nPDEVAL en x = 0.3 : u = %.6f (exact %.6f)\n', ...
        uInterp, sin(pi * 0.3) * exp(-pi^2 * 0.1));
fprintf('                  du/dx = %.6f (exact %.6f)\n', ...
        duInterp, pi * cos(pi * 0.3) * exp(-pi^2 * 0.1));
assert(abs(uInterp - sin(pi * 0.3) * exp(-pi^2 * 0.1)) < 5e-4);
assert(abs(duInterp - pi * cos(pi * 0.3) * exp(-pi^2 * 0.1)) < 5e-3);

%% 7. Un probleme aux limites : BVP4C
% Une equation differentielle dont on ne connait pas tout l'etat d'un
% bout : on ne peut donc pas l'integrer en partant de la. La collocation
% discretise tout l'intervalle a la fois et resout le systeme entier.
%
% y'' + y = 0 avec y(0) = 0 et y(pi/2) = 1 : c'est sin, et rien d'autre.
sol = bvp4c(@(x, y) [y(2); -y(1)], @(ya, yb) [ya(1); yb(1) - 1], ...
            bvpinit(linspace(0, pi/2, 11), [0 1]));
fprintf('\nBVP4C sur y'''' + y = 0, y(0) = 0, y(pi/2) = 1 :\n');
fprintf('  ecart a sin : %.3e sur 11 points\n', ...
        max(abs(sol.y(1, :) - sin(sol.x))));
assert(max(abs(sol.y(1, :) - sin(sol.x))) < 1e-6);
% La derivee aussi est juste : c'est cos, la seconde composante du systeme.
assert(max(abs(sol.y(2, :) - cos(sol.x))) < 1e-5);

% La formule est d'ordre quatre : sur un polynome de degre trois, elle est
% exacte. y'' = 6x avec y(0) = 0 et y(1) = 1 donne x^3.
cubique = bvp4c(@(x, y) [y(2); 6*x], @(ya, yb) [ya(1); yb(1) - 1], ...
                bvpinit(linspace(0, 1, 11), [0 1]));
fprintf('  ecart a x^3 : %.3e — la formule est exacte sur les cubiques\n', ...
        max(abs(cubique.y(1, :) - cubique.x .^ 3)));
assert(max(abs(cubique.y(1, :) - cubique.x .^ 3)) < 1e-8);

% Et sur un probleme non lineaire, que rien de tout cela ne resolvait :
% y'' = 2 y^3 avec y(1) = 1/2 et y(2) = 1/3 a pour solution 1/(x+1).
courbe = bvp4c(@(x, y) [y(2); 2 * y(1)^3], ...
               @(ya, yb) [ya(1) - 1/2; yb(1) - 1/3], ...
               bvpinit(linspace(1, 2, 21), [0.4 -0.2]));
fprintf('  non lineaire y'''' = 2y^3 : ecart a 1/(x+1) = %.3e\n', ...
        max(abs(courbe.y(1, :) - 1 ./ (courbe.x + 1))));
assert(max(abs(courbe.y(1, :) - 1 ./ (courbe.x + 1))) < 1e-6);

fprintf('\nToutes les verifications passent.\n');

function taux = refroidissement(m, equation)
% La vitesse a laquelle le centre se vide, depuis le meme profil initial :
% flux nul au centre par symetrie, temperature nulle au bord.
    r = linspace(0, 1, 21);
    s = pdepe(m, equation, @(r) 1 - r .^ 2, ...
              @(xl, ul, xr, ur, t) deal(0, 1, ur, 0), r, [0 0.05 0.1]);
    taux = -log(s(end, 1) / s(1, 1)) / 0.1;
end
