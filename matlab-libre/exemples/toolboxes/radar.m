% radar.m — Radar Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/radar.m
%
% Le cas : détecter une cible et mesurer sa distance et sa vitesse. Les
% deux mesures viennent de deux grandeurs différentes du signal reçu — le
% retard pour la distance, le décalage de fréquence pour la vitesse — et
% c'est ce qui structure toute la chaîne.

fprintf('=== Radar : le retard donne la distance, le decalage la vitesse ===\n\n');

c = 299792458;

%% 1. Distance et retard
% L'onde fait l'aller-retour : le retard vaut deux fois la distance
% divisée par la vitesse de la lumière. Ce facteur deux est la première
% source d'erreur quand on écrit l'équation de tête.
distances = [1e3 10e3 100e3];
retards = range2time(distances, c);
fprintf('Distance et retard :\n');
for k = 1:numel(distances)
    fprintf('  %6.1f km -> %8.2f microsecondes\n', ...
            distances(k) / 1e3, retards(k) * 1e6);
end
assert(max(abs(time2range(retards, c) - distances)) < 1e-6, ...
       'les deux conversions sont exactement inverses');
% Le facteur deux, verifie explicitement.
assert(abs(retards(1) - 2 * distances(1) / c) < 1e-15);
% Une microseconde de retard vaut 150 metres : le repere qu'on retient.
fprintf('  une microseconde vaut %.1f m\n', time2range(1e-6, c));
assert(abs(time2range(1e-6, c) - 149.9) < 0.2);

%% 2. Vitesse et décalage Doppler
% Une cible qui s'approche renvoie une onde plus haute en fréquence. Le
% décalage vaut deux fois la vitesse divisée par la longueur d'onde — le
% même facteur deux, pour la même raison.
frequence = 10e9;                     % 10 GHz, bande X
longueurOnde = c / frequence;
vitesses = [10 100 300];
decalages = dopplerShift(vitesses, frequence, c);
fprintf('\nDecalage Doppler a %g GHz (longueur d''onde %.2f cm) :\n', ...
        frequence / 1e9, longueurOnde * 100);
for k = 1:numel(vitesses)
    fprintf('  %5.0f m/s -> %8.1f Hz\n', vitesses(k), decalages(k));
end
assert(max(abs(decalages - 2 * vitesses / longueurOnde)) < 1e-6);
% Le decalage est proportionnel a la vitesse : doubler l'une double
% l'autre.
assert(abs(decalages(2) / decalages(1) - 10) < 1e-9);
% Une cible qui s'eloigne donne un decalage negatif.
assert(dopplerShift(-50, frequence, c) < 0);

%% 3. La compression d'impulsion
% Une impulsion longue porte de l'énergie, une impulsion courte donne de
% la résolution. On ne peut pas avoir les deux — sauf en émettant une
% impulsion longue *modulée*, et en la comprimant à la réception par un
% filtre adapté. C'est l'idée centrale du radar moderne.
Fe = 10e6;
dureeImpulsion = 20e-6;
bande = 2e6;
tImpulsion = (0:1 / Fe:dureeImpulsion - 1 / Fe)';
impulsion = exp(1i * pi * (bande / dureeImpulsion) * tImpulsion .^ 2);
fprintf('\nCompression d''impulsion :\n');
fprintf('  impulsion de %.0f microsecondes, bande de %.1f MHz\n', ...
        dureeImpulsion * 1e6, bande / 1e6);
% L'echo : l'impulsion retardee, noyee dans le bruit.
retardEchantillons = 500;
rng(1);
recu = [zeros(retardEchantillons, 1); impulsion; zeros(300, 1)];
recu = recu + 3 * (randn(size(recu)) + 1i * randn(size(recu)));
fprintf('  rapport signal sur bruit avant compression : %.1f dB\n', ...
        20 * log10(1 / 3 / sqrt(2)));
[comprime, decalagesCompression] = pulseCompression(recu, impulsion);
[pic, position] = max(abs(comprime));
retardTrouve = decalagesCompression(position);
fprintf('  retard trouve : %d echantillons (vrai %d)\n', ...
        retardTrouve, retardEchantillons);
assert(abs(retardTrouve - retardEchantillons) <= 2, ...
       'la compression doit retrouver le retard malgre le bruit');
% La compression achete deux choses distinctes, qu'on confond souvent.
%
% D'abord un gain en rapport signal sur bruit : le filtre adapte somme
% les N echantillons de l'impulsion en phase, alors que le bruit s'y
% ajoute au hasard. Le signal croit donc comme N, le bruit comme racine
% de N, et le rapport gagne un facteur N en puissance.
loinDuPic = abs(decalagesCompression - retardEchantillons) > 50;
fondCompresse = std(abs(comprime(loinDuPic)));
rapportApres = 20 * log10(pic / fondCompresse);
rapportAvant = 20 * log10(1 / (3 * sqrt(2)));
nEchantillons = numel(impulsion);
fprintf('  rapport apres compression : %.1f dB\n', rapportApres);
fprintf('  gain obtenu %.1f dB, attendu 10 log10(N) = %.1f dB\n', ...
        rapportApres - rapportAvant, 10 * log10(nEchantillons));
