%% Dynamique du véhicule : le pneu, la transmission, la route
% Tout ce qu'un véhicule peut faire passe par quatre empreintes de pneu de
% la taille d'une main. Le reste — moteur, boîte, aérodynamique — n'est
% qu'une façon de leur demander des choses.
%
% Voir aussi BICYCLEMODEL, TIREFORCE, LONGITUDINAL, GEARRATIOSPEED.

fprintf('=== Dynamique du vehicule ===\n');

%% 1. Le modèle bicyclette
% Deux roues, un empattement, un angle de braquage. C'est le modèle
% cinématique de tout véhicule à direction avant, et il suffit à
% construire n'importe quelle trajectoire à basse vitesse.
empattement = 2.7;
dt = 0.01;

% Braquage nul : le véhicule va tout droit, et parcourt exactement
% vitesse x temps.
etat = [0 0 0];
for k = 1:1000
    etat = bicycleModel(etat, 10, 0, empattement, dt);
end
fprintf('\nModele bicyclette (empattement %g m) :\n', empattement);
fprintf('  10 m/s pendant 10 s, braquage nul : x = %.4f m, y = %.2e m\n', ...
        etat(1), etat(2));
assert(abs(etat(1) - 100) < 1e-9, 'tout droit : la distance est vitesse x temps');
assert(abs(etat(2)) < 1e-12 && abs(etat(3)) < 1e-12, 'sans deriver ni tourner');

% Braquage constant : le véhicule décrit un cercle, de rayon
% empattement / tan(braquage). C'est la formule d'Ackermann, et le modèle
% doit la vérifier au dixième de pour cent.
braquage = deg2rad(10);
rayonPredit = empattement / tan(braquage);
etat = [0 0 0];
trace = zeros(4000, 2);
for k = 1:4000
    etat = bicycleModel(etat, 5, braquage, empattement, dt);
    trace(k, :) = etat(1:2);
end
% Le centre du cercle est à gauche, à la distance du rayon.
centre = [0, rayonPredit];
rayons = sqrt(sum((trace - centre) .^ 2, 2));
fprintf('  braquage de %g deg : rayon predit %.4f m, mesure %.4f m\n', ...
        rad2deg(braquage), rayonPredit, mean(rayons));
assert(abs(mean(rayons) - rayonPredit) / rayonPredit < 2e-3, ...
       'le rayon suit la formule d''Ackermann');
assert(std(rayons) / rayonPredit < 2e-3, 'et le rayon est constant : c''est un cercle');

% Le rayon ne dépend pas de la vitesse : c'est un modèle cinématique, sans
% glissement ni force centrifuge. C'est sa limite, et il faut la connaître.
etat = [0 0 0];
for k = 1:2000
    etat = bicycleModel(etat, 10, braquage, empattement, dt);
end
rayon2 = norm(etat(1:2) - centre);
fprintf('  a 10 m/s : rayon %.4f m — le modele ignore la vitesse\n', rayon2);
assert(abs(rayon2 - rayonPredit) / rayonPredit < 2e-3, ...
       'un modele cinematique ne connait pas la vitesse limite');

% Braquer d'un côté puis de l'autre ramène le cap : les rotations
% s'annulent, la position non.
etat = [0 0 0];
for k = 1:500, etat = bicycleModel(etat, 5, braquage, empattement, dt); end
for k = 1:500, etat = bicycleModel(etat, 5, -braquage, empattement, dt); end
fprintf('  un creneau symetrique : cap final %.2e rad, ecart lateral %.3f m\n', ...
        etat(3), etat(2));
assert(abs(etat(3)) < 1e-12, 'braquer autant a droite qu''a gauche ramene le cap');
assert(etat(2) > 0.5, 'mais deplace lateralement : c''est un changement de file');

%% 2. La formule magique de Pacejka
% La force qu'un pneu transmet ne croît pas indéfiniment avec le
% glissement : elle passe par un maximum, puis retombe. Ce maximum est la
% limite d'adhérence, et le décrochage est ce qui vient après.
charge = 4000;
glissements = linspace(0, 0.6, 6001);
F = arrayfun(@(g) tireForce(g, charge), glissements);
[Fmax, imax] = max(F);
fprintf('\nPneu de Pacejka sous %g N :\n', charge);
fprintf('  force maximale %.1f N a %.1f %% de glissement\n', ...
        Fmax, 100 * glissements(imax));
fprintf('  coefficient d''adherence : %.3f\n', Fmax / charge);
assert(glissements(imax) > 0.05 && glissements(imax) < 0.25, ...
       'le maximum est autour de 10 a 20 %% de glissement');
