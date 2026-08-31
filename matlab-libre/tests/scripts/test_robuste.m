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

%% ------------------------------- une ponderation bipropre : D11 non nul
% Une ponderation bipropre donne un chemin direct des perturbations vers
% les signaux ponderes. Les formules du correcteur central demandent D11
% nul ; le decalage de boucle y ramene exactement, a chaque gamma. Le
% controle est le meme : la boucle est stable et tient le gain annonce.
Pbipropre = augw(G, tf([0.1 1], [1 1e-5]), 0.1, []);
D11essai = Pbipropre.D(1:2, 1);
assert(max(abs(D11essai)) > 0.05);          % le terme direct est bien la
[Kb, CLb, gammaB] = hinfsyn(Pbipropre, 1, 1);
assert(max(real(pole(CLb))) < 0);
assert(abs(hinfnorm(CLb) - gammaB) / gammaB < 1e-3);
% Et a tout gamma faisable, non seulement a l'optimum.
for essai = [10 2 0.5]
    [~, CLg] = hinfsyn(Pbipropre, 1, 1, 'GMIN', essai * 0.999, 'GMAX', essai, ...
                       'TOLGAM', 1e-9);
    assert(max(real(pole(CLg))) < 0);
    assert(hinfnorm(CLg) <= essai);
end
% Le gain du terme direct borne ce qu'on peut demander : en deca, il n'y a
% pas de solution, et la fonction le dit au lieu de rendre n'importe quoi.
sousLeTermeDirect = '';
try
    hinfsyn(Pbipropre, 1, 1, 'GMIN', 0, 'GMAX', max(svd(D11essai)) / 2);
catch err
    sousLeTermeDirect = err.identifier;
end
assert(strcmp(sousLeTermeDirect, 'Robust:design:hinfsyn:NoSolution'));

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

%% ------------------------------------------------------------- sysic
% L'interconnexion decrite par des variables doit donner exactement le
% schema qu'on ecrirait a la main.
G = ss(tf(2, [1 1]));
K = ss(tf(10, [1 0]));
W1 = ss(tf(1, [1 0.1]));
W2 = ss(0.5);
systemnames  = 'G K W1 W2';
inputvar     = '[ref; u]';
outputvar    = '[W1; W2; G]';
input_to_G   = '[u]';
input_to_K   = '[ref - G]';
input_to_W1  = '[ref - G]';
input_to_W2  = '[u]';
cleanupsysic = 'yes';
P = sysic;
assert(isequal(size(P), [3 2]));
assert(order(P) == order(G) + order(K) + order(W1));
for p = [0.1 1 10]
    g = freqresp(G, p);
    w1 = freqresp(W1, p);
    attendu = [w1, -w1 * g; 0, 0.5; 0, g];
    assert(max(max(abs(freqresp(P, p) - attendu))) < 1e-9);
end
% « cleanupsysic » efface les variables du montage.
assert(exist('input_to_G', 'var') == 0);
assert(exist('systemnames', 'var') == 0);

% Les gains, les indices de voie et les entrees en groupe.
GM = ss(-eye(2), eye(2), eye(2), zeros(2));
systemnames = 'GM';
inputvar    = '[d{2}]';
outputvar   = '[2*GM(1) - GM(2); d(1)]';
input_to_GM = '[d]';
Q = sysic;
assert(isequal(size(Q), [2 2]));
for p = [0.2 3]
    g = freqresp(GM, p);
    attendu = [2 * g(1, 1) - g(2, 1), 2 * g(1, 2) - g(2, 2); 1, 0];
    assert(max(max(abs(freqresp(Q, p) - attendu))) < 1e-9);
end
clear systemnames inputvar outputvar input_to_GM

% Un bloc oublie est signale, avec son nom.
systemnames = 'GM';
inputvar    = '[d]';
outputvar   = '[GM]';
manque = '';
try
    sysic;
catch err
    manque = err.identifier;
end
assert(strcmp(manque, 'Robust:sysic:Missing'));
clear systemnames inputvar outputvar

