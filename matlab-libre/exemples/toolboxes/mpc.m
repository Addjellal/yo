% mpc.m — Model Predictive Control Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/mpc.m
%
% Le cas : commander un procédé en anticipant. À chaque instant, le
% correcteur prédit ce que le procédé fera sur un horizon, choisit la
% suite de commandes qui minimise l'écart à la consigne, applique la
% première seulement, et recommence. C'est cette dernière clause — ne
% garder que la première — qui fait toute la robustesse de la méthode.

fprintf('=== Commande predictive : anticiper, appliquer un pas, recommencer ===\n\n');

%% 1. Le procédé
% Un double intégrateur discret : la position d'une masse commandée en
% force. C'est le cas d'école, parce qu'il est instable en boucle ouverte
% et qu'aucun réglage naïf ne le tient.
Te = 0.1;
A = [1 Te; 0 1];
B = [Te ^ 2 / 2; Te];
C = [1 0];
fprintf('Procede : double integrateur, periode %g s\n', Te);
fprintf('  poles : %s (sur le cercle unite)\n', mat2str(eig(A)'));
assert(max(abs(eig(A))) >= 1 - 1e-12, ...
       'un double integrateur n''est pas asymptotiquement stable');
% Il est commandable : c'est la condition pour qu'une commande predictive
% ait quelque chose a optimiser.
assert(rank([B, A * B]) == 2, 'le procede doit etre commandable');

%% 2. Le correcteur
% Deux horizons et deux pondérations. L'horizon de prédiction dit
% jusqu'où on regarde ; celui de commande, combien de coups on décide. Q
% pèse l'écart à la consigne, R le coût de la commande.
horizonPrediction = 20;
horizonCommande = 5;
Q = 1;
R = 0.1;
controleur = mpcSetup(A, B, C, horizonPrediction, horizonCommande, Q, R);
fprintf('\nCorrecteur : prediction %d pas, commande %d pas\n', ...
        horizonPrediction, horizonCommande);
fprintf('  ponderations Q = %g, R = %g\n', Q, R);

%% 3. Un pas de commande
% Le correcteur rend la commande à appliquer, et la séquence complète
% qu'il avait prévue. Comparer les deux montre ce que « horizon glissant »
% veut dire : on jette tout sauf le premier terme.
etat = [0; 0];
consigne = 1;
[u, sequence] = mpcmove(controleur, etat, consigne);
fprintf('\nPremier pas depuis l''origine, consigne %g :\n', consigne);
fprintf('  commande appliquee : %.6f\n', u);
fprintf('  sequence prevue : %s\n', mat2str(round(sequence(:)', 4)));
assert(numel(sequence) == horizonCommande, ...
       'la sequence couvre l''horizon de commande');
assert(abs(u - sequence(1)) < 1e-12, ...
       'on applique le premier terme de la sequence, et lui seul');
% Pour atteindre une consigne positive depuis l'arret, il faut d'abord
% pousser.
assert(u > 0, 'la premiere commande doit pousser vers la consigne');

%% 4. La simulation complète
% Ce qui compte : la sortie rejoint la consigne, sans dépassement
% excessif, et la commande reste bornée.
nPas = 60;
[y, commandes, t] = mpcsim(controleur, consigne, nPas);
fprintf('\nSimulation sur %d pas :\n', nPas);
fprintf('  sortie finale %.6f (consigne %g)\n', y(end), consigne);
fprintf('  depassement %.2f %%\n', (max(y) - consigne) / consigne * 100);
fprintf('  commande maximale %.4f\n', max(abs(commandes)));
assert(abs(y(end) - consigne) < 0.05, 'la sortie doit rejoindre la consigne');
assert(numel(y) == numel(t) && numel(commandes) == numel(t));
% La sortie part de zero et croit vers la consigne.
assert(abs(y(1)) < 0.2);
% La commande est finie : c'est ce qu'on demande a un correcteur, et ce
% qu'un placement de poles trop ambitieux ne garantit pas.
assert(all(isfinite(commandes)));
assert(max(abs(commandes)) < 100);

%% 5. Ce que R règle
% Augmenter R rend la commande plus douce et la réponse plus lente.
% C'est le seul vrai réglage de la méthode, et l'arbitrage est explicite —
% contrairement à un PID, où il se cache dans trois gains.
fprintf('\nEffet de la ponderation de la commande :\n');
efforts = zeros(1, 4);
rapidites = zeros(1, 4);
valeursR = [0.01 0.1 1 10];
for k = 1:4
    controleurK = mpcSetup(A, B, C, horizonPrediction, horizonCommande, Q, valeursR(k));
    [yk, uk] = mpcsim(controleurK, consigne, nPas);
    efforts(k) = max(abs(uk));
    atteint = find(yk > 0.9 * consigne, 1);
    if isempty(atteint)
        rapidites(k) = nPas;
    else
        rapidites(k) = atteint;
    end
    fprintf('  R = %6.2f : commande maximale %7.4f, 90 %% atteint en %2d pas\n', ...
            valeursR(k), efforts(k), rapidites(k));
end
% Plus R est grand, moins on pousse : c'est mecanique.
assert(all(diff(efforts) <= 1e-9), ...
       'ponderer la commande la reduit, sans exception');
% Et plus la reponse est lente.
assert(rapidites(end) >= rapidites(1), ...
       'la douceur se paie en rapidite');

%% 6. Ce que l'horizon règle
% Un horizon de prédiction trop court rend le correcteur myope : il ne
% voit pas assez loin pour anticiper, et se comporte mal sur un procédé
% qui répond lentement.
fprintf('\nEffet de l''horizon de prediction :\n');
for horizon = [3 10 30]
    controleurH = mpcSetup(A, B, C, horizon, min(horizonCommande, horizon), Q, R);
    [yh, ~] = mpcsim(controleurH, consigne, nPas);
    ecartFinal = abs(yh(end) - consigne);
    fprintf('  horizon %2d : ecart final %.6f, depassement %.2f %%\n', ...
            horizon, ecartFinal, (max(yh) - consigne) / consigne * 100);
end
% Un horizon long doit au moins faire aussi bien qu'un horizon court.
controleurCourt = mpcSetup(A, B, C, 3, 3, Q, R);
controleurLong = mpcSetup(A, B, C, 30, 5, Q, R);
yCourt = mpcsim(controleurCourt, consigne, nPas);
yLong = mpcsim(controleurLong, consigne, nPas);
assert(abs(yLong(end) - consigne) <= abs(yCourt(end) - consigne) + 0.05, ...
       'voir plus loin ne peut pas nuire');

fprintf('\nToutes les verifications passent.\n');
