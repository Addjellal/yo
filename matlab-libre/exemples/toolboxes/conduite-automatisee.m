%% Conduite automatisée : rester dans la voie, suivre, ne pas percuter
% Trois fonctions élémentaires y reviennent : savoir où l'on est dans sa
% voie, savoir quoi braquer pour suivre un chemin, et savoir combien de
% temps il reste avant de toucher ce qui est devant.
%
% Voir aussi LANEOFFSET, PUREPURSUIT, SMOOTHPATH, TIMETOCOLLISION.

fprintf('=== Conduite automatisee ===\n');

%% 1. L'écart au centre de la voie
% Le plus simple des indicateurs, et le plus utilisé : la distance
% signée au milieu des deux lignes.
fprintf('\nEcart au centre de la voie :\n');
fprintf('  voie de -1.75 a 1.75, vehicule a 0 : %.3f m\n', ...
        laneOffset(0, -1.75, 1.75));
assert(abs(laneOffset(0, -1.75, 1.75)) < 1e-15, 'centre : ecart nul');
fprintf('  vehicule a 0.5 : %+.3f m\n', laneOffset(0.5, -1.75, 1.75));
assert(abs(laneOffset(0.5, -1.75, 1.75) - 0.5) < 1e-15, 'ecart signe');
% Le signe indique le côté : c'est ce qui permet de savoir de quel bord
% on s'approche, non seulement de combien.
assert(laneOffset(-0.5, -1.75, 1.75) < 0, 'a gauche du centre : ecart negatif');
% Une voie décalée — en virage, ou après un rétrécissement — déplace le
% centre, et l'écart le suit.
fprintf('  voie decalee de 0.5 a 4.0, vehicule a 2.25 : %+.3f m\n', ...
        laneOffset(2.25, 0.5, 4.0));
assert(abs(laneOffset(2.25, 0.5, 4.0)) < 1e-15, ...
       'le centre suit les lignes, ou qu''elles soient');
% Sur une trajectoire entière : l'écart se calcule d'un coup.
positions = linspace(-1, 1, 9);
ecarts = laneOffset(positions, -1.75, 1.75);
assert(max(abs(ecarts - positions)) < 1e-15, 'vectorise sur toute une trajectoire');
% Franchissement de ligne : l'écart dépasse la demi-largeur.
demiLargeur = 1.75;
franchit = abs(ecarts) > demiLargeur;
fprintf('  %d position(s) hors voie sur %d\n', sum(franchit), numel(ecarts));
assert(sum(franchit) == 0, 'aucune de ces positions ne sort de la voie');
assert(abs(laneOffset(2.0, -1.75, 1.75)) > demiLargeur, ...
       'a 2 metres du centre, la ligne est franchie');

%% 2. Le temps avant collision
% La distance seule ne dit rien : trente mètres à vitesse égale sont sûrs,
% trente mètres à vingt mètres par seconde de rapprochement laissent une
% seconde et demie. C'est le temps, non la distance, qui décide.
fprintf('\nTemps avant collision :\n');
cas = [30 20; 30 5; 30 0; 30 -5; 5 20];
noms = {'30 m, rapprochement 20 m/s', '30 m, rapprochement 5 m/s', ...
        '30 m, meme vitesse', '30 m, il s''eloigne', '5 m, rapprochement 20 m/s'};
for k = 1:size(cas, 1)
    t = timeToCollision(cas(k,1), cas(k,2));
    fprintf('  %-32s : %s s\n', noms{k}, num2str(t));
end
assert(abs(timeToCollision(30, 20) - 1.5) < 1e-15, 'distance sur vitesse');
assert(isinf(timeToCollision(30, 0)), 'a vitesse egale, jamais de collision');
assert(isinf(timeToCollision(30, -5)), 's''il s''eloigne non plus');
% Vectorisé : c'est ainsi qu'on traite tous les objets détectés d'un coup.
distances = [50 30 6 12];
vitesses = [10 -2 3 20];
temps = timeToCollision(distances, vitesses);
fprintf('  sur quatre objets : %s\n', mat2str(round(temps, 2)));
assert(numel(temps) == 4, 'un temps par objet');
assert(isinf(temps(2)), 'celui qui s''eloigne ne compte pas');
% Le plus urgent n'est pas le plus proche : c'est tout l'intérêt de la
% mesure.
[urgence, lequel] = min(temps);
[~, proche] = min(distances);
fprintf('  le plus urgent : objet %d a %g m (%.2f s) ; le plus proche : objet %d a %g m (%.2f s)\n', ...
        lequel, distances(lequel), urgence, proche, distances(proche), temps(proche));
