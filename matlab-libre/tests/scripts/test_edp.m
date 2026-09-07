% test_edp.m — équations aux dérivées partielles et problèmes aux limites.
% On ne compare pas à des valeurs relevées ailleurs : chaque solveur est
% mis face à un problème dont la solution s'écrit, et c'est elle qui juge.
disp('--- edp ---');

chaleur = @(x, t, u, dudx) deal(1, dudx, 0);
bordsNuls = @(xl, ul, xr, ur, t) deal(ul, 0, ur, 0);
centreEtBord = @(xl, ul, xr, ur, t) deal(0, 1, ur, 0);

% ---------------------------------------------------------------- PDEPE
% L'équation de la chaleur u_t = u_xx sur [0,1], bords tenus à zéro. Avec
% sin(pi x) pour condition initiale, la solution est sin(pi x) e^{-pi^2 t}
% pour toujours : le mode propre ne fait que décroître.
x = linspace(0, 1, 41);
t = linspace(0, 0.1, 6);
sol = pdepe(0, chaleur, @(x) sin(pi * x), bordsNuls, x, t);
assert(isequal(size(sol), [numel(t) numel(x)]));
% La condition initiale doit être rendue telle quelle.
assert(max(abs(sol(1, :) - sin(pi * x))) < 1e-12);
for k = 1:numel(t)
    assert(max(abs(sol(k, :) - sin(pi * x) * exp(-pi^2 * t(k)))) < 5e-4);
end

% Le schéma est d'ordre deux en espace : doubler les mailles divise
% l'écart par quatre. C'est la propriété qui définit la discrétisation, et
% elle se vérifie sans rien connaître de la réponse.
e1 = ecartChaleur(11);
e2 = ecartChaleur(21);
e3 = ecartChaleur(41);
assert(e3 < e2 && e2 < e1);
assert(abs(e1 / e2 - 4) < 1);
assert(abs(e2 / e3 - 4) < 1);

% Flux nul aux deux bouts : rien n'entre, rien ne sort, donc l'intégrale
% de u se conserve. C'est ce que les volumes finis garantissent
% exactement, à l'erreur du solveur en temps près — une différence finie
% centrée ne le ferait pas.
fluxNul = @(xl, ul, xr, ur, t) deal(0, 1, 0, 1);
solN = pdepe(0, chaleur, @(x) 1 + cos(pi * x), fluxNul, x, t);
assert(abs(trapz(x, solN(end, :)) - trapz(x, solN(1, :))) < 1e-6);
assert(max(abs(solN(end, :) - (1 + cos(pi * x) * exp(-pi^2 * 0.1)))) < 5e-4);

% Cylindrique : le mode propre est J0(j r), j le premier zéro de J0, et il
% décroît en e^{-j^2 t}. C'est la solution exacte, pas une approximation,
% et l'ordre deux s'y lit comme en plan.
j0 = fzero(@(z) besselj(0, z), 2.4);
cyl1 = ecartMode(1, 21, @(r) besselj(0, j0 * r), j0^2);
cyl2 = ecartMode(1, 41, @(r) besselj(0, j0 * r), j0^2);
assert(cyl2 < 2e-4);
assert(abs(cyl1 / cyl2 - 4) < 1);

% Sphérique : le mode propre est sin(pi r)/r, prolongé par pi au centre,
% et il décroît en e^{-pi^2 t}.
sinc = @(r) (r == 0) * pi + (r ~= 0) .* sin(pi * r) ./ (r + (r == 0));
sph1 = ecartMode(2, 21, sinc, pi^2);
sph2 = ecartMode(2, 41, sinc, pi^2);
assert(sph2 < 1e-3);
assert(abs(sph1 / sph2 - 4) < 1);

% Les trois géométries se classent : plus la dimension est grande, plus la
% surface par laquelle la chaleur s'échappe est vaste, et plus vite le
% centre se refroidit. C'est la seule chose que le facteur x^m dit.
tauxPlan = tauxRefroidissement(0);
tauxCyl  = tauxRefroidissement(1);
tauxSph  = tauxRefroidissement(2);
assert(tauxPlan < tauxCyl && tauxCyl < tauxSph);

% Un terme source constant chauffe : l'état stationnaire de u_t = u_xx + 1
% avec des bords nuls est x(1-x)/2, dont le maximum vaut 1/8.
source = @(x, t, u, dudx) deal(1, dudx, 1);
solSrc = pdepe(0, source, @(x) zeros(size(x)), bordsNuls, x, linspace(0, 3, 4));
assert(abs(max(solSrc(end, :)) - 0.125) < 2e-3);

