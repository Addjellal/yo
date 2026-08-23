% test_domaines.m — communications, ondelettes, logique floue.
% Les références sont exactes : valeurs connues de la fonction Q,
% aller-retour de modulations, correction d'une erreur par un code de
% Hamming, identités des transformées en ondelettes, valeurs remarquables
% des fonctions d'appartenance.
disp('--- domaines ---');

%% ---------------------------------------------------- communications
assert(abs(qfunc(0) - 0.5) < 1e-12);
assert(abs(qfunc(1) - 0.15865525393146) < 1e-12);
assert(abs(qfunc(-1) - (1 - qfunc(1))) < 1e-12);
assert(abs(qfuncinv(0.5)) < 1e-12);
assert(abs(qfuncinv(qfunc(1.3)) - 1.3) < 1e-9);

% DPSK binaire : la phase bascule à chaque 1, reste à chaque 0.
assert(max(abs(dpskmod([0 1 0], 2)' - [1 -1 -1])) < 1e-12);
% Aller-retour sur quatre phases.
symboles = [0 1 2 3 1 0];
assert(isequal(dpskdemod(dpskmod(symboles, 4), 4)', symboles));

% FSK : la démodulation par corrélation retrouve les symboles.
assert(isequal(fskdemod(fskmod([0 1 1 0], 2, 100, 8, 1000), 2, 100, 8, 1000)', [0 1 1 0]));
assert(isequal(fskdemod(fskmod([0 1 2 3], 4, 100, 16, 1000), 4, 100, 16, 1000)', [0 1 2 3]));

% Hamming (7,4) : les dimensions, puis la correction d'une erreur simple
% à chaque position possible.
[H, G, n, k] = hammgen(3);
assert(n == 7 && k == 4);
assert(isequal(size(H), [3 7]));
assert(isequal(size(G), [4 7]));
% G*H' doit être nul modulo 2 : tout mot de code a un syndrome nul.
assert(all(all(mod(G * H', 2) == 0)));

message = [1 0 1 1];
code = encode(message, 7, 4, 'hamming/fmt');
assert(numel(code) == 7);
assert(isequal(decode(code, 7, 4, 'hamming/fmt'), message));
for position = 1:7
    abime = code;
    abime(position) = 1 - abime(position);
    assert(isequal(decode(abime, 7, 4, 'hamming/fmt'), message));
end

%% -------------------------------------------------------- ondelettes
% Niveau maximal : floor(log2(L/(Lf-1))).
assert(wmaxlev(64, 'db2') == 4);
assert(wmaxlev(8, 'db1') == 3);
assert(wmaxlev(2, 'db1') == 1);

[c, l] = wavedec(1:8, 2, 'db1');
assert(numel(detcoef(c, l, 1)) == 4);
assert(numel(detcoef(c, l, 2)) == 2);
assert(numel(appcoef(c, l, 'db1')) == 2);
% Les détails d'un signal affine sont nuls au premier niveau, à la
% normalisation de Haar près : une rampe n'a pas de rupture.
d1 = detcoef(c, l, 1);
assert(max(abs(d1 - d1(1))) < 1e-12);

% Transformée bidimensionnelle : une image constante n'a que de
% l'approximation.
[a, h, v, d] = dwt2(ones(4), 'db1');
assert(isequal(size(a), [2 2]));
assert(max(abs(a(:) - 2)) < 1e-12);
assert(max(abs(h(:))) < 1e-12);
assert(max(abs(v(:))) < 1e-12);
assert(max(abs(d(:))) < 1e-12);

% Aller-retour exact sur une image quelconque.
x = magic(4);
[a2, h2, v2, d2] = dwt2(x, 'db1');
assert(max(max(abs(idwt2(a2, h2, v2, d2, 'db1') - x))) < 1e-10);

% Mise à l'échelle des indices de couleur.
assert(isequal(wcodemat([0 1], 4), [1 4]));
assert(isequal(wcodemat([5 5], 4), [1 1]));

%% ------------------------------------------------------ logique floue
% Z décroît de 1 à 0, S est son complément, et les deux valent 1/2 au
% milieu de l'intervalle.
assert(abs(zmf(0, [2 8]) - 1) < 1e-12);
assert(abs(zmf(10, [2 8])) < 1e-12);
assert(abs(zmf(5, [2 8]) - 0.5) < 1e-12);
assert(abs(smf(5, [2 8]) - 0.5) < 1e-12);
assert(abs(smf(10, [2 8]) - 1) < 1e-12);
assert(abs(zmf(4, [2 8]) + smf(4, [2 8]) - 1) < 1e-12);

% Pi vaut 1 sur le plateau, 0 en dehors.
assert(abs(pimf(5, [1 4 6 9]) - 1) < 1e-12);
assert(abs(pimf(0, [1 4 6 9])) < 1e-12);
assert(abs(pimf(10, [1 4 6 9])) < 1e-12);

% Différence et produit de sigmoïdes : proches de 1 au centre.
assert(dsigmf(0, [5 -2 5 2]) > 0.99);
assert(psigmf(0, [5 -2 -5 2]) > 0.99);

% Gaussienne à plateau : 1 entre les deux centres.
assert(abs(gauss2mf(5, [1 3 1 7]) - 1) < 1e-12);
assert(gauss2mf(0, [1 3 1 7]) < 0.02);

% Les fonctions d'appartenance restent entre 0 et 1 sur tout l'intervalle.
grille = linspace(-5, 15, 200);
for f = {@(v) zmf(v, [2 8]), @(v) smf(v, [2 8]), @(v) pimf(v, [1 4 6 9]), ...
         @(v) gauss2mf(v, [1 3 1 7])}
    valeurs = f{1}(grille);
    assert(all(valeurs >= -1e-12) && all(valeurs <= 1 + 1e-12));
end

disp('domaines : toutes les verifications passent');
