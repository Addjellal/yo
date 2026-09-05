% ondelettes.m — Wavelet Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/ondelettes.m
%
% Le cas : un signal qui change de fréquence en cours de route, avec un
% saut au milieu. C'est exactement ce que la transformée de Fourier ne
% sait pas décrire — elle dit quelles fréquences sont présentes, jamais
% quand — et ce que les ondelettes sont faites pour voir.

fprintf('=== Ondelettes : voir quand, et pas seulement quoi ===\n\n');

%% 1. Le signal
n = 1024;
t = (0:n - 1)' / n;
signal = [sin(2 * pi * 20 * t(1:n / 2)); sin(2 * pi * 80 * t(n / 2 + 1:end))];
signal(600:end) = signal(600:end) + 1.5;      % un saut de niveau
rng(1);
bruite = signal + 0.25 * randn(n, 1);
fprintf('Signal : %d points, 20 Hz puis 80 Hz, saut a l''indice 600\n', n);

%% 2. Décomposition multirésolution
% WAVEDEC descend d'un niveau à la fois : à chaque étage le signal est
% séparé en une approximation, deux fois plus courte, et un détail.
niveaux = 5;
[coefficients, longueurs] = wavedec(bruite, niveaux, 'db4');
fprintf('\nDecomposition sur %d niveaux (db4) :\n', niveaux);
fprintf('  longueurs : %s\n', mat2str(longueurs));
fprintf('  total des coefficients : %d (signal : %d)\n', numel(coefficients), n);
% La transformée est inversible : reconstruire rend le signal de départ.
% Les coefficients et le signal reconstruit sortent en ligne, quelle que
% soit l'orientation de l'entrée : on compare donc en colonne.
reconstruit = waverec(coefficients, longueurs, 'db4');
fprintf('  reconstruction : ecart max %.3e\n', max(abs(reconstruit(:) - bruite(:))));
assert(max(abs(reconstruit(:) - bruite(:))) < 1e-10);
% L'énergie se conserve : c'est une base orthonormale.
fprintf('  energie : signal %.6f, coefficients %.6f\n', ...
        sum(bruite .^ 2), sum(coefficients .^ 2));
assert(abs(sum(coefficients .^ 2) - sum(bruite .^ 2)) / sum(bruite .^ 2) < 1e-10);

% Chaque niveau porte une bande de fréquences. Le détail de niveau j
% couvre [Fe/2^(j+1), Fe/2^j].
Fe = n;
for j = 1:niveaux
    detail = detcoef(coefficients, longueurs, j);
    bande = [Fe / 2 ^ (j + 1), Fe / 2 ^ j];
    fprintf('  detail %d : %3d coefficients, bande %.0f-%.0f Hz, energie %.2f\n', ...
            j, numel(detail), bande(1), bande(2), sum(detail .^ 2));
end
% Les 80 Hz tombent dans le detail 3 (64-128 Hz), les 20 Hz dans le
% detail 5 (16-32 Hz) : les deux doivent ressortir.
energies = zeros(1, niveaux);
for j = 1:niveaux
    energies(j) = sum(detcoef(coefficients, longueurs, j) .^ 2);
end
[~, dominant] = max(energies(2:end));
fprintf('  niveau de detail le plus energique : %d\n', dominant + 1);

%% 3. Localiser dans le temps
% Un détail reconstruit garde la longueur du signal : on lit alors
% directement où la fréquence est présente.
detail3 = wrcoef('d', coefficients, longueurs, 'db4', 3);
detail3 = detail3(:);
premiereMoitie = sum(detail3(1:n / 2) .^ 2);
secondeMoitie = sum(detail3(n / 2 + 1:end) .^ 2);
fprintf('\nDetail 3 (bande des 80 Hz) :\n');
fprintf('  energie premiere moitie %.3f, seconde moitie %.3f\n', ...
        premiereMoitie, secondeMoitie);
assert(secondeMoitie > 5 * premiereMoitie, ...
       'les 80 Hz sont dans la seconde moitie, et l''ondelette doit le dire');
% Une transformee de Fourier, elle, ne le dirait pas.
spectre = abs(fft(bruite));
fprintf('  la transformee de Fourier voit bien 20 et 80 Hz, sans dire quand :\n');
fprintf('    raie a 20 Hz : %.1f, a 80 Hz : %.1f\n', spectre(21), spectre(81));
assert(spectre(21) > 10 * mean(spectre(2:200)));
assert(spectre(81) > 10 * mean(spectre(2:200)));

