%% Communications sans fil : OFDM, canal, capacité
% Un canal radio n'est pas un fil : il atténue, il retarde par plusieurs
% chemins, et il varie. L'OFDM répond au multitrajet en découpant la bande
% en sous-porteuses assez étroites pour que chacune voie un canal plat.
%
% Voir aussi OFDMMOD, OFDMDEMOD, EVM, PATHLOSS, RAYLEIGHCHANNEL,
% THROUGHPUTSHANNON.

fprintf('=== Communications sans fil ===\n');

%% 1. L'affaiblissement de parcours
% En espace libre, la puissance décroît comme le carré de la distance :
% six décibels par doublement. En ville, l'exposant monte à trois ou
% quatre, et chaque doublement coûte alors neuf ou douze décibels.
frequence = 2.4e9;
fprintf('\nAffaiblissement a %g GHz :\n', frequence / 1e9);
for exposant = [2 3 4]
    L100 = pathLoss(100, frequence, exposant);
    L200 = pathLoss(200, frequence, exposant);
    fprintf('  exposant %g : %.2f dB a 100 m, %.2f dB a 200 m (+%.2f dB)\n', ...
            exposant, L100, L200, L200 - L100);
    assert(abs((L200 - L100) - 10 * exposant * log10(2)) < 1e-9, ...
           'chaque doublement coute 10 n log 2 decibels');
end
% À un mètre et en espace libre, l'affaiblissement vaut 20 log(4 pi / lambda).
lambda = 299792458 / frequence;
fprintf('  reference a 1 m : %.2f dB (20 log(4 pi / lambda) = %.2f)\n', ...
        pathLoss(1, frequence), 20 * log10(4 * pi / lambda));
assert(abs(pathLoss(1, frequence) - 20 * log10(4 * pi / lambda)) < 1e-12, ...
       'la reference a un metre suit la formule');
% Monter en fréquence coûte aussi : à distance égale, doubler la
% fréquence coûte six décibels de plus.
fprintf('  doubler la frequence coute %.2f dB\n', ...
        pathLoss(100, 2 * frequence) - pathLoss(100, frequence));
assert(abs(pathLoss(100, 2*frequence) - pathLoss(100, frequence) - 20*log10(2)) < 1e-9, ...
       'doubler la frequence coute 6 dB');

%% 2. La capacité de Shannon
% Elle borne tout : aucun codage, aussi ingénieux soit-il, ne peut faire
% passer plus de bits par seconde. Doubler la bande double la capacité ;
% doubler le rapport signal à bruit ne fait qu'ajouter un bit par hertz.
B = 20e6;
fprintf('\nCapacite de Shannon sur %g MHz :\n', B / 1e6);
for snr = [0 10 20 30]
    fprintf('  a %2g dB de RSB : %.2f Mbit/s (%.2f bit/s/Hz)\n', ...
            snr, throughputShannon(B, snr) / 1e6, throughputShannon(1, snr));
end
assert(abs(throughputShannon(B, 0) - B) < 1e-6, ...
       'a 0 dB de RSB, un bit par seconde et par hertz');
assert(abs(throughputShannon(2*B, 10) - 2 * throughputShannon(B, 10)) < 1e-6, ...
       'la capacite est proportionnelle a la bande');
% Aux grands RSB, chaque triplement de puissance ajoute environ un bit et
% demi ; plus précisément, 3 dB de plus donnent un bit de plus par hertz.
gain = throughputShannon(1, 33) - throughputShannon(1, 30);
fprintf('  3 dB de plus a haut RSB : %.4f bit/s/Hz de gagne\n', gain);
assert(abs(gain - 1) < 0.01, 'a haut RSB, 3 dB valent un bit par hertz');
% Il n'y a pas de capacité négative : à RSB très bas, elle tend vers zéro
% sans jamais s'annuler.
assert(throughputShannon(B, -30) > 0, 'la capacite reste positive');
assert(throughputShannon(B, -30) < B / 100, 'mais devient negligeable');