% Deux composantes, chacune son mode propre et son rythme.
deux = @(x, t, u, dudx) deal([1; 1], dudx, [0; 0]);
bordsDeux = @(xl, ul, xr, ur, t) deal(ul, [0; 0], ur, [0; 0]);
solD = pdepe(0, deux, @(x) [sin(pi * x); sin(2 * pi * x)], bordsDeux, x, t);
assert(isequal(size(solD), [numel(t) numel(x) 2]));
assert(max(abs(solD(end, :, 1) - sin(pi * x) * exp(-pi^2 * 0.1))) < 5e-4);
assert(max(abs(solD(end, :, 2) - sin(2 * pi * x) * exp(-4 * pi^2 * 0.1))) < 2e-3);

% Ce qui ne peut pas être résolu est refusé, avec la raison : une
% géométrie qui n'existe pas, un maillage qui recule, un rayon négatif.
refuse = @(f) verifierRefus(f);
assert(refuse(@() pdepe(3, chaleur, @(x) x, bordsNuls, linspace(0,1,5), [0 1 2])));
assert(refuse(@() pdepe(0, chaleur, @(x) x, bordsNuls, [0 1], [0 1 2])));
assert(refuse(@() pdepe(0, chaleur, @(x) x, bordsNuls, linspace(0,1,5), [0 1])));
assert(refuse(@() pdepe(0, chaleur, @(x) x, bordsNuls, [0 0.5 0.5 1], [0 1 2])));
assert(refuse(@() pdepe(1, chaleur, @(x) x, bordsNuls, linspace(-1,1,5), [0 1 2])));

% ---------------------------------------------------------------- PDEVAL
xm = linspace(0, 1, 21);
um = sin(pi * xm);
[v, dv] = pdeval(0, xm, um, 0.25);
assert(abs(v - sin(pi * 0.25)) < 1e-3);
assert(abs(dv - pi * cos(pi * 0.25)) < 1e-2);
% Sur un nœud, l'interpolation rend la valeur du nœud, exactement.
assert(max(abs(pdeval(0, xm, um, xm) - um)) < 1e-14);
% L'interpolation est cubique d'Hermite avec des pentes prises sur la
% parabole des trois points voisins : elle est donc exacte sur les
% paraboles, valeurs et dérivées, jusqu'aux deux bouts du maillage.
q = @(z) 2 * z.^2 - 3 * z + 1;
essais = [0 0.07 0.41 0.93 1];
[vq, dq] = pdeval(0, xm, q(xm), essais);
assert(max(abs(vq - q(essais))) < 1e-13);
assert(max(abs(dq - (4 * essais - 3))) < 1e-12);
% Et sur un maillage inégal aussi : la formule des pentes ne suppose pas
% l'espacement constant.
xn = [0 0.1 0.35 0.4 0.8 1];
[vn, dn] = pdeval(0, xn, q(xn), [0 0.2 0.6 1]);
assert(max(abs(vn - q([0 0.2 0.6 1]))) < 1e-13);
assert(max(abs(dn - (4 * [0 0.2 0.6 1] - 3))) < 1e-12);
% La dérivée rendue est celle de la fonction rendue : une différence finie
% sur UOUT doit retrouver DUOUTDX.
pas = 1e-6;
[uA, dA] = pdeval(0, xm, um, 0.37);
uB = pdeval(0, xm, um, 0.37 + pas);
assert(abs((uB - uA) / pas - dA) < 1e-4);
% La forme de la sortie suit celle de la demande.
assert(isequal(size(pdeval(0, xm, um, [0.1 0.2 0.3])), [1 3]));
assert(isequal(size(pdeval(0, xm, um, [0.1; 0.2])), [2 1]));

% ---------------------------------------------------------------- BVP4C
% y'' + y = 0 avec y(0) = 0 et y(pi/2) = 1 : c'est sin, et rien d'autre.
oscillateur = @(x, y) [y(2); -y(1)];
bornesSin = @(ya, yb) [ya(1); yb(1) - 1];
sol1 = bvp4c(oscillateur, bornesSin, bvpinit(linspace(0, pi/2, 11), [0 1]));
assert(max(abs(sol1.y(1, :) - sin(sol1.x))) < 1e-6);
assert(max(abs(sol1.y(2, :) - cos(sol1.x))) < 1e-5);
% Les conditions aux limites sont tenues, pas seulement approchées.
assert(abs(sol1.y(1, 1)) < 1e-9);
assert(abs(sol1.y(1, end) - 1) < 1e-9);

% y'' = 6x avec y(0) = 0, y(1) = 1 : la solution est x^3. La formule est
% d'ordre quatre, donc elle intègre un polynôme de degré trois exactement.
cubique = bvp4c(@(x, y) [y(2); 6*x], @(ya, yb) [ya(1); yb(1) - 1], ...
                bvpinit(linspace(0, 1, 11), [0 1]));
