% test_robuste.m — norme H-infini, modèle augmenté, synthèse H-infini.
%
% La synthèse H-infini ne se vérifie pas en comparant des nombres à une
% table : elle se vérifie par ce qu'elle promet. Un correcteur H-infini
% doit stabiliser la boucle et tenir le gain qu'il annonce ; et le gain
% annoncé doit être proche du meilleur possible. Chaque contrôle ci-dessous
% mesure l'une de ces trois promesses, par un chemin indépendant du calcul
% qui les produit.
disp('--- robuste ---');

%% ------------------------------------------------------ la norme H-infini
% La norme exacte vient de la matrice hamiltonienne ; un balayage très fin
% doit trouver la même chose, par en dessous.
resonant = tf(1, [1 0.1 1]);
[g, w] = hinfnorm(resonant);
balayage = max(bode(resonant, logspace(-2, 2, 200000).'));
assert(abs(g - balayage) / balayage < 1e-4);
assert(abs(w - 1 / sqrt(1 - 0.1^2 / 2)) < 1e-2);   % la pulsation de résonance

% Un premier ordre : le gain le plus fort est en zéro.
assert(abs(hinfnorm(tf(1, [1 1])) - 1) < 1e-5);
assert(abs(hinfnorm(tf(3, [1 2])) - 1.5) < 1e-5);

% Un modèle à plusieurs voies : la plus grande valeur singulière.
mimo = ss(blkdiag(-1, -2), eye(2), eye(2), [0.5 0; 0 0.25]);
assert(abs(hinfnorm(mimo) - 1.5) < 1e-4);
assert(abs(hinfnorm(mimo) - max(max(sigma(mimo, logspace(-3, 3, 20000))))) < 1e-4);

% Un modèle instable n'a pas de norme.
assert(isinf(hinfnorm(ss(1, 1, 1, 0))));

%% ------------------------------------------------- le modèle augmenté
% AUGW doit rendre exactement [W1 -W1G ; 0 W2 ; I -G], ce qu'on vérifie
% voie par voie sur la réponse fréquentielle.
G = tf(2, [1 1]);
W1 = tf(10, [1 0.1]);
W2 = 0.5;
P = augw(G, W1, W2, []);
assert(isequal(size(P), [3 2]));
for p = [0.05 1 30]
    reponse = freqresp(P, p);
    g = freqresp(G, p);
    w1 = freqresp(ss(W1), p);
    attendu = [w1, -w1 * g; 0, W2; 1, -g];
    assert(max(max(abs(reponse - attendu))) < 1e-9);
end
% Le modèle est assemblé sans copie inutile : G n'y figure qu'une fois.
assert(order(P) == order(ss(G)) + order(ss(W1)));
% W3 pèse sur la sortie, et ajoute sa ligne.
P3 = augw(G, W1, W2, tf(1, [1 100]));
assert(isequal(size(P3), [4 2]));
for p = [0.05 1 30]
    reponse = freqresp(P3, p);
    g = freqresp(G, p);
    w3 = freqresp(ss(tf(1, [1 100])), p);
    assert(abs(reponse(3, 2) - w3 * g) < 1e-9);
    assert(abs(reponse(3, 1)) < 1e-12);
end

%% --------------------------------------------- ce que promet la synthèse
% Un problème minuscule, dont on peut tout vérifier : x' = -x + w + u,
% z = [x ; u], y = x + w.
P = ss(-1, [1 1], [1; 0; 1], [0 0; 0 1; 1 0]);
[K, CL, gamma] = hinfsyn(P, 1, 1);

% Première promesse : la boucle fermée est stable.
assert(max(real(pole(CL))) < 0);
% Deuxième : elle tient le gain annoncé.
assert(abs(hinfnorm(CL) - gamma) / gamma < 1e-3);
% Troisième : ce gain est un minimum local. Un correcteur voisin fait
% moins bien — on le vérifie sur vingt perturbations tirées au hasard.
rand('seed', 7);
Kss = ss(K);
pire = gamma;
for essai = 1:20
    bruit = @(M) M .* (1 + 0.05 * (2 * rand(size(M)) - 1));
    voisin = ss(bruit(Kss.A), bruit(Kss.B), bruit(Kss.C), Kss.D);
    boucle = lft(P, voisin);
    if max(real(pole(boucle))) < 0
        pire = min(pire, hinfnorm(boucle));
    end
end
assert(pire >= gamma * (1 - 1e-3));

% Le correcteur central tient sa borne à tout GAMMA faisable, non
% seulement à l'optimum : c'est la promesse du théorème.
for essai = [10 3 1.5 1.1]
    [Kg, CLg] = hinfsyn(P, 1, 1, 'GMIN', essai * 0.999, 'GMAX', essai, ...
                        'TOLGAM', 1e-9);
    assert(max(real(pole(CLg))) < 0);
    assert(hinfnorm(CLg) <= essai);
end

%% ------------------------------------------------ la sensibilité mixte
% MIXSYN sur un modèle d'ordre trois, dont deux pôles confondus : le
% solveur de Riccati doit tenir le coup — les vecteurs propres seuls ne
% suffisent pas.
G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
[K, CL, gamma] = mixsyn(G, tf(10, [1 0.1]), 0.1, []);
assert(order(ss(K)) == order(ss(G)) + 1);
assert(max(real(pole(CL))) < 0);
assert(abs(hinfnorm(CL) - gamma) / gamma < 1e-3);
% La boucle réelle, refermée à la main, est stable elle aussi.
boucle = feedback(series(K, ss(G)), 1);
assert(max(real(pole(boucle))) < 0);
% Et la sensibilité pondérée est bien ce que la synthèse a minimisé.
S = feedback(ss(1), series(K, ss(G)));
assert(abs(hinfnorm(ss(tf(10, [1 0.1])) * S) - gamma) / gamma < 1e-2);

% Un modèle augmenté dont D11 n'est pas nul est refusé, avec la raison.
refus = '';
try
    hinfsyn(augw(G, tf([0.1 1], [1 1e-5]), 0.1, []), 1, 1);
catch err
    refus = err.identifier;
end
assert(strcmp(refus, 'Robust:design:hinfsyn:D11'));

%% ------------------------------------------ l'équation de Riccati elle-même
% La solution rendue doit annuler l'équation et stabiliser.
A = [0 1; -2 -3];
B = [0; 1];
Q = eye(2);
[X, ok] = matlibre_riccati(A, -B * B', Q);
assert(ok);
assert(norm(A' * X + X * A - X * (B * B') * X + Q, 'fro') < 1e-9);
assert(max(real(eig(A - B * B' * X))) < 0);
% Un pôle double ne met pas le solveur en défaut : c'est le cas où les
% vecteurs propres manquent.
Ad = [-2 1; 0 -2];
[Xd, okd] = matlibre_riccati(Ad, -B * B', Q);
assert(okd);
assert(norm(Ad' * Xd + Xd * Ad - Xd * (B * B') * Xd + Q, 'fro') < 1e-9);

disp('robuste : toutes les verifications passent');