assert(pic > 4 * fondCompresse, 'le pic doit ressortir du fond');
assert(abs((rapportApres - rapportAvant) - 10 * log10(nEchantillons)) < 8, ...
       'le gain doit etre de l''ordre de N');
% Ensuite une resolution : le pic comprime est large de 1/bande au lieu
% de la duree de l'impulsion. Le rapport des deux — le produit duree fois
% bande — est le taux de compression.
seuil = pic / sqrt(2);
largeur = sum(abs(comprime) > seuil);
fprintf('  largeur du pic : %d echantillons (impulsion : %d)\n', ...
        largeur, nEchantillons);
fprintf('  taux de compression : %.0f (duree x bande = %.0f)\n', ...
        nEchantillons / max(largeur, 1), dureeImpulsion * bande);
assert(largeur < nEchantillons / 10, ...
       'le pic comprime est bien plus etroit que l''impulsion');
% Sans compression, l'echo ne se distingue pas du bruit dans le signal
% recu : c'est tout l'interet de l'operation.
picBrut = max(abs(recu(1:retardEchantillons - 50)));
assert(max(abs(recu)) < 2 * picBrut, ...
       'dans le signal recu, l''echo ne se distingue pas du bruit');

%% 4. Le filtre adapté
% Le filtre qui maximise le rapport signal sur bruit à l'instant de la
% cible est la référence retournée et conjuguée. Aucun autre filtre ne
% fait mieux : c'est un théorème, non un réglage.
% Le code de Barker de longueur 5 est [+1 +1 +1 -1 +1] : il n'y en a
% qu'un, a la reflexion et au changement de signe pres.
reference = [1 1 1 -1 1]';
signalPropre = [zeros(10, 1); reference; zeros(10, 1)];
sortie = matchedFilter(signalPropre, reference);
[picBarker, positionBarker] = max(abs(sortie));
fprintf('\nFiltre adapte, code de Barker de longueur 5 :\n');
fprintf('  pic %.1f a l''indice %d\n', picBarker, positionBarker);
% Le pic vaut l'energie du code : c'est la definition du filtre adapte.
assert(abs(picBarker - sum(reference .^ 2)) < 1e-9);
% Les lobes secondaires d'un code de Barker valent un au plus : c'est la
% propriete qui definit ces codes, et la raison de leur usage.
lobes = abs(sortie);
lobes(positionBarker) = 0;
fprintf('  plus grand lobe secondaire : %.1f (le pic vaut %.1f)\n', ...
        max(lobes), picBarker);
assert(max(lobes) <= 1 + 1e-9, ...
       'un code de Barker a tous ses lobes secondaires a un');

%% 5. L'équation du radar
% Ce que la puissance reçue devient avec la distance : elle décroît comme
% la puissance quatrième, l'aller et le retour se composant. Doubler la
% portée demande donc seize fois plus de puissance.
lambda = longueurOnde;
gain = 1000;                          % 30 dB
surface = 1;                          % 1 m^2
puissanceMin = 1e-13;
portee = radareqrng(lambda, 1e6, gain, surface, puissanceMin);
fprintf('\nEquation du radar :\n');
fprintf('  1 MW, gain %g, cible de %g m2 : portee %.1f km\n', ...
        gain, surface, portee / 1e3);
% Verification par l'autre sens : la puissance necessaire pour cette
% portee doit valoir un megawatt.
puissance = radareqpow(lambda, portee, gain, surface, puissanceMin);
fprintf('  puissance recalculee : %.4f MW\n', puissance / 1e6);
assert(abs(puissance - 1e6) / 1e6 < 1e-9, ...
       'les deux formes de l''equation sont inverses');
% La loi en puissance quatrieme : seize fois plus de puissance pour deux
% fois la portee.
puissanceDouble = radareqpow(lambda, 2 * portee, gain, surface, puissanceMin);
fprintf('  pour doubler la portee : %.2f fois plus de puissance\n', ...
        puissanceDouble / puissance);
assert(abs(puissanceDouble / puissance - 16) < 1e-9);
% Et une cible deux fois plus grosse ne gagne que la racine quatrieme.
porteeGrosse = radareqrng(lambda, 1e6, gain, 2 * surface, puissanceMin);
fprintf('  cible deux fois plus grosse : portee x %.4f (2^(1/4) = %.4f)\n', ...
        porteeGrosse / portee, 2 ^ 0.25);
assert(abs(porteeGrosse / portee - 2 ^ 0.25) < 1e-9);

fprintf('\nToutes les verifications passent.\n');