assert(max(abs(cubique.y(1, :) - cubique.x.^3)) < 1e-8);

% Non linéaire : y'' = 2y^3 avec y(1) = 1/2 et y(2) = 1/3, dont la
% solution est 1/(x+1).
nonLineaire = bvp4c(@(x, y) [y(2); 2 * y(1)^3], ...
                    @(ya, yb) [ya(1) - 1/2; yb(1) - 1/3], ...
                    bvpinit(linspace(1, 2, 21), [0.4 -0.2]));
assert(max(abs(nonLineaire.y(1, :) - 1 ./ (nonLineaire.x + 1))) < 1e-6);

% Ordre quatre : diviser le pas par deux divise l'écart par seize.
e11 = ecartBvp(6);
e21 = ecartBvp(11);
e41 = ecartBvp(21);
assert(e41 < e21 && e21 < e11);
assert(e11 / e21 > 8 && e21 / e41 > 8);

% Le maillage rendu est celui donné, et la solution y est rangée en colonnes.
assert(max(abs(sol1.x - linspace(0, pi/2, 11))) < 1e-14);
assert(isequal(size(sol1.y), [2 11]));
assert(strcmp(sol1.solver, 'bvp4c'));

% ------------------------------------------------------- BVPINIT, BVPSET
init = bvpinit(linspace(0, 1, 5), [1 2]);
assert(max(abs(init.x - linspace(0, 1, 5))) < 1e-14);
assert(isequal(size(init.y), [2 5]));
assert(all(init.y(1, :) == 1) && all(init.y(2, :) == 2));
% Une devinette qui varie : la fonction est évaluée en chaque point.
initFn = bvpinit(linspace(0, 1, 5), @(x) [x; 1 - x]);
assert(max(abs(initFn.y(1, :) - linspace(0, 1, 5))) < 1e-12);
assert(max(abs(initFn.y(2, :) - (1 - linspace(0, 1, 5)))) < 1e-12);

opt = bvpset('RelTol', 1e-8, 'NMax', 30);
assert(abs(opt.RelTol - 1e-8) < 1e-20);
assert(opt.NMax == 30);
% Un réglage plus lâche doit rester bon, sinon il ne réglait rien.
solLache = bvp4c(oscillateur, bornesSin, ...
                 bvpinit(linspace(0, pi/2, 11), [0 1]), bvpset('RelTol', 1e-4));
assert(max(abs(solLache.y(1, :) - sin(solLache.x))) < 1e-4);

disp('edp : toutes les verifications passent');

function ok = verifierRefus(f)
% Vrai si l'appel leve une erreur de PDEPE, faux s'il passe.
    ok = false;
    try
        f();
    catch e
        ok = ~isempty(strfind(e.identifier, 'pdepe'));
    end
end

function e = ecartChaleur(n)
% L'ecart au mode propre exact sin(pi x) e^{-pi^2 t}, sur n points.
    x = linspace(0, 1, n);
    s = pdepe(0, @(x, t, u, dudx) deal(1, dudx, 0), @(x) sin(pi * x), ...
              @(xl, ul, xr, ur, t) deal(ul, 0, ur, 0), x, [0 0.05 0.1]);
    e = max(abs(s(end, :) - sin(pi * x) * exp(-pi^2 * 0.1)));
end

function taux = tauxRefroidissement(m)
% La vitesse a laquelle le centre se vide, en geometrie plane,
% cylindrique ou spherique, depuis le meme profil initial.
    r = linspace(0, 1, 21);
    s = pdepe(m, @(x, t, u, dudx) deal(1, dudx, 0), @(r) 1 - r.^2, ...
              @(xl, ul, xr, ur, t) deal(0, 1, ur, 0), r, [0 0.05 0.1]);
    taux = -log(s(end, 1) / s(1, 1)) / 0.1;
end

function e = ecartMode(m, n, mode, lambda)
% L'ecart au mode propre exact d'une geometrie donnee : le profil ne
% change pas de forme, il ne fait que decroitre en e^{-lambda t}.
    r = linspace(0, 1, n);
    s = pdepe(m, @(x, t, u, dudx) deal(1, dudx, 0), mode, ...
              @(xl, ul, xr, ur, t) deal(0, 1, ur, 0), r, [0 0.05 0.1]);
    e = max(abs(s(end, :) - mode(r) * exp(-lambda * 0.1)));
end

function e = ecartBvp(n)
% L'ecart a sin sur un maillage de n points.
    s = bvp4c(@(x, y) [y(2); -y(1)], @(ya, yb) [ya(1); yb(1) - 1], ...
              bvpinit(linspace(0, pi/2, n), [0 1]));
    e = max(abs(s.y(1, :) - sin(s.x)));
end
