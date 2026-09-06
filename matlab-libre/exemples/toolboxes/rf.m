%% Radiofréquences : impédances, réflexions, bruit
% Une ligne de transmission n'a que faire des tensions et des courants
% pris séparément : ce qui compte est le rapport entre l'onde qui part et
% celle qui revient. Tout le vocabulaire du domaine — coefficient de
% réflexion, TOS, paramètres S — décrit ce seul rapport.
%
% Voir aussi Z2GAMMA, GAMMA2Z, VSWR, DBM2W, W2DBM, FRIISNOISE, SPARAM2ZPARAM.

fprintf('=== Radiofrequences ===\n');

%% 1. Les décibels-milliwatt
% Le dBm est une puissance absolue : zéro dBm vaut un milliwatt. Dix dB
% de plus, c'est dix fois plus de puissance ; trois dB, c'est le double.
fprintf('\nEchelle des dBm :\n');
for p = [-30 0 10 30]
    fprintf('  %+4g dBm = %g W\n', p, dbm2w(p));
end
assert(abs(dbm2w(0) - 1e-3) < 1e-15, 'zero dBm vaut un milliwatt');
assert(abs(dbm2w(30) - 1) < 1e-12, 'trente dBm valent un watt');
assert(abs(dbm2w(10) / dbm2w(0) - 10) < 1e-12, 'dix dB : dix fois plus');
assert(abs(dbm2w(3) / dbm2w(0) - 2) < 0.005, 'trois dB : le double');
% Aller-retour exact : c'est une bijection.
essais = [-120 -60 -3 0 7 43];
assert(max(abs(w2dbm(dbm2w(essais)) - essais)) < 1e-12, ...
       'w2dbm annule dbm2w');
fprintf('  aller-retour sur %d valeurs : ecart %.2e dB\n', ...
        numel(essais), max(abs(w2dbm(dbm2w(essais)) - essais)));
% Les décibels transforment les produits en sommes : c'est leur raison
% d'être. Un gain de 20 dB sur -10 dBm donne +10 dBm.
assert(abs(w2dbm(dbm2w(-10) * 100) - 10) < 1e-12, ...
       'les gains s''additionnent en decibels');

%% 2. Coefficient de réflexion et adaptation
% Une charge égale à l'impédance caractéristique ne renvoie rien : c'est
% l'adaptation parfaite. Tout écart se paie en onde réfléchie.
Z0 = 50;
charges = [50, 100, 25, 0, 1e12, 50 + 50i];
noms = {'50 ohms (adaptee)', '100 ohms', '25 ohms', 'court-circuit', ...
        'quasi ouvert (1e12)', '50 + 50j ohms'};
fprintf('\nCoefficient de reflexion sur %g ohms :\n', Z0);
for k = 1:numel(charges)
    g = z2gamma(charges(k), Z0);
    fprintf('  %-18s gamma = %+.4f %+.4fj, |gamma| = %.4f, TOS = %.3f\n', ...
            noms{k}, real(g), imag(g), abs(g), vswr(g));
end
assert(abs(z2gamma(Z0, Z0)) < 1e-15, 'la charge adaptee ne reflechit rien');
assert(abs(z2gamma(0, Z0) + 1) < 1e-15, 'le court-circuit reflechit tout, inverse');
assert(abs(z2gamma(1e12, Z0) - 1) < 1e-9, 'le circuit ouvert reflechit tout, en phase');
% À l'infini exact la formule est indéterminée — (Inf-Z0)/(Inf+Z0) — et
% rend NaN, comme dans MATLAB. Sa limite, elle, vaut bien +1.
assert(isnan(z2gamma(inf, Z0)), 'a l''infini exact la formule est indeterminee');
% Une charge purement résistive donne un gamma réel ; les réactances
% seules le font tourner dans le plan complexe sans changer son module.
assert(abs(abs(z2gamma(1i * 37, Z0)) - 1) < 1e-14, ...
       'une reactance pure reflechit toute la puissance');

% L'aller-retour impédance-gamma est exact, sauf aux deux extrêmes.
retour = gamma2z(z2gamma(charges(1:3), Z0), Z0);
fprintf('  retour a l''impedance : ecart %.2e ohm\n', ...
        max(abs(retour - charges(1:3))));