% ------------------------------------------------------ reduction de modele
% Trois modes bien separes : la troncature equilibree doit garder le plus
% lent et respecter la borne de Glover.
Gtrois = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
[GbEquilibre, valeursHankel] = sysbal(Gtrois);
assert(max(max(abs(gram(GbEquilibre, 'c') - gram(GbEquilibre, 'o')))) < 1e-12);
% Les valeurs de Hankel se calculent a la main : ce sont les valeurs
% propres de la matrice 1/(pi+pj), les deux grammiens etant egaux.
poles = [1 10 100];
W = zeros(3);
for i = 1:3
    for j = 1:3
        W(i, j) = 1 / (poles(i) + poles(j));
    end
end
assert(max(abs(sort(valeursHankel, 'descend') - sort(eig(W), 'descend'))) < 1e-12);

[Greduit, infoReduction] = balancmr(Gtrois, 1);
assert(infoReduction.n == 1);
assert(abs(infoReduction.ErrorBound - 2 * sum(valeursHankel(2:3))) < 1e-12);
assert(hinfnorm(Gtrois - Greduit) <= infoReduction.ErrorBound + 1e-9);
% La borne choisit l'ordre.
[~, infoBorne] = balancmr(Gtrois, [], 'MaxError', 0.01);
assert(infoBorne.n == 2 && infoBorne.ErrorBound <= 0.01);
% HANKELMR annonce l'erreur de Hankel : c'est la valeur suivante.
[~, infoHankel] = hankelmr(Gtrois, 2);
assert(abs(infoHankel.HankelError - valeursHankel(3)) < 1e-12);
[~, infoSchur] = schurmr(Gtrois, 2);
assert(infoSchur.n == 2);
assert(size(ss(reduce(Gtrois, 2)).A, 1) == 2);
assert(size(ss(reduce(Gtrois, 2, 'Algorithm', 'hankel')).A, 1) == 2);
% BSTMR demande un terme direct inversible.
[~, infoStochastique] = bstmr(ss(Gtrois.A, Gtrois.B, Gtrois.C, 1), 2);
assert(infoStochastique.n == 2 && infoStochastique.ErrorBound > 0);

