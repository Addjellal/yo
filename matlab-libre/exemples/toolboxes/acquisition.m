%% Acquisition de données : échantillonner, et les pièges qui vont avec
% Une carte d'acquisition ne fait qu'une chose : prélever la valeur d'une
% tension à intervalles réguliers. Tout ce qui compte tient dans le
% rythme de ces prélèvements — et dans ce qu'on perd à mal le choisir.
%
% Voir aussi DAQ, ADDANALOGINPUT, ADDANALOGOUTPUT, READDATA, WRITEDATA.

fprintf('=== Acquisition de donnees ===\n');

%% 1. Une session, une voie, un bloc d'échantillons
s = daq('simule');
s.frequence = 10000;
s = addAnalogInput(s, 'ai0', @(t) sin(2 * pi * 100 * t));
[donnees, temps] = readData(s, 1000);
fprintf('\nSession a %g kHz, une voie :\n', s.frequence / 1000);
fprintf('  %d echantillons sur %g ms\n', numel(temps), 1000 * temps(end));
assert(size(donnees, 1) == 1000, 'mille echantillons demandes, mille rendus');
assert(size(donnees, 2) == 1, 'une seule voie');
% Le pas d'échantillonnage est l'inverse de la fréquence : c'est la seule
% chose que la fréquence veut dire.
assert(abs(diff(temps(1:2)) - 1 / s.frequence) < 1e-15, ...
       'le pas est l''inverse de la frequence');
assert(abs(temps(end) - 999 / s.frequence) < 1e-15, 'et le dernier instant suit');

% Le signal relevé est bien celui du générateur, prélevé aux instants
% voulus : la fidélité de la mesure, c'est cela et rien d'autre.
assert(max(abs(donnees - sin(2 * pi * 100 * temps))) < 1e-15, ...
       'chaque echantillon est la valeur du signal a son instant');
fprintf('  ecart au signal exact : %.1e\n', ...
        max(abs(donnees - sin(2 * pi * 100 * temps))));
% Mille échantillons à dix kilohertz couvrent 999 pas, soit 99,9 ms — un
% peu moins de dix périodes de cent hertz. Le compte des passages par
% zéro le confirme : deux par période, arrêtés à la durée réelle.
passages = sum(donnees(1:end-1) .* donnees(2:end) < 0);
predits = floor(2 * 100 * temps(end));
fprintf('  %.4f ms couverts, %.2f periodes de 100 Hz\n', ...
        1000 * temps(end), 100 * temps(end));
fprintf('  %d passages par zero (predits : %d)\n', passages, predits);
assert(passages == predits, 'deux passages par zero et par periode');

%% 2. Plusieurs voies
% Les voies se lisent ensemble, une colonne chacune, aux mêmes instants.
% C'est la simultanéité qui fait l'intérêt d'une carte multivoie.
s = daq('simule');
s.frequence = 8000;
s = addAnalogInput(s, 'tension', @(t) 5 * sin(2 * pi * 50 * t));
s = addAnalogInput(s, 'courant', @(t) 0.4 * sin(2 * pi * 50 * t - pi/6));
s = addAnalogInput(s, 'temperature', @(t) 20 + t);
[donnees, temps] = readData(s, 1600);
fprintf('\nTrois voies a %g kHz, %d echantillons :\n', ...
        s.frequence / 1000, size(donnees, 1));
fprintf('  tension %.4f V eff., courant %.4f A eff.\n', ...
        rms(donnees(:,1)), rms(donnees(:,2)));
assert(size(donnees, 2) == 3, 'trois colonnes pour trois voies');
assert(abs(rms(donnees(:,1)) - 5/sqrt(2)) < 0.01, ...
       'la valeur efficace d''un sinus est son amplitude sur racine de deux');

% Le déphasage entre tension et courant se mesure sur les données : c'est
% le facteur de puissance, et il sort d'un simple produit moyen.
puissanceActive = mean(donnees(:,1) .* donnees(:,2));
puissanceApparente = rms(donnees(:,1)) * rms(donnees(:,2));
facteur = puissanceActive / puissanceApparente;
fprintf('  puissance active %.4f W, apparente %.4f VA\n', ...
        puissanceActive, puissanceApparente);
fprintf('  facteur de puissance %.4f (cos(pi/6) = %.4f)\n', ...
        facteur, cos(pi/6));
assert(abs(facteur - cos(pi/6)) < 0.01, ...
       'le facteur de puissance est le cosinus du dephasage');