assert(abs(Fmax / charge - 1) < 0.05, 'l''adherence de pointe vaut environ un');

% Au-delà, la force redescend : c'est la zone instable où la roue se
% bloque ou patine. Tout l'ABS et tout le contrôle de traction consistent
% à ne pas y entrer.
fprintf('  a 50 %% de glissement : %.1f N, soit %.0f %% du maximum\n', ...
        tireForce(0.5, charge), 100 * tireForce(0.5, charge) / Fmax);
assert(tireForce(0.5, charge) < Fmax, 'au-dela du pic, la force retombe');
assert(F(end) < 0.95 * Fmax, 'le decrochage est net');

% Pour de petits glissements, la relation est linéaire : c'est la rigidité
% de dérive, celle qu'on emploie dans tous les modèles linéarisés.
rigidite = (tireForce(0.001, charge) - tireForce(0, charge)) / 0.001;
fprintf('  rigidite au voisinage de zero : %.0f N par unite de glissement\n', ...
        rigidite);
assert(abs(tireForce(0, charge)) < 1e-12, 'sans glissement, pas de force');
assert(abs(tireForce(0.002, charge) - 2 * tireForce(0.001, charge)) ...
       / tireForce(0.002, charge) < 0.01, ...
       'la reponse est lineaire pres de zero');
% Impair : glisser dans l'autre sens donne la force opposée.
assert(abs(tireForce(-0.1, charge) + tireForce(0.1, charge)) < 1e-12, ...
       'la formule est impaire');
% Proportionnelle à la charge : c'est l'hypothèse même du modèle.
assert(abs(tireForce(0.1, 2 * charge) - 2 * tireForce(0.1, charge)) < 1e-9, ...
       'la force est proportionnelle a la charge verticale');

%% 3. Les résistances à l'avancement
% Trois forces s'opposent au véhicule : la traînée, qui croît comme le
% carré de la vitesse ; le roulement, à peu près constant ; la pente, qui
% ne dépend que d'elle.
masse = 1500;
cx = 0.30;
fprintf('\nResistances sur %g kg, Cx = %g :\n', masse, cx);
for v = [10 30 50]
    a = longitudinal(0, masse, v, cx);
    fprintf('  a %2g m/s, moteur coupe : deceleration %.4f m/s2\n', v, -a);
end
% À vitesse nulle, seul le roulement freine.
a0 = longitudinal(0, masse, 0, cx);
fprintf('  a l''arret : %.4f m/s2, soit crr x g = %.4f\n', -a0, 0.012 * 9.81);
assert(abs(-a0 - 0.012 * 9.81) < 1e-9, 'a l''arret, seul le roulement compte');
% La traînée quadruple quand la vitesse double.
traineeA = -longitudinal(0, masse, 20, cx) + a0;
traineeB = -longitudinal(0, masse, 40, cx) + a0;
fprintf('  la trainee est multipliee par %.4f quand la vitesse double\n', ...
        traineeB / traineeA);
assert(abs(traineeB / traineeA - 4) < 1e-9, 'la trainee croit comme le carre');

% La vitesse maximale : celle où la poussée disponible égale exactement
% les résistances. On la trouve en cherchant le zéro de l'accélération.
poussee = 2500;
vmax = fzero(@(v) longitudinal(poussee, masse, v, cx), [1 200]);
fprintf('  avec %g N de poussee : vitesse maximale %.2f m/s (%.1f km/h)\n', ...
        poussee, vmax, vmax * 3.6);
assert(abs(longitudinal(poussee, masse, vmax, cx)) < 1e-9, ...
       'a la vitesse maximale, l''acceleration est nulle');
assert(longitudinal(poussee, masse, vmax - 5, cx) > 0, 'en deca, on accelere');
assert(longitudinal(poussee, masse, vmax + 5, cx) < 0, 'au-dela, on ralentit');

% Une pente de dix pour cent coûte g sin(atan(0.1)), soit près d'un
% mètre par seconde carrée : à la portée d'un petit moteur, mais pas
% négligeable.
pente = atan(0.10);
coutPente = longitudinal(0, masse, 0, cx) - longitudinal(0, masse, 0, cx, 2.2, 1.225, 0.012, pente);
fprintf('  une pente de 10 %% coute %.4f m/s2 (g sin = %.4f)\n', ...
        coutPente, 9.81 * sin(pente));
assert(abs(coutPente - 9.81 * sin(pente)) < 0.02, ...
       'la pente coute g sin(pente), au roulement pres');

