% dsp.m — DSP System Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/dsp.m
%
% Le cas : les outils du traitement du signal en temps réel — filtrer par
% blocs, prédire linéairement, changer la cadence. Ce qui les distingue
% du traitement hors ligne : ils travaillent sur un flux, sans voir tout
% le signal.

fprintf('=== DSP : filtrer par blocs, predire, reechantillonner ===\n\n');

%% 1. Le filtrage rapide par blocs
% Convoluer un long signal par un filtre coûte O(N M). Découper le signal
% et passer par la transformée de Fourier ramène cela à O(N log M) : c'est
% ce que fait FFTFILT, et c'est ce qui rend le filtrage temps réel
% possible sur de longs filtres.
rng(1);
signal = randn(4096, 1);
filtre = fir1(64, 0.3);
parBlocs = fftfilt(filtre, signal);
direct = filter(filtre, 1, signal);
fprintf('Filtrage par blocs :\n');
fprintf('  signal %d points, filtre %d coefficients\n', numel(signal), numel(filtre));
fprintf('  ecart au filtrage direct : %.3e\n', max(abs(parBlocs - direct)));
assert(max(abs(parBlocs - direct)) < 1e-10, ...
       'le decoupage ne doit rien changer au resultat');
% La longueur est preservee : c'est ce qu'on attend d'un filtre.
assert(numel(parBlocs) == numel(signal));

%% 2. La prédiction linéaire
% Prédire l'échantillon suivant depuis les précédents. C'est le cœur du
% codage de la parole : au lieu de transmettre le signal, on transmet les
% coefficients du prédicteur et l'erreur, bien plus petite.
rng(2);
excitation = randn(2000, 1);
vraiFiltre = [1 -1.6 0.9];
parole = filter(1, vraiFiltre, excitation);
ordre = 2;
[coefficients, variance] = lpc(parole, ordre);
fprintf('\nPrediction lineaire d''ordre %d :\n', ordre);
fprintf('  coefficients trouves %s\n', mat2str(round(coefficients, 4)));
fprintf('  vrais                %s\n', mat2str(vraiFiltre));
assert(max(abs(coefficients - vraiFiltre)) < 0.05);
% L'erreur de prediction est bien plus petite que le signal : c'est tout
% le gain du codage.
erreur = filter(coefficients, 1, parole);
fprintf('  ecart type : signal %.4f, erreur de prediction %.4f\n', ...
        std(parole), std(erreur));
fprintf('  gain de prediction : %.2f dB\n', 20 * log10(std(parole) / std(erreur)));
assert(std(erreur) < std(parole) / 3, 'le predicteur doit gagner nettement');
% La variance rendue est celle de l'erreur.
assert(abs(sqrt(variance) - std(erreur)) / std(erreur) < 0.1);
% Le filtre trouve est stable : ses poles sont dans le disque unite. La
% recurrence de Levinson le garantit, ce qu'une resolution directe des
% moindres carres ne garantirait pas.
assert(all(abs(roots(coefficients)) < 1), ...
       'Levinson rend toujours un predicteur stable');

%% 3. La récurrence de Levinson
% Résoudre un système de Toeplitz en O(n²) au lieu de O(n³). C'est ce qui
% rend la prédiction linéaire calculable en temps réel.
autocorrelations = xcorr(parole, ordre, 'biased');
r = autocorrelations(ordre + 1:end);
parLevinson = levinson(r, ordre);
fprintf('\nLevinson directement sur l''autocorrelation :\n');
fprintf('  %s\n', mat2str(round(parLevinson, 6)));
assert(max(abs(parLevinson - coefficients)) < 1e-9, ...
       'LPC n''est que LEVINSON sur l''autocorrelation');

