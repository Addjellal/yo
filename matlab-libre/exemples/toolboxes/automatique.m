% automatique.m — Control System Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/automatique.m
%
% Le cas : un moteur à courant continu commandé en vitesse. C'est
% l'exemple d'école par excellence — un premier ordre avec retard
% mécanique, qu'on corrige par un PID, et dont on lit les marges.
%
% Le fil du script sert de modèle : décrire le procédé, l'analyser,
% le corriger, vérifier le résultat.

fprintf('=== Automatique : asservissement de vitesse d''un moteur ===\n\n');

%% 1. Le procédé
% Moteur à courant continu, entrée tension, sortie vitesse. Les
% constantes sont celles du modèle de cours :
%   J = 0.01 kg.m^2, b = 0.1 N.m.s, K = 0.01, R = 1 ohm, L = 0.5 H
%
%   G(s) = K / [(J s + b)(L s + R) + K^2]
J = 0.01; b = 0.1; K = 0.01; R = 1; L = 0.5;
numerateur = K;
denominateur = [J * L, J * R + b * L, b * R + K ^ 2];
G = tf(numerateur, denominateur);
fprintf('Procede :\n');
disp(G);

% Ce qu'on lit sur un modèle avant toute correction.
fprintf('  gain statique      : %.4f\n', dcgain(G));
fprintf('  poles              : %s\n', mat2str(round(pole(G)', 4)));
[pulsation, amortissement] = damp(G);
fprintf('  pulsations propres : %s rad/s\n', mat2str(round(pulsation', 4)));
fprintf('  amortissements     : %s\n', mat2str(round(amortissement', 4)));
% Deux poles reels : l'amortissement vaut un, et la pulsation propre est
% le module du pole.
assert(max(abs(amortissement - 1)) < 1e-12);
assert(max(abs(pulsation - abs(pole(G)))) < 1e-12);
assert(abs(dcgain(G) - K / (b * R + K ^ 2)) < 1e-12);
assert(all(real(pole(G)) < 0), 'le moteur doit etre stable');

%% 2. La réponse en boucle ouverte
[y, t] = step(G, 3);
info = stepinfo(y, t);
fprintf('\nBoucle ouverte, reponse indicielle :\n');
fprintf('  valeur finale      : %.4f\n', y(end));
fprintf('  temps de montee    : %.4f s\n', info.RiseTime);
fprintf('  temps d''etablissement : %.4f s\n', info.SettlingTime);
% Un premier ordre dominant ne dépasse pas.
fprintf('  depassement        : %.2f %%\n', info.Overshoot);
assert(info.Overshoot < 1, 'un systeme sans zero ni resonance ne depasse pas');
assert(abs(y(end) - dcgain(G)) < 1e-3);

%% 3. Le correcteur
% Un PID accélère et annule l'erreur statique. L'intégrateur est ce qui
% amène la sortie exactement à la consigne : sans lui, le gain statique
% de la boucle fermée resterait inférieur à un.
Kp = 100; Ki = 200; Kd = 10;
C = pid(Kp, Ki, Kd);
boucleOuverte = C * G;
boucleFermee = feedback(boucleOuverte, 1);
fprintf('\nCorrecteur PID : Kp = %g, Ki = %g, Kd = %g\n', Kp, Ki, Kd);
fprintf('  gain statique en boucle fermee : %.6f\n', dcgain(boucleFermee));
assert(abs(dcgain(boucleFermee) - 1) < 1e-6, ...
       'l''integrateur doit annuler l''erreur statique');

[yf, tf_] = step(boucleFermee, 1);
infoF = stepinfo(yf, tf_);
fprintf('  temps de montee    : %.4f s (contre %.4f sans correction)\n', ...
        infoF.RiseTime, info.RiseTime);
fprintf('  depassement        : %.2f %%\n', infoF.Overshoot);
assert(infoF.RiseTime < info.RiseTime, 'le PID doit accelerer la reponse');

%% 4. Les marges
% Une boucle n'est pas jugée sur sa seule rapidité : il faut savoir de
% combien on peut se tromper sur le gain et sur la phase avant de perdre
% la stabilité.
[marge, phase, wg, wp] = margin(boucleOuverte);
fprintf('\nMarges de la boucle ouverte corrigee :\n');
fprintf('  marge de gain  : %.4g (soit %.2f dB) a %.4g rad/s\n', ...
        marge, 20 * log10(marge), wg);
fprintf('  marge de phase : %.2f degres a %.4g rad/s\n', phase, wp);
assert(phase > 30, 'une marge de phase saine depasse trente degres');

% Le lieu des racines dit où les pôles partent quand le gain monte : une
% ligne par pôle, une colonne par gain.
[racines, gains] = rlocus(G);
fprintf('  lieu des racines : %d branches sur %d gains\n', ...
        size(racines, 1), numel(gains));
assert(size(racines, 1) == numel(pole(G)));
assert(size(racines, 2) == numel(gains));
% Au gain le plus faible, les branches partent des pôles du procédé. Les
% racines sont complexes même quand elles sont réelles : SORT les
% rangerait par module, on compare donc les parties réelles.
assert(max(abs(sort(real(racines(:, 1))) - sort(pole(G)))) < 0.05);

%% 5. Représentation d'état, commandabilité, observabilité
systemeEtat = ss(G);
[A, B, Cmat, D] = ssdata(systemeEtat);
fprintf('\nRepresentation d''etat : %d etats\n', size(A, 1));
fprintf('  rang de commandabilite : %d sur %d\n', rank(ctrb(A, B)), size(A, 1));
fprintf('  rang d''observabilite   : %d sur %d\n', rank(obsv(A, Cmat)), size(A, 1));
assert(rank(ctrb(A, B)) == size(A, 1), 'le moteur doit etre commandable');
assert(rank(obsv(A, Cmat)) == size(A, 1), 'le moteur doit etre observable');

% Placement de pôles : on impose où les pôles doivent aller.
polesVoulus = [-10, -12];
gainRetour = place(A, B, polesVoulus);
polesObtenus = sort(eig(A - B * gainRetour));
fprintf('  poles places : %s (demandes %s)\n', ...
        mat2str(round(polesObtenus', 4)), mat2str(sort(polesVoulus)));
assert(max(abs(polesObtenus' - sort(polesVoulus))) < 1e-8);

% Commande optimale : le même problème, résolu par un critère plutôt que
% par un choix de pôles.
gainLqr = lqr(A, B, eye(size(A)), 1);
fprintf('  poles LQR    : %s\n', mat2str(round(sort(eig(A - B * gainLqr))', 4)));
assert(all(real(eig(A - B * gainLqr)) < 0), 'le LQR est stable par construction');

%% 6. Discrétisation
% Un correcteur s'implante sur un calculateur : il faut le discrétiser.
Te = 0.01;
Gd = c2d(G, Te, 'zoh');
fprintf('\nDiscretisation a Te = %g s :\n', Te);
fprintf('  poles discrets : %s\n', mat2str(round(pole(Gd)', 6)));
fprintf('  |poles|        : %s (stable si < 1)\n', mat2str(round(abs(pole(Gd))', 6)));
assert(all(abs(pole(Gd)) < 1), 'la discretisation preserve la stabilite');
% Les pôles discrets sont l'exponentielle des pôles continus.
assert(max(abs(sort(pole(Gd)) - sort(exp(pole(G) * Te)))) < 1e-10);

fprintf('\nToutes les verifications passent.\n');