%% 3. OFDM : moduler et démoduler
% Chaque colonne de symboles devient un symbole OFDM temporel. Sans canal,
% la démodulation doit rendre exactement ce qu'on a mis.
rng(21);
nfft = 64;
nPorteuses = 48;
nSymboles = 20;
prefixe = 16;

% Des symboles QPSK sur les porteuses utiles.
bits = randi([0 3], nPorteuses, nSymboles);
symboles = exp(1i * (pi/4 + bits * pi/2));

signal = ofdmMod(symboles, nfft, prefixe);
recus = ofdmDemod(signal, nfft, prefixe, nPorteuses);
fprintf('\nOFDM : %d porteuses sur %d points, prefixe de %d :\n', ...
        nPorteuses, nfft, prefixe);
fprintf('  %d echantillons pour %d symboles (%d par symbole)\n', ...
        numel(signal), nSymboles, nfft + prefixe);
assert(numel(signal) == nSymboles * (nfft + prefixe), ...
       'chaque symbole occupe NFFT + prefixe echantillons');
fprintf('  aller-retour sans canal : EVM %.2e %%\n', evm(recus, symboles));
assert(evm(recus, symboles) < 1e-10, ...
       'sans canal, la demodulation rend exactement les symboles');

%% 4. Pourquoi le préfixe cyclique
% Un canal multitrajet étale chaque symbole sur le suivant. Le préfixe
% cyclique absorbe cet étalement : tant qu'il est plus long que le canal,
% l'interférence entre symboles disparaît, et le canal devient une simple
% multiplication porteuse par porteuse.
canal = [1; 0.5; -0.3; 0.15];                     % 4 coefficients
fprintf('\nCanal a %d trajets, prefixe de %d :\n', numel(canal), prefixe);

apresCanal = conv(signal, canal);
apresCanal = apresCanal(1:numel(signal));
recus = ofdmDemod(apresCanal, nfft, prefixe, nPorteuses);
% La réponse du canal aux fréquences des porteuses.
H = fft(canal, nfft);
H = H(1:nPorteuses);
egalises = recus ./ H;
fprintf('  sans egalisation : EVM %.2f %%\n', evm(recus, symboles));
fprintf('  apres egalisation a un coefficient : EVM %.2e %%\n', ...
        evm(egalises(:, 2:end), symboles(:, 2:end)));
assert(evm(recus, symboles) > 20, 'le canal deforme fortement les symboles');
assert(evm(egalises(:, 2:end), symboles(:, 2:end)) < 1e-9, ...
       'un seul coefficient par porteuse suffit a annuler le canal');

% Le premier symbole aussi, alors que rien ne le précède : son préfixe
% est sa propre fin, et le transitoire du canal est entièrement contenu
% dans les premiers échantillons du préfixe, qui sont jetés. C'est ce qui
% rend le procédé autonome, symbole par symbole.
fprintf('  y compris le premier symbole : EVM %.2e %%\n', ...
        evm(egalises(:, 1), symboles(:, 1)));
assert(evm(egalises(:, 1), symboles(:, 1)) < 1e-9, ...
       'le prefixe rend chaque symbole independant de ce qui precede');

% Un préfixe trop court laisse passer l'interférence : c'est exactement la
% limite que le dimensionnement doit respecter.
court = 2;
signalCourt = ofdmMod(symboles, nfft, court);
apres = conv(signalCourt, canal);
apres = apres(1:numel(signalCourt));
recusCourt = ofdmDemod(apres, nfft, court, nPorteuses);
egalisesCourt = recusCourt ./ H;
fprintf('  prefixe de %d, plus court que le canal : EVM %.2f %%\n', ...
        court, evm(egalisesCourt(:, 2:end), symboles(:, 2:end)));
assert(evm(egalisesCourt(:, 2:end), symboles(:, 2:end)) > 1, ...
       'un prefixe trop court laisse passer l''interference entre symboles');