%% 4. Le changement de cadence
% Monter d'un facteur L et descendre d'un facteur M, en une seule
% opération. Faire les deux séparément coûterait beaucoup plus : le
% signal intermédiaire serait L fois plus long.
rng(3);
court = sin(2 * pi * 0.05 * (0:499)');
reechantillonne = upfirdn(court, fir1(32, 0.4), 3, 2);
fprintf('\nChangement de cadence 3/2 :\n');
fprintf('  %d points -> %d points\n', numel(court), numel(reechantillonne));
attendu = ceil(numel(court) * 3 / 2);
assert(abs(numel(reechantillonne) - attendu) < 40, ...
       'la longueur suit le rapport des facteurs');
% Le contenu frequentiel est preserve : la raie se retrouve a la
% frequence correspondante.
[~, kAvant] = max(abs(fft(court)));
[~, kApres] = max(abs(fft(reechantillonne)));
frequenceAvant = (kAvant - 1) / numel(court);
frequenceApres = (kApres - 1) / numel(reechantillonne);
fprintf('  raie : %.4f puis %.4f cycles par echantillon\n', ...
        frequenceAvant, frequenceApres);
assert(abs(frequenceApres - frequenceAvant * 2 / 3) < 0.005, ...
       'la frequence relative est divisee par le rapport de cadence');

%% 5. Le filtre à moindres carrés
% Approcher un gabarit de réponse en fréquence au sens des moindres
% carrés, plutôt que par fenêtrage. On contrôle alors ce qu'on
% sacrifie — et où.
gabarit = firls(40, [0 0.3 0.4 1], [1 1 0 0]);
[reponse, pulsations] = freqz(gabarit, 1, 1024);
gain = abs(reponse);
dansBande = pulsations / pi < 0.3;
horsBande = pulsations / pi > 0.4;
fprintf('\nFiltre a moindres carres, ordre 40 :\n');
fprintf('  gain dans la bande : de %.4f a %.4f\n', ...
        min(gain(dansBande)), max(gain(dansBande)));
fprintf('  gain hors bande    : au plus %.5f (%.1f dB)\n', ...
        max(gain(horsBande)), 20 * log10(max(gain(horsBande))));
assert(min(gain(dansBande)) > 0.9);
assert(max(gain(horsBande)) < 0.1);
% Un filtre a phase lineaire est symetrique : c'est ce qui garantit que
% toutes les frequences subissent le meme retard.
assert(max(abs(gabarit - fliplr(gabarit))) < 1e-12, ...
       'la symetrie donne la phase lineaire');
% Ce que « moindres carres » veut dire : la methode minimise l'energie de
% l'ecart, non son maximum. Ponderer une bande y ramene l'attention, au
% detriment de l'autre — c'est le seul reglage disponible, et il montre
% bien l'arbitrage.
pondere = firls(40, [0 0.3 0.4 1], [1 1 0 0], [1 100]);
[reponsePonderee, pulsationsPonderees] = freqz(pondere, 1, 1024);
gainPondere = abs(reponsePonderee);
horsPondere = pulsationsPonderees / pi > 0.4;
dansPondere = pulsationsPonderees / pi < 0.3;
fprintf('  avec un poids de 100 hors bande : coupee a %.5f (%.1f dB)\n', ...
        max(gainPondere(horsPondere)), 20 * log10(max(gainPondere(horsPondere))));
fprintf('  ondulation dans la bande : %.4f contre %.4f\n', ...
        max(gainPondere(dansPondere)) - min(gainPondere(dansPondere)), ...
        max(gain(dansBande)) - min(gain(dansBande)));
assert(max(gainPondere(horsPondere)) < max(gain(horsBande)), ...
       'ponderer la bande coupee l''ameliore');
assert(max(gainPondere(dansPondere)) - min(gainPondere(dansPondere)) > ...
       max(gain(dansBande)) - min(gain(dansBande)), ...
       'et degrade l''autre : c''est l''arbitrage');
% Le gabarit n'a pas besoin d'etre constant par bande : un derivateur se
% demande directement.
derivateur = firls(30, [0 0.9], [0 0.9]);
[reponseDeriv, pulsationsDeriv] = freqz(derivateur, 1, 512);
utile = pulsationsDeriv / pi < 0.8;
fprintf('  derivateur : ecart maximal au gabarit %.4f\n', ...
        max(abs(abs(reponseDeriv(utile)) - pulsationsDeriv(utile) / pi)));
assert(max(abs(abs(reponseDeriv(utile)) - pulsationsDeriv(utile) / pi)) < 0.05);

%% 6. Ôter la composante continue
% Un filtre d'ordre un, réglé pour ne rien laisser passer à fréquence
% nulle et presque tout ailleurs. C'est le premier étage de toute chaîne
% d'acquisition.
avecOffset = 5 + sin(2 * pi * 0.05 * (0:1999)');
sansOffset = dcblock(avecOffset, 0.99);
etabli = 500:2000;
fprintf('\nSuppression de la composante continue (alpha = 0.99) :\n');
fprintf('  moyenne : %.4f -> %.6f\n', mean(avecOffset), mean(sansOffset(etabli)));
assert(abs(mean(sansOffset(etabli))) < 0.05, ...
       'la composante continue doit disparaitre');
% Le signal utile, lui, reste : son amplitude est preservee.
fprintf('  amplitude de l''alternatif : %.4f -> %.4f\n', ...
        std(avecOffset), std(sansOffset(etabli)));
assert(abs(std(sansOffset(etabli)) / std(avecOffset) - 1) < 0.1);
% L'arbitrage : un pole plus proche de un touche moins le signal utile,
% mais met bien plus longtemps a s'etablir. La duree du transitoire vaut
% environ 1/(1-alpha) echantillons.
fprintf('  duree du transitoire :\n');
for alpha = [0.9 0.99 0.999]
    essai = dcblock(avecOffset, alpha);
    etabliDes = find(abs(movmean(essai, 100)) < 0.05, 1);
    fprintf('    alpha = %-6g : etabli vers l''echantillon %4d (1/(1-a) = %d)\n', ...
            alpha, etabliDes, round(1 / (1 - alpha)));
end
% Un pole hors de ]0,1[ n'a pas de sens : le filtre serait instable.
refusePole = false;
try
    dcblock(avecOffset, 1.1);
catch
    refusePole = true;
end
assert(refusePole);

fprintf('\nToutes les verifications passent.\n');
