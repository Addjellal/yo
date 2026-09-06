%% Simscape : circuits électriques résolus par les lois de Kirchhoff
% Décrire un circuit, non les équations qui le régissent : c'est tout le
% propos. On pose des composants entre des nœuds, et l'analyse nodale
% modifiée écrit et résout le système à notre place.
%
% Voir aussi CIRCUIT, ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR,
% ADDVOLTAGESOURCE, ADDCURRENTSOURCE, SOLVEDC, SOLVETRANSIENT.

fprintf('=== Simscape : circuits electriques ===\n');

%% 1. Le pont diviseur, cas d'école s'il en est
% Deux résistances en série sur une source : la tension au point milieu
% vaut E R2 / (R1 + R2). C'est la première formule de tout cours
% d'électricité, et le solveur doit la retrouver sans qu'on la lui dise.
E = 10;
R1 = 1000;
R2 = 2000;
c = circuit('diviseur');
c = addVoltageSource(c, 1, 0, E);
c = addResistor(c, 1, 2, R1);
c = addResistor(c, 2, 0, R2);
[v, i] = solveDC(c);
fprintf('\nPont diviseur %g V, %g et %g ohms :\n', E, R1, R2);
fprintf('  V1 = %.4f V, V2 = %.4f V (formule : %.4f V)\n', ...
        v(1), v(2), E * R2 / (R1 + R2));
assert(abs(v(1) - E) < 1e-12, 'le noeud 1 est au potentiel de la source');
assert(abs(v(2) - E * R2 / (R1 + R2)) < 1e-12, 'le point milieu suit la formule');
% Le courant débité est celui de la loi d'Ohm sur la série, compté
% positivement quand il sort de la borne moins de la source.
fprintf('  courant %.6f mA (E/(R1+R2) = %.6f mA)\n', ...
        1000 * abs(i(1)), 1000 * E / (R1 + R2));
assert(abs(abs(i(1)) - E / (R1 + R2)) < 1e-12, 'le courant est celui de la serie');
% La loi des nœuds se vérifie : ce qui entre en 2 en ressort.
fprintf('  loi des noeuds en 2 : %.2e A de residu\n', ...
        (v(1) - v(2)) / R1 - v(2) / R2);
assert(abs((v(1) - v(2))/R1 - v(2)/R2) < 1e-15, 'la loi des noeuds est tenue');

%% 2. Résistances en série et en parallèle
% Les deux règles que tout le monde connaît, retrouvées par le solveur.
serie = circuit('serie');
serie = addVoltageSource(serie, 1, 0, 12);
serie = addResistor(serie, 1, 2, 100);
serie = addResistor(serie, 2, 3, 220);
serie = addResistor(serie, 3, 0, 330);
[~, iSerie] = solveDC(serie);
fprintf('\nTrois resistances en serie sur 12 V :\n');
fprintf('  courant %.6f mA, equivalent %.1f ohms (100+220+330 = 650)\n', ...
        1000 * abs(iSerie(1)), 12 / abs(iSerie(1)));
assert(abs(12 / abs(iSerie(1)) - 650) < 1e-9, 'les resistances en serie s''ajoutent');

parallele = circuit('parallele');
parallele = addVoltageSource(parallele, 1, 0, 12);
parallele = addResistor(parallele, 1, 0, 100);
parallele = addResistor(parallele, 1, 0, 220);
parallele = addResistor(parallele, 1, 0, 330);
[~, iPar] = solveDC(parallele);
equivalent = 1 / (1/100 + 1/220 + 1/330);
fprintf('  en parallele : equivalent %.4f ohms (formule %.4f)\n', ...
        12 / abs(iPar(1)), equivalent);
assert(abs(12 / abs(iPar(1)) - equivalent) < 1e-9, ...
       'en parallele, ce sont les conductances qui s''ajoutent');

