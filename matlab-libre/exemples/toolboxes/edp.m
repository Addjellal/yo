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

fprintf('\nToutes les verifications passent.\n');