assert(lequel == 4 && proche == 3, ...
       'le plus urgent n''est pas le plus proche : c''est tout l''interet de la mesure');
% Un seuil de freinage d'urgence se pose directement sur ce temps.
assert(sum(temps < 2) == 1, 'un seul objet sous les deux secondes');

%% 3. La poursuite pure
% Le véhicule vise un point du chemin situé à une distance fixe devant
% lui, et braque de façon à décrire l'arc de cercle qui l'y mène. La
% commande est explicite : omega = 2 v sin(alpha) / L.
chemin = [linspace(0, 100, 1001).', zeros(1001, 1)];
distanceVisee = 5;
vitesse = 5;

% Sur le chemin et bien orienté : rien à corriger.
[omega, cible] = purePursuit([0 0 0], chemin, distanceVisee, vitesse);
fprintf('\nPoursuite pure sur une ligne droite :\n');
fprintf('  vehicule sur le chemin, bien oriente : omega = %.2e rad/s\n', omega);
assert(abs(omega) < 1e-12, 'aligne sur le chemin, aucune correction');
assert(abs(norm(chemin(cible, :)) - distanceVisee) < 0.2, ...
       'le point vise est bien a la distance de visee');

% Décalé à gauche du chemin : le véhicule doit braquer à droite, donc
% omega négatif.
omegaGauche = purePursuit([0 1 0], chemin, distanceVisee, vitesse);
omegaDroite = purePursuit([0 -1 0], chemin, distanceVisee, vitesse);
fprintf('  decale de +1 m : omega = %+.4f rad/s ; de -1 m : %+.4f rad/s\n', ...
        omegaGauche, omegaDroite);
assert(omegaGauche < 0, 'decale a gauche, il braque a droite');
assert(omegaDroite > 0, 'et reciproquement');
assert(abs(omegaGauche + omegaDroite) < 1e-12, 'la loi est impaire');

% La correction est d'autant plus vive que l'écart est grand, et
% d'autant plus douce que la distance de visée est longue. Ce dernier
% point est le seul réglage de la méthode.
fprintf('  intensite de la correction (ecart de 1 m) :\n');
precedente = inf;
for L = [3 5 10 20]
    o = abs(purePursuit([0 1 0], chemin, L, vitesse));
    fprintf('    visee a %2g m : omega = %.4f rad/s\n', L, o);
    assert(o < precedente, 'viser plus loin adoucit la correction');
    precedente = o;
end

% En boucle fermée : le véhicule rejoint le chemin et y reste. C'est la
% seule vérification qui compte vraiment.
etat = [0 2 0];
dt = 0.02;
ecarts = zeros(1, 600);
for k = 1:600
    o = purePursuit(etat, chemin, distanceVisee, vitesse);
    etat = [etat(1) + vitesse * cos(etat(3)) * dt, ...
            etat(2) + vitesse * sin(etat(3)) * dt, ...
            etat(3) + o * dt];
    ecarts(k) = etat(2);
end
fprintf('  en boucle fermee, depart a 2 m du chemin :\n');
fprintf('    ecart apres 2 s : %.4f m ; apres 12 s : %.4f m\n', ...
        ecarts(100), ecarts(end));
assert(abs(ecarts(end)) < 0.02, 'le vehicule rejoint le chemin');
assert(max(abs(ecarts(400:end))) < 0.05, 'et y reste');
assert(max(abs(ecarts)) <= 2 + 1e-9, 'sans jamais s''en ecarter davantage');

% Viser trop court rend la poursuite oscillante : c'est le défaut connu
% de la méthode, et il se mesure au nombre de passages par zéro.
etat = [0 2 0];
ecartsCourt = zeros(1, 600);
for k = 1:600
    o = purePursuit(etat, chemin, 1.2, vitesse);
    etat = [etat(1) + vitesse * cos(etat(3)) * dt, ...
            etat(2) + vitesse * sin(etat(3)) * dt, ...
            etat(3) + o * dt];
    ecartsCourt(k) = etat(2);
end
passages = sum(ecartsCourt(1:end-1) .* ecartsCourt(2:end) < 0);
fprintf('    visee a 1.2 m : %d passages par zero (contre %d a 5 m)\n', ...
        passages, sum(ecarts(1:end-1) .* ecarts(2:end) < 0));
assert(passages > sum(ecarts(1:end-1) .* ecarts(2:end) < 0), ...
       'viser trop court fait osciller');

%% 4. Lisser un chemin
% Un chemin issu d'un planificateur en grille est fait d'angles droits :
% impraticable tel quel. Le lissage arbitre entre fidélité aux points
% d'origine et douceur, par descente de gradient.
brut = [0 0; 1 0; 2 0; 3 0; 3 1; 3 2; 3 3];
lisse = smoothPath(brut, 0.5, 0.3);
longueurBrut = sum(vecnorm(diff(brut), 2, 2));
longueurLisse = sum(vecnorm(diff(lisse), 2, 2));
fprintf('\nLissage d''un chemin en equerre :\n');
fprintf('  longueur : %.4f -> %.4f m\n', longueurBrut, longueurLisse);
assert(longueurLisse < longueurBrut, 'le lissage raccourcit le chemin');

% Les extrémités ne bougent pas : on ne change ni le départ ni l'arrivée.
assert(norm(lisse(1,:) - brut(1,:)) < 1e-12, 'le depart reste');
assert(norm(lisse(end,:) - brut(end,:)) < 1e-12, 'l''arrivee aussi');
assert(size(lisse, 1) == size(brut, 1), 'et le nombre de points ne change pas');

% L'angle le plus vif s'arrondit : c'est la mesure qui compte, car c'est
% lui qui décide du braquage maximal à demander. La somme des courbures,
% elle, se conserve à peu près — le virage est étalé, non supprimé.
courbure = @(c) max(vecnorm(diff(c, 2), 2, 2));
fprintf('  angle le plus vif : %.4f -> %.4f\n', courbure(brut), courbure(lisse));
fprintf('  courbure cumulee : %.4f -> %.4f (le virage est etale, non supprime)\n', ...
        sum(vecnorm(diff(brut, 2), 2, 2)), sum(vecnorm(diff(lisse, 2), 2, 2)));
assert(courbure(lisse) < 0.6 * courbure(brut), 'les angles s''arrondissent');

% Le compromis se règle par les deux poids : plus de lissage, plus de
% douceur mais plus d'écart aux points d'origine.
fprintf('  compromis fidelite / douceur :\n');
for poidsLissage = [0.1 0.3 0.45]
    c = smoothPath(brut, 0.5, poidsLissage);
    fprintf('    poids %.2f : courbure %.4f, ecart aux points %.4f m\n', ...
            poidsLissage, courbure(c), max(vecnorm(c - brut, 2, 2)));
end
douxFort = smoothPath(brut, 0.5, 0.45);
douxFaible = smoothPath(brut, 0.5, 0.1);
assert(courbure(douxFort) < courbure(douxFaible), ...
       'plus de poids au lissage, moins de courbure');
assert(max(vecnorm(douxFort - brut, 2, 2)) > max(vecnorm(douxFaible - brut, 2, 2)), ...
       'mais plus d''ecart aux points d''origine');

% Un chemin déjà droit ne bouge pas : le lissage n'invente rien.
droit = [(0:5).', zeros(6, 1)];
assert(max(max(abs(smoothPath(droit, 0.5, 0.3) - droit))) < 1e-6, ...
       'un chemin droit reste droit');
fprintf('  un chemin deja droit reste inchange\n');

% Et un chemin lissé se suit mieux : la poursuite pure y braque moins.
maxBrut = 0; maxLisse = 0;
for k = 1:size(brut, 1) - 1
    cap = atan2(brut(k+1,2) - brut(k,2), brut(k+1,1) - brut(k,1));
    maxBrut = max(maxBrut, abs(purePursuit([brut(k,:) cap], brut, 1.5, 1)));
    maxLisse = max(maxLisse, abs(purePursuit([lisse(k,:) cap], lisse, 1.5, 1)));
end
fprintf('  braquage maximal a le suivre : %.4f (brut) contre %.4f (lisse)\n', ...
        maxBrut, maxLisse);
assert(maxLisse < maxBrut, 'un chemin lisse demande moins de braquage');

fprintf('\nToutes les verifications passent.\n');