%% 3. Une source de courant, et le théorème de superposition
% Une source de courant dans une résistance impose la tension R I. Et
% deux sources agissant ensemble donnent la somme de ce que chacune
% donnerait seule : c'est la superposition, propre aux circuits linéaires.
c = circuit('courant');
c = addCurrentSource(c, 0, 1, 0.005);
c = addResistor(c, 1, 0, 1000);
v = solveDC(c);
fprintf('\nSource de courant de 5 mA dans 1 kohm :\n');
fprintf('  tension %.4f V (R I = %.4f V)\n', v(1), 1000 * 0.005);
assert(abs(v(1) - 5) < 1e-12, 'une source de courant impose R I');

% Superposition sur un circuit à deux sources.
pont = @(Ea, Eb) addResistor(addResistor(addResistor( ...
            addVoltageSource(addVoltageSource(circuit('deux'), 1, 0, Ea), ...
                             3, 0, Eb), 1, 2, 1000), 2, 0, 2200), 3, 2, 470);
vAB = solveDC(pont(10, 4));
vA = solveDC(pont(10, 0));
vB = solveDC(pont(0, 4));
fprintf('  superposition : %.6f V ensemble, %.6f + %.6f = %.6f separement\n', ...
        vAB(2), vA(2), vB(2), vA(2) + vB(2));
assert(abs(vAB(2) - (vA(2) + vB(2))) < 1e-12, ...
       'un circuit lineaire superpose ses sources');

%% 4. La charge d'un condensateur
% Le RC est le premier circuit dynamique du cours. La tension monte en
% 1 - exp(-t/RC) : à une constante de temps, 63,2 % de la valeur finale ;
% à cinq, 99,3 %.
R = 1000;
C = 1e-6;
tau = R * C;
c = circuit('rc');
c = addVoltageSource(c, 1, 0, 5);
c = addResistor(c, 1, 2, R);
c = addCapacitor(c, 2, 0, C);
[t, v] = solveTransient(c, 10 * tau, tau / 400);
sortie = v(:, 2);
fprintf('\nCharge d''un RC (%g kohm, %g uF, tau = %g ms) :\n', ...
        R / 1000, C * 1e6, tau * 1000);
theorique = 5 * (1 - exp(-t / tau));
for multiple = [1 3 5]
    [~, indice] = min(abs(t - multiple * tau));
    fprintf('  a %d tau : %.4f V (theorie %.4f V, soit %.1f %%)\n', ...
            multiple, sortie(indice), theorique(indice), ...
            100 * theorique(indice) / 5);
end
[~, unTau] = min(abs(t - tau));
assert(abs(sortie(unTau) / 5 - (1 - exp(-1))) < 0.01, ...
       'a une constante de temps, 63,2 %% de la valeur finale');
assert(abs(sortie(end) - 5) < 0.02, 'la charge tend vers la tension de source');
assert(max(abs(sortie - theorique)) < 0.02, ...
       'toute la courbe suit l''exponentielle');
fprintf('  ecart maximal a l''exponentielle : %.4f V\n', ...
        max(abs(sortie - theorique)));

% En régime continu établi, le condensateur est un circuit ouvert : plus
% aucun courant, et la tension à ses bornes vaut celle de la source.
vDC = solveDC(c);
fprintf('  regime etabli, calcule directement : %.6f V\n', vDC(2));
assert(abs(vDC(2) - 5) < 1e-12, 'en continu, le condensateur est ouvert');

%% 5. Le circuit RLC, et ses trois régimes
% Le RLC série est le second ordre canonique. Son amortissement
% zeta = R/2 sqrt(C/L) décide de tout : au-dessus de un il ne dépasse
% jamais, en dessous il oscille.
L = 1e-3;
C = 1e-6;
omega0 = 1 / sqrt(L * C);
critique = 2 * sqrt(L / C);
fprintf('\nRLC serie (%g mH, %g uF) : f0 = %.1f Hz, R critique = %.1f ohms\n', ...
        L * 1000, C * 1e6, omega0 / (2 * pi), critique);