%% 4. Débruiter
% Le bruit s'étale sur tous les coefficients ; le signal se concentre sur
% quelques-uns. Mettre à zéro les petits coefficients ôte donc bien plus
% de bruit que de signal — c'est tout le principe du seuillage.
seuil = thselect(coefficients, 'sqtwolog');
debruite = wdenoise(bruite, niveaux, 'Wavelet', 'db4');
debruite = debruite(:);
erreurAvant = norm(bruite - signal) / norm(signal);
erreurApres = norm(debruite - signal) / norm(signal);
fprintf('\nDebruitage :\n');
fprintf('  seuil universel : %.4f\n', seuil);
fprintf('  erreur relative : %.4f -> %.4f (divisee par %.2f)\n', ...
        erreurAvant, erreurApres, erreurAvant / erreurApres);
assert(erreurApres < erreurAvant / 1.3, 'le debruitage doit ameliorer nettement');
% Le saut est préservé : c'est ce qu'un filtre passe-bas détruirait.
sautAvant = signal(605) - signal(595);
sautApres = debruite(605) - debruite(595);
fprintf('  saut de niveau : %.3f dans le vrai signal, %.3f apres debruitage\n', ...
        sautAvant, sautApres);
assert(abs(sautApres - sautAvant) < 0.6, 'le saut doit survivre');

%% 5. Compresser
% Garder les plus gros coefficients, jeter le reste.
[triees, ordre] = sort(abs(coefficients), 'descend');
garde = round(0.05 * numel(coefficients));
comprimes = zeros(size(coefficients));
comprimes(ordre(1:garde)) = coefficients(ordre(1:garde));
approche = waverec(comprimes, longueurs, 'db4');
approche = approche(:);
fprintf('\nCompression a %d %% des coefficients :\n', round(garde / numel(coefficients) * 100));
fprintf('  energie retenue : %.2f %%\n', sum(triees(1:garde) .^ 2) / sum(triees .^ 2) * 100);
fprintf('  erreur relative : %.4f\n', norm(approche - bruite) / norm(bruite));
assert(sum(triees(1:garde) .^ 2) / sum(triees .^ 2) > 0.85, ...
       'un vingtieme des coefficients doit porter l''essentiel de l''energie');

%% 6. Transformée continue
% La transformée discrète donne une octave par niveau. La continue est
% plus fine : autant de voix par octave qu'on veut, au prix de la
% redondance.
banc = cwtfilterbank('SignalLength', n, 'SamplingFrequency', Fe, ...
                     'VoicesPerOctave', 12);
[coefficientsContinus, frequences] = wt(banc, signal);
[~, kDebut] = max(mean(abs(coefficientsContinus(:, 100:400)), 2));
[~, kFin] = max(mean(abs(coefficientsContinus(:, 600:900)), 2));
fprintf('\nTransformee continue :\n');
fprintf('  %d echelles, de %.1f a %.1f Hz\n', numel(frequences), ...
        min(frequences), max(frequences));
fprintf('  frequence dominante debut : %.1f Hz (attendu 20)\n', frequences(kDebut));
fprintf('  frequence dominante fin   : %.1f Hz (attendu 80)\n', frequences(kFin));
assert(abs(log2(frequences(kDebut) / 20)) < 0.2);
assert(abs(log2(frequences(kFin) / 80)) < 0.2);

%% 7. Bancs de filtres
% Ce qu'une ondelette orthogonale garantit : les filtres se partagent
% exactement l'énergie, sans trou ni recouvrement.
bancDiscret = dwtfilterbank('Wavelet', 'sym6', 'SignalLength', n);
[borneBasse, borneHaute] = framebounds(bancDiscret);
fprintf('\nBanc de filtres discret (sym6) :\n');
fprintf('  bornes du repere : %.12f et %.12f\n', borneBasse, borneHaute);
assert(abs(borneBasse - 1) < 1e-9 && abs(borneHaute - 1) < 1e-9);
q = qfactor(bancDiscret);
fprintf('  facteurs de qualite : %s\n', mat2str(round(q', 2)));
assert(std(q) / mean(q) < 0.15, 'le facteur de qualite ne depend pas du niveau');

fprintf('\nToutes les verifications passent.\n');