assert(max(abs(retour - charges(1:3))) < 1e-12, 'gamma2z annule z2gamma');
assert(abs(gamma2z(z2gamma(50 + 50i, Z0), Z0) - (50 + 50i)) < 1e-12, ...
       'y compris pour une charge complexe');

%% 3. Le taux d'ondes stationnaires
% Le TOS est le rapport du maximum au minimum de la tension le long de la
% ligne. Il vaut un quand rien ne revient, et croît sans borne quand tout
% revient. C'est le même renseignement que |gamma|, sur une autre échelle.
fprintf('\nTaux d''ondes stationnaires :\n');
for module = [0 1/3 0.5 0.9]
    fprintf('  |gamma| = %.4f -> TOS = %.4f\n', module, vswr(module));
end
assert(abs(vswr(0) - 1) < 1e-15, 'adaptee : TOS de un');
assert(abs(vswr(1/3) - 2) < 1e-12, '|gamma| = 1/3 : TOS de deux');
assert(vswr(0.999) > 1000, 'quasi totalement reflechie : TOS enorme');
% Le TOS ne distingue pas la nature du désaccord : cent ohms et vingt-cinq
% donnent le même deux, l'un par excès, l'autre par défaut.
assert(abs(vswr(z2gamma(100, Z0)) - vswr(z2gamma(25, Z0))) < 1e-12, ...
       'doubler ou diviser par deux donne le meme TOS');
fprintf('  100 et 25 ohms donnent le meme TOS : %.4f\n', vswr(z2gamma(100, Z0)));
% La fraction de puissance réfléchie est |gamma|^2 ; le reste est
% transmis à la charge.
g = z2gamma(100, Z0);
fprintf('  a TOS 2 : %.2f %% de la puissance revient, %.2f %% passe\n', ...
        100 * abs(g)^2, 100 * (1 - abs(g)^2));
assert(abs(abs(g)^2 - 1/9) < 1e-12, 'un neuvieme de la puissance revient');

%% 4. Le facteur de bruit d'une chaîne
% La formule de Friis dit que le premier étage domine : le bruit des
% suivants est divisé par tout le gain qui les précède. C'est pourquoi on
% met l'amplificateur faible bruit tout devant, et pourquoi ce qui vient
% après compte de moins en moins.
facteurs = [10^(1.0/10), 10^(3.0/10), 10^(10.0/10)];   % 1, 3 et 10 dB
gains = [10^(20/10), 10^(15/10), 1];                    % 20 et 15 dB
[F, FdB] = friisNoise(facteurs, gains);
fprintf('\nChaine LNA (1 dB, 20 dB) + melangeur (3 dB, 15 dB) + FI (10 dB) :\n');
fprintf('  facteur de bruit total %.4f, soit %.4f dB\n', F, FdB);
assert(FdB > 10 * log10(facteurs(1)), 'le total depasse le premier etage');
assert(FdB < 10 * log10(facteurs(1)) + 0.2, 'mais de tres peu : le LNA domine');

% Inverser l'ordre ruine la chaîne : le même matériel, mal rangé, donne
% des décibels de bruit en plus.
[~, FdBinverse] = friisNoise(fliplr(facteurs), fliplr(gains(end:-1:1)));
fprintf('  le meme materiel range a l''envers : %.4f dB\n', FdBinverse);
assert(FdBinverse > FdB + 5, 'mettre le pire etage devant coute tres cher');

% Un seul étage : le facteur de bruit total est le sien.
assert(abs(friisNoise(facteurs(1), 1) - facteurs(1)) < 1e-15, ...
       'un seul etage : rien a ajouter');
% Un premier étage à gain infini rend les suivants invisibles.
[Finfini, ~] = friisNoise(facteurs, [1e12, 1e12]);
assert(abs(Finfini - facteurs(1)) < 1e-6, ...
       'a gain infini, seul le premier etage compte');
fprintf('  a gain infini du premier etage : %.6f (le sien : %.6f)\n', ...
        Finfini, facteurs(1));