for R = [critique * 3, critique, critique / 20]
    zeta = R / 2 * sqrt(C / L);
    c = circuit('rlc');
    c = addVoltageSource(c, 1, 0, 1);
    c = addResistor(c, 1, 2, R);
    c = addInductor(c, 2, 3, L);
    c = addCapacitor(c, 3, 0, C);
    [t, v] = solveTransient(c, 20 * 2 * pi / omega0, 2 * pi / omega0 / 200);
    sortie = v(:, 3);
    depassement = max(sortie) - 1;
    fprintf('  R = %7.2f ohms, zeta = %.3f : depassement %+.4f V\n', ...
            R, zeta, depassement);
    if zeta > 1.05
        assert(depassement < 0.01, 'suramorti : aucun depassement');
    elseif zeta < 0.2
        % Sous-amorti : le dépassement suit exp(-pi zeta / sqrt(1-zeta^2)).
        attendu = exp(-pi * zeta / sqrt(1 - zeta^2));
        fprintf('    depassement theorique %.4f, mesure %.4f\n', attendu, depassement);
        assert(abs(depassement - attendu) < 0.1, ...
               'le depassement suit la formule du second ordre');
    end
    assert(abs(sortie(end) - 1) < 0.15, 'la tension finit sur la source');
end

% Et la pulsation propre se lit sur les oscillations du cas peu amorti.
R = critique / 20;
c = circuit('rlc');
c = addVoltageSource(c, 1, 0, 1);
c = addResistor(c, 1, 2, R);
c = addInductor(c, 2, 3, L);
c = addCapacitor(c, 3, 0, C);
[t, v] = solveTransient(c, 10 * 2 * pi / omega0, 2 * pi / omega0 / 400);
sortie = v(:, 3);
sommets = find(sortie(2:end-1) > sortie(1:end-2) & sortie(2:end-1) > sortie(3:end)) + 1;
if numel(sommets) >= 3
    periode = mean(diff(t(sommets)));
    fprintf('  periode mesuree %.6f ms, theorie 2 pi / omega0 = %.6f ms\n', ...
            periode * 1000, 2 * pi / omega0 * 1000);
    assert(abs(periode - 2 * pi / omega0) / periode < 0.05, ...
           'la periode est celle de la pulsation propre');
end

%% 6. Une source variable dans le temps
% SOLVETRANSIENT accepte une poignée qui module les sources : c'est ainsi
% qu'on excite un circuit par autre chose qu'un échelon. Sur un RC
% attaqué à une fréquence bien au-dessus de sa coupure, l'atténuation
% doit valoir 1/sqrt(1 + (f/fc)^2).
R = 1000;
C = 1e-7;
fc = 1 / (2 * pi * R * C);
f = 10 * fc;
c = circuit('passe-bas');
c = addVoltageSource(c, 1, 0, 1);
c = addResistor(c, 1, 2, R);
c = addCapacitor(c, 2, 0, C);
[t, v] = solveTransient(c, 20 / f, 1 / f / 200, @(temps) sin(2 * pi * f * temps));
regime = t > 10 / f;
amplitude = (max(v(regime, 2)) - min(v(regime, 2))) / 2;
attendue = 1 / sqrt(1 + (f / fc) ^ 2);
fprintf('\nPasse-bas RC, coupure %.0f Hz, excite a %.0f Hz :\n', fc, f);
fprintf('  amplitude en sortie %.4f, attendue %.4f (soit %.1f dB)\n', ...
        amplitude, attendue, 20 * log10(attendue));
assert(abs(amplitude - attendue) / attendue < 0.1, ...
       'l''attenuation suit la reponse en frequence du premier ordre');
% À la coupure exactement, l'atténuation vaut 1/racine de deux.
[t, v] = solveTransient(c, 40 / fc, 1 / fc / 200, @(temps) sin(2 * pi * fc * temps));
regime = t > 20 / fc;
amplitude = (max(v(regime, 2)) - min(v(regime, 2))) / 2;
fprintf('  a la coupure : %.4f (1/racine(2) = %.4f)\n', amplitude, 1/sqrt(2));
assert(abs(amplitude - 1/sqrt(2)) < 0.03, ...
       'a la coupure, l''attenuation vaut 3 dB');



fprintf('\nToutes les verifications passent.\n');