% Separation des modes : la somme des deux morceaux redonne le modele.
[lent, rapide] = slowfast(Gtrois, 1);
assert(abs(max(real(pole(lent))) + 1) < 1e-9);
assert(hinfnorm(Gtrois - (lent + rapide)) < 1e-8);
Ginstable = ss([1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
[partieStable, partieInstable] = stabproj(Ginstable);
assert(abs(max(real(pole(partieInstable))) - 1) < 1e-9);
assert(max(real(pole(partieStable))) < 0);
% La forme modale garde la relation entree-sortie.
Gcomplexe = ss([-1 2; -2 -1], [1; 0], [1 1], 0);
Gmodal = modreal(Gcomplexe);
assert(hinfnorm(Gcomplexe - Gmodal) < 1e-9);
% STRANS permute les etats sans rien changer d'autre.
Gdiagonal = ss(diag([-1 -10 -100]), [1; 1; 1], [1 1 1], 0);
Gpermute = strans(Gdiagonal, [3 1 2]);
assert(max(abs(diag(Gpermute.A)' - [-100 -1 -10])) < 1e-12);
assert(hinfnorm(Gdiagonal - Gpermute) < 1e-9);

% ------------------------------------------ facteurs premiers normalises
% La factorisation vaut pour un modele instable, et elle est normalisee :
% on le verifie sur l'axe imaginaire, la norme du produit valant l'infini
% parce que le systeme conjugue est antistable.
for essai = 1:3
    switch essai
        case 1, Gessai = ss(1, 1, 1, 0);
        case 2, Gessai = ss(tf([1 2], [1 3 2]));
        case 3, Gessai = ss([-1 1; 0 2], [0; 1], [1 1], 0.5);
    end
    [M, N] = lncf(Gessai);
    assert(max(real(pole(M))) < 0);
    pulsations = logspace(-3, 3, 30);
    Hm = freqresp(M, pulsations);
    Hn = freqresp(N, pulsations);
    pireEcart = 0;
    for k = 1:numel(pulsations)
        pireEcart = max(pireEcart, ...
                        abs(Hm(k) * conj(Hm(k)) + Hn(k) * conj(Hn(k)) - 1));
    end
    assert(pireEcart < 1e-10);
end
% NCFMR reduit un modele instable, ce qu'aucune autre methode ne fait.
[GinstableReduit, infoNcf] = ncfmr(Ginstable, 2);
assert(size(ss(GinstableReduit).A, 1) == 2);
% Le mode instable est garde, a la precision de la troncature pres :
% la reduction des facteurs premiers ne conserve pas les poles exactement.
assert(abs(max(real(pole(GinstableReduit))) - 1) < 1e-2);
assert(infoNcf.n == 2);

% La marge des facteurs premiers, et la distance de graphe qui va avec.
Pinstable = ss(tf(1, [1 -1]));
Cstabilisant = ss(tf([2 1], [1 0]));
[margeNcf, pulsationNcf] = ncfmargin(Pinstable, Cstabilisant);
assert(margeNcf > 0.2 && margeNcf < 1);
assert(pulsationNcf > 0);
assert(gapmetric(ss(tf(1, [1 1])), ss(tf(1, [1 1.1]))) < 0.1);
assert(abs(gapmetric(ss(tf(1, [1 1])), ss(tf(1, [1 -1]))) - 1) < 1e-6);
assert(gapmetric(ss(tf(1, [1 1])), ss(tf(1, [1 1]))) < 1e-9);

% NCFSYN atteint la marge optimale, qui est connue en forme close.
for essai = 1:2
    if essai == 1
        Gsyn = ss(tf(1, [1 -1]));
    else
        Gsyn = ss(tf(1, [1 1]));
    end
    [Ksyn, ~, margeAtteinte, infoSyn] = ncfsyn(Gsyn);
    assert(margeAtteinte > 0.98 * infoSyn.emax);
    assert(margeAtteinte <= infoSyn.emax + 1e-6);
    boucleSyn = loopsens(Gsyn, Ksyn);
    assert(boucleSyn.Stable);
    assert(abs(ncfmargin(Gsyn, Ksyn) - margeAtteinte) < 1e-6);
end

% --------------------------------------------------------------- synthese
% La norme H2 se calcule par les grammiens : exacte, et valable en
% multivariable.
assert(abs(h2norm(tf(1, [1 1])) - sqrt(0.5)) < 1e-12);
Gdeux = [tf(1, [1 1]), tf(0, 1); tf(0, 1), tf(2, [1 2])];
assert(abs(h2norm(Gdeux) - sqrt(1.5)) < 1e-12);
assert(isinf(h2norm(tf(1, [1 -1]))));        % instable
assert(isinf(h2norm(tf([1 1], [1 2]))));     % terme direct non nul

Gsynthese = ss(tf(1, [1 1]));
Paugmente = augw(Gsynthese, tf(1, [1 0.1]), 0.1, []);
[Kdeux, CLdeux, normeDeux] = h2syn(Paugmente, 1, 1);
assert(abs(h2norm(CLdeux) - normeDeux) < 1e-9);
assert(max(real(pole(CLdeux))) < 0);
% Le correcteur H2 fait mieux que le correcteur H-infini, en norme H2.
[~, CLinfini] = hinfsyn(Paugmente, 1, 1);
assert(normeDeux <= h2norm(CLinfini) + 1e-9);
[~, ~, normesMixtes] = h2hinfsyn(Paugmente, 1, 1, 'HINFMAX', 5);
assert(numel(normesMixtes) == 2 && normesMixtes(2) <= 5);

% La transformation de secteur ramene un secteur [a b] au secteur [-1 1].
Gsecteur = ss(tf(1, [1 2 1]));
% Pour [0 2] : GT = G/(1+G) = 1/(s^2+2s+2), dont le sommet vaut 1/2.
assert(abs(hinfnorm(sectf(Gsecteur, [0 2])) - 0.5) < 1e-6);
assert(popov(Gsecteur, [0 10]) == 1);
assert(popov(ss(tf(-1, [1 1])), [0 10]) == 0);     % gain statique negatif
assert(popov(ss(tf(-1, [1 1])), [0 0.5]) == 1);

% ------------------------------------------------- ponderations et filtres
% MAKEWEIGHT respecte les trois nombres qu'on lui donne.
W = makeweight(0.01, 10, 2);
assert(abs(dcgain(W) - 0.01) < 1e-9);
assert(abs(abs(evalfr(W, 1i * 10)) - 1) < 1e-9);
assert(abs(abs(evalfr(W, 1i * 1e8)) - 2) < 1e-4);
Wordre = makeweight(0.01, 10, 2, 0, 2);
assert(abs(dcgain(Wordre) - 0.01) < 1e-9);
assert(abs(abs(evalfr(Wordre, 1i * 10)) - 1) < 1e-9);
Wgain = makeweight(0.01, [10 0.5], 2);
assert(abs(abs(evalfr(Wgain, 1i * 10)) - 0.5) < 1e-9);

% MKFILTER : gain statique un, coupure a -3 dB.
for type = {'butterw', 'cheby', 'bessel', 'rc'}
    F = mkfilter(10, 3, type{1});
    assert(abs(dcgain(F) - 1) < 1e-9);
end
assert(abs(abs(evalfr(mkfilter(10, 3, 'butterw'), 1i * 10)) - 1/sqrt(2)) < 1e-9);
assert(abs(abs(evalfr(mkfilter(1, 3, 'bessel'), 1i)) - 1/sqrt(2)) < 1e-6);

% IMP2SS retrouve l'ordre et les poles d'un modele a partir de sa seule
% reponse impulsionnelle.
Gsuite = c2d(ss(tf(1, [1 1.4 1])), 0.1);
suite = impulse(Gsuite, 0:0.1:20) * 0.1;
[Gidentifie, valeursSingulieres] = imp2ss(suite, 0.1);
assert(size(ss(Gidentifie).A, 1) == 2);
assert(valeursSingulieres(3) < 1e-9 * valeursSingulieres(1));
suiteIdentifiee = impulse(Gidentifie, 0:0.1:20) * 0.1;
assert(max(abs(suite(:) - suiteIdentifiee(:))) < 1e-10);
assert(max(abs(sort(abs(pole(Gidentifie))) - sort(abs(pole(Gsuite))))) < 1e-9);

% ------------------------------------------------------- analyse de marges
% MUSSV : un bloc plein donne exactement la plus grande valeur singuliere.
Mmu = [1 2; 3 4];
bornesPlein = mussv(Mmu, [2 2]);
assert(abs(bornesPlein(1) - max(svd(Mmu))) < 1e-12);
bornesScalaire = mussv(Mmu, [2 0]);
assert(bornesScalaire(1) <= max(svd(Mmu)) + 1e-9);      % mu <= sigma_max
assert(bornesScalaire(2) >= max(abs(eig(Mmu))) - 1e-9); % mu >= rayon
assert(bornesScalaire(2) <= bornesScalaire(1) + 1e-9);
% Une matrice diagonale : mu vaut le plus grand module de la diagonale.
bornesDiagonale = mussv(diag([2 -3 1]), [3 0]);
assert(abs(bornesDiagonale(1) - 3) < 1e-9);
assert(abs(bornesDiagonale(2) - 3) < 1e-9);
assert(isequal(size(skewdec(3, 0)), [3 3]));
assert(isequal(skewdec(3, 0) + skewdec(3, 0)', zeros(3)));
assert(isequal(symdec(3, 0), symdec(3, 0)'));

[margeEntree, margeSortie, margeBoucle] = loopmargin(ss(tf(1, [1 1 0])), ss(tf(2, 1)));
assert(margeBoucle.Stable);
assert(margeEntree.PhaseMargin > 0);
assert(abs(margeEntree.PhaseMargin - margeSortie.PhaseMargin) < 1e-6);  % monovariable
assert(margeBoucle.DiskMargin > 0 && margeBoucle.DiskMargin < 1);
assert(margeEntree.DelayMargin > 0);

% LOOPSENS : « G*Si » se calcule par FEEDBACK, faute de quoi un procede
% instable donnait une PSi instable alors que la boucle ne l'est pas.
boucleInstable = loopsens(Pinstable, Cstabilisant);
assert(boucleInstable.Stable);
assert(isfinite(hinfnorm(boucleInstable.PSi)));
assert(isfinite(hinfnorm(boucleInstable.CSo)));

% Une matrice de transferts s'ecrit maintenant entre crochets, et son gain
% statique se lit : SS2TF ne savait traiter qu'une seule voie.
Gmatrice = [tf(1, [1 1]), tf(2, [1 2]); tf(3, [1 3]), tf(4, [1 4])];
assert(size(ss(Gmatrice).A, 1) == 4);
assert(max(max(abs(dcgain(Gmatrice) - ones(2)))) < 1e-12);

disp('robuste : toutes les verifications passent');