%% 5. Le canal de Rayleigh
% Quand aucun trajet ne domine, la somme de nombreux trajets indépendants
% donne un gain complexe gaussien : c'est le canal de Rayleigh, dont
% l'amplitude suit la loi du même nom.
rng(31);
n = 200000;
amplitudes = zeros(1, n);
for k = 1:n
    [~, h] = rayleighChannel(1, 1);
    amplitudes(k) = abs(h);
end
fprintf('\nCanal de Rayleigh, %d tirages :\n', n);
fprintf('  E[|h|^2] = %.4f (attendu 1)\n', mean(amplitudes .^ 2));
assert(abs(mean(amplitudes .^ 2) - 1) < 0.02, ...
       'la puissance moyenne du canal est normalisee a un');
% Moyenne de la loi de Rayleigh de paramètre sigma : sigma sqrt(pi/2).
% Ici E[|h|^2] = 2 sigma^2 = 1, donc sigma = 1/sqrt(2) et la moyenne
% vaut sqrt(pi)/2 = 0.8862.
fprintf('  E[|h|] = %.4f (loi de Rayleigh : %.4f)\n', ...
        mean(amplitudes), sqrt(pi) / 2);
assert(abs(mean(amplitudes) - sqrt(pi)/2) < 0.01, ...
       'l''amplitude suit bien une loi de Rayleigh');
% Sa médiane vaut sigma sqrt(2 ln 2) = sqrt(ln 2) = 0.8326.
fprintf('  mediane %.4f (attendue %.4f)\n', median(amplitudes), sqrt(log(2)));
assert(abs(median(amplitudes) - sqrt(log(2))) < 0.01, 'mediane conforme');
% Les évanouissements profonds sont fréquents : c'est ce qui rend la
% diversité indispensable. P(|h|^2 < x) = 1 - exp(-x).
for seuil = [0.1 0.01]
    proportion = mean(amplitudes .^ 2 < seuil);
    fprintf('  P(|h|^2 < %.2f) = %.4f (theorie : %.4f)\n', ...
            seuil, proportion, 1 - exp(-seuil));
    assert(abs(proportion - (1 - exp(-seuil))) < 0.005, ...
           'la puissance suit une loi exponentielle');
end

% Avec plusieurs trajets, le canal devient sélectif en fréquence : sa
% réponse n'est plus plate, et c'est précisément ce que l'OFDM sait
% traiter porteuse par porteuse.
rng(41);
[~, h] = rayleighChannel(1, 8);
H8 = abs(fft(h, nfft));
fprintf('  a 8 trajets : reponse en frequence de %.3f a %.3f\n', ...
        min(H8), max(H8));
assert(max(H8) / min(H8) > 3, ...
       'le canal multitrajet est selectif : certaines porteuses sont noyees');
[~, h1] = rayleighChannel(1, 1);
H1 = abs(fft(h1, nfft));
assert(std(H1) < 1e-12, 'a un seul trajet, le canal est plat');
fprintf('  a 1 trajet : reponse plate (ecart type %.2e)\n', std(H1));

%% 6. L'EVM comme mesure de qualité
% L'amplitude du vecteur d'erreur rapporte l'erreur à la référence. Elle
% se relie directement au rapport signal à bruit : EVM en pour cent vaut
% cent fois l'inverse de la racine du RSB.
rng(51);
reference = exp(1i * 2 * pi * rand(1, 100000));
fprintf('\nEVM contre RSB :\n');
for snrdB = [10 20 30]
    sigma = 10 ^ (-snrdB / 20);
    bruite = reference + sigma * (randn(1, 100000) + 1i * randn(1, 100000)) / sqrt(2);
    mesure = evm(bruite, reference);
    fprintf('  RSB %2g dB : EVM %.3f %% (predit %.3f %%)\n', ...
            snrdB, mesure, 100 * sigma);
    assert(abs(mesure - 100 * sigma) < 0.05 * 100 * sigma, ...
           'l''EVM vaut l''inverse de la racine du RSB');
end
assert(evm(reference, reference) < 1e-12, 'sans erreur, l''EVM est nulle');

fprintf('\nToutes les verifications passent.\n');