%% 4. La transmission
% Le rapport de boîte ne fait qu'échanger couple contre vitesse. Le régime
% moteur et la vitesse du véhicule sont liés rigidement, une fois le
% rapport choisi.
rayonRoue = 0.32;
final = 3.9;
rapports = [3.5 2.1 1.4 1.0 0.8];
fprintf('\nTransmission (roue %g m, pont %g) a 3000 tr/min :\n', rayonRoue, final);
vitesses = zeros(size(rapports));
for k = 1:numel(rapports)
    vitesses(k) = gearRatioSpeed(3000, rapports(k), final, rayonRoue);
    fprintf('  rapport %d (%.1f) : %.2f m/s, soit %.1f km/h\n', ...
            k, rapports(k), vitesses(k), vitesses(k) * 3.6);
end
assert(all(diff(vitesses) > 0), 'monter les rapports fait aller plus vite');
% La relation est linéaire en régime : c'est un simple rapport d'engrenages.
assert(abs(gearRatioSpeed(6000, 1, final, rayonRoue) - ...
           2 * gearRatioSpeed(3000, 1, final, rayonRoue)) < 1e-12, ...
       'doubler le regime double la vitesse');
% Et inversement proportionnelle au rapport.
assert(abs(gearRatioSpeed(3000, 2, final, rayonRoue) * 2 - ...
           gearRatioSpeed(3000, 1, final, rayonRoue)) < 1e-12, ...
       'doubler la demultiplication divise la vitesse par deux');
% Vérification directe : la roue tourne à regime/(rapport x final) et
% avance de 2 pi R par tour.
regimeRoue = 3000 / (rapports(4) * final);        % tours par minute
attendue = regimeRoue / 60 * 2 * pi * rayonRoue;
fprintf('  verification en 4e : roue a %.1f tr/min -> %.4f m/s\n', ...
        regimeRoue, attendue);
assert(abs(attendue - vitesses(4)) < 1e-12, 'la roue avance de 2 pi R par tour');

%% 5. Tout ensemble : une accélération départ arrêté
% La poussée disponible est celle du pneu ou celle du moteur, selon
% laquelle est la plus faible. Aux premiers mètres c'est le pneu qui
% commande — d'où l'intérêt d'une charge sur l'essieu moteur.
chargeMotrice = masse * 9.81 * 0.6;                % 60 % sur l'essieu moteur
pousseeMax = tireForce(0.12, chargeMotrice);
pousseeMoteur = 12000;                             % un moteur genereux
fprintf('\nAcceleration depart arrete :\n');
fprintf('  poussee du moteur %g N, limite du pneu %.0f N\n', ...
        pousseeMoteur, pousseeMax);
assert(pousseeMax < pousseeMoteur, ...
       'ici c''est bien le pneu qui commande, non le moteur');
v = 0;
distance = 0;
temps = 0;
while v < 27.8 && temps < 60                       % jusqu'a 100 km/h
    a = longitudinal(min(pousseeMoteur, pousseeMax), masse, v, cx);
    v = v + a * 0.001;
    distance = distance + v * 0.001;
    temps = temps + 0.001;
end
fprintf('  0 a 100 km/h en %.2f s sur %.1f m\n', temps, distance);
assert(temps > 3 && temps < 12, 'un 0 a 100 plausible pour ces chiffres');
assert(distance > 30 && distance < 200, 'sur une distance plausible');
% Sans limite de pneu, ce serait plus rapide : l'écart mesure exactement
% ce que l'adhérence manquante coûte.
v = 0; tempsLibre = 0;
while v < 27.8 && tempsLibre < 60
    v = v + longitudinal(pousseeMoteur, masse, v, cx) * 0.001;
    tempsLibre = tempsLibre + 0.001;
end
fprintf('  sans limite d''adherence : %.2f s, soit %.2f s de moins\n', ...
        tempsLibre, temps - tempsLibre);
assert(tempsLibre < temps - 0.5, ...
       'le pneu bride vraiment la performance, et l''ecart le chiffre');
% Charger l'essieu moteur augmente la poussée disponible : c'est
% pourquoi une propulsion accélère mieux qu'une traction au démarrage,
% le transfert de charge allant vers l'arrière.
fprintf('  avec 80 %% de charge sur l''essieu moteur : %.0f N disponibles\n', ...
        tireForce(0.12, masse * 9.81 * 0.8));
assert(tireForce(0.12, masse * 9.81 * 0.8) > pousseeMax, ...
       'plus de charge sur l''essieu moteur, plus de poussee');

fprintf('\nToutes les verifications passent.\n');