%% 3. Le repliement, ou pourquoi la fréquence se choisit
% Échantillonner à moins du double de la fréquence du signal ne le
% dégrade pas : il le remplace par un autre. C'est le théorème de
% Shannon, vu du mauvais côté.
vraie = 900;
fprintf('\nUn signal a %g Hz, echantillonne trop lentement :\n', vraie);
for fe = [4000 1000 800]
    s = daq('simule');
    s.frequence = fe;
    s = addAnalogInput(s, 'ai0', @(t) sin(2 * pi * vraie * t));
    [d, t] = readData(s, 4096);
    spectre = abs(fft(d(:, 1)));
    moitie = 1:floor(numel(spectre)/2);
    [~, pic] = max(spectre(moitie));
    apparente = (pic - 1) * fe / numel(spectre);
    % La fréquence apparente est le repliement de la vraie : elle vaut
    % |f - k fe| pour l'entier k qui la ramène dans la bande.
    predite = abs(vraie - round(vraie / fe) * fe);
    fprintf('  a %5g Hz : lue a %6.1f Hz (repliement predit %6.1f Hz)%s\n', ...
            fe, apparente, predite, repere(fe, vraie));
    assert(abs(apparente - predite) < 2, ...
           'la frequence lue est le repliement de la vraie');
end
% Au-dessus du double, aucun repliement : la fréquence lue est la vraie.
s = daq('simule'); s.frequence = 4000;
s = addAnalogInput(s, 'ai0', @(t) sin(2 * pi * vraie * t));
[d, ~] = readData(s, 4096);
spectre = abs(fft(d(:,1)));
[~, pic] = max(spectre(1:2048));
assert(abs((pic - 1) * 4000 / 4096 - vraie) < 2, ...
       'au-dessus de deux fois la frequence, rien ne se replie');

%% 4. Le bruit, et ce que moyenner y fait
% Moyenner N mesures indépendantes divise l'écart type par racine de N.
% C'est la seule façon d'améliorer une mesure sans changer de matériel,
% et la racine explique pourquoi cela devient vite coûteux.
rng(17);
s = daq('simule');
s.frequence = 1000;
s = addAnalogInput(s, 'bruitee', @(t) 2.5 + 0.1 * randn());
fprintf('\nMesure bruitee d''une tension continue de 2.5 V :\n');
precedent = inf;
for n = [1 10 100 1000]
    ecarts = zeros(1, 200);
    for essai = 1:200
        d = readData(s, n);
        ecarts(essai) = mean(d) - 2.5;
    end
    mesure = std(ecarts);
    fprintf('  moyenne de %4d mesures : ecart type %.5f V (theorie %.5f)\n', ...
            n, mesure, 0.1 / sqrt(n));
    assert(abs(mesure - 0.1/sqrt(n)) < 0.3 * 0.1/sqrt(n), ...
           'moyenner N mesures divise l''ecart type par racine de N');
    assert(mesure < precedent, 'et moyenner davantage fait toujours mieux');
    precedent = mesure;
end

%% 5. Les voies de sortie
% Une carte écrit aussi. Ce qu'on lui envoie est mémorisé, ce qui permet
% de vérifier qu'on a bien écrit ce qu'on croyait.
s = daq('simule');
s.frequence = 1000;
s = addAnalogOutput(s, 'ao0');
rampe = linspace(0, 5, 500).';
s = writeData(s, rampe);
fprintf('\nEcriture d''une rampe de %d points :\n', numel(rampe));
fprintf('  %d echantillons ecrits, de %.4f a %.4f V\n', ...
        numel(s.ecrit), s.ecrit(1), s.ecrit(end));
assert(numel(s.ecrit) == 500, 'tout est ecrit');
assert(max(abs(s.ecrit - rampe)) < 1e-15, 'et sans deformation');
% Deux écritures s'accumulent, comme sur une file de sortie réelle.
s = writeData(s, -rampe);
fprintf('  apres une seconde ecriture : %d echantillons\n', numel(s.ecrit));
assert(numel(s.ecrit) == 1000, 'les ecritures s''accumulent');
assert(abs(s.ecrit(end) + 5) < 1e-15, 'et la derniere valeur est la bonne');

fprintf('\nToutes les verifications passent.\n');

function texte = repere(fe, vraie)
% Signale les cas où le théorème de Shannon n'est pas respecté.
    if fe > 2 * vraie
        texte = '';
    else
        texte = '  <- sous le double : repliement';
    end
end