%% 5. Paramètres S et paramètres Z
% Les paramètres S décrivent un quadripôle par des ondes, les Z par des
% tensions et courants. Les deux disent la même chose, et la conversion
% doit le montrer.
%
% Cas d'école : un quadripôle parfaitement adapté et transparent — rien
% ne réfléchit, tout passe.
S = [0 1; 1 0];
Z = sparam2zparam(S + 1e-9 * eye(2), 50);
fprintf('\nQuadripole adapte et transparent (S = [0 1; 1 0]) :\n');
fprintf('  |Z11| = %.3e ohms : la matrice Z diverge\n', abs(Z(1,1)));
assert(abs(Z(1,1)) > 1e8, 'la ligne parfaite n''a pas de representation Z finie');

% Un atténuateur résistif adapté : il ne réfléchit rien et divise
% l'amplitude. Sa matrice Z existe, et elle est purement réelle — un
% réseau de résistances ne peut rien déphaser.
attenuation = 10 ^ (-6 / 20);            % -6 dB en amplitude, adapte
S = [0 attenuation; attenuation 0];
Z = sparam2zparam(S, 50);
fprintf('  attenuateur adapte de -6 dB : Z11 = %.3f, Z12 = %.3f ohms\n', ...
        real(Z(1,1)), real(Z(1,2)));
assert(max(abs(imag(Z(:)))) < 1e-12, 'un attenuateur resistif est purement reel');
assert(real(Z(1,2)) > 0 && real(Z(1,1)) > 0, 'et ses impedances sont positives');
% Réciproque et symétrique en S, il le reste en Z.
assert(abs(Z(1,2) - Z(2,1)) < 1e-12, 'reciproque : Z12 = Z21');
assert(abs(Z(1,1) - Z(2,2)) < 1e-12, 'symetrique : Z11 = Z22');
% Le calcul se vérifie à la main : Z = Z0/(1-a^2) * [1+a^2, 2a; 2a, 1+a^2].
a = attenuation;
attendu = 50 / (1 - a^2) * [1 + a^2, 2*a; 2*a, 1 + a^2];
fprintf('  contre la forme fermee : ecart %.2e ohm\n', norm(Z - attendu));
assert(norm(Z - attendu) < 1e-10, 'la conversion suit la forme fermee');

%% 6. Un bilan de liaison complet
% Tout se met bout à bout en décibels : c'est là que l'échelle
% logarithmique paie vraiment.
puissanceEmise = 30;                     % dBm
gainEmission = 12;                       % dBi
gainReception = 12;                      % dBi
frequence = 2.4e9;
distance = 1000;
lambda = 3e8 / frequence;
pertes = 20 * log10(4 * pi * distance / lambda);
recue = puissanceEmise + gainEmission + gainReception - pertes;
fprintf('\nBilan de liaison a %g GHz sur %g m :\n', frequence / 1e9, distance);
fprintf('  emis %g dBm, antennes %+g et %+g dBi, espace libre -%.2f dB\n', ...
        puissanceEmise, gainEmission, gainReception, pertes);
fprintf('  recu %.2f dBm, soit %.3e W\n', recue, dbm2w(recue));
assert(abs(pertes - 100.05) < 0.1, 'les pertes en espace libre a 2.4 GHz sur 1 km');
% Le même calcul en watts, sans décibels, doit donner le même résultat.
enWatts = dbm2w(puissanceEmise) * 10^(gainEmission/10) * 10^(gainReception/10) * ...
          (lambda / (4 * pi * distance)) ^ 2;
fprintf('  le meme calcul en watts : %.3e W, ecart relatif %.2e\n', ...
        enWatts, abs(enWatts - dbm2w(recue)) / enWatts);
assert(abs(enWatts - dbm2w(recue)) / enWatts < 1e-12, ...
       'decibels et watts donnent le meme resultat');
% Doubler la distance coûte exactement six décibels.
pertes2 = 20 * log10(4 * pi * 2 * distance / lambda);
fprintf('  doubler la distance coute %.4f dB\n', pertes2 - pertes);
assert(abs((pertes2 - pertes) - 20 * log10(2)) < 1e-12, ...
       'doubler la distance coute 6 dB');

fprintf('\nToutes les verifications passent.\n');
