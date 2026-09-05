% signal.m — Signal Processing Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/signal.m
%
% Le cas : une sinusoïde noyée dans du bruit et parasitée par le
% cinquante hertz du secteur. C'est le problème d'école du traitement du
% signal — le retrouver, le mesurer, le nettoyer.

fprintf('=== Signal : retrouver une sinusoide dans le bruit ===\n\n');

%% 1. Le signal
Fe = 1000;                       % fréquence d'échantillonnage, Hz
duree = 2;                       % secondes
t = (0:1 / Fe:duree - 1 / Fe)';
utile = 1.0 * sin(2 * pi * 120 * t);      % ce qu'on cherche
secteur = 0.7 * sin(2 * pi * 50 * t);     % ce qui parasite
rng(1);
bruit = 0.5 * randn(size(t));
x = utile + secteur + bruit;
fprintf('Signal : %d points a %g Hz, soit %g s\n', numel(t), Fe, duree);
fprintf('  ecart type total %.4f, dont utile %.4f\n', std(x), std(utile));

%% 2. Le spectre
% La transformée de Fourier dit où est l'énergie. On la lit sur un seul
% côté et on la met à l'échelle du signal : une sinusoïde d'amplitude A
% doit y culminer à A.
N = numel(x);
spectre = fft(x);
moitie = 1:floor(N / 2) + 1;
amplitude = abs(spectre(moitie)) / N * 2;
amplitude(1) = amplitude(1) / 2;
frequences = (moitie - 1)' * Fe / N;
[~, kSecteur] = min(abs(frequences - 50));
[~, kUtile] = min(abs(frequences - 120));
fprintf('\nSpectre :\n');
fprintf('  raie a  50 Hz : amplitude %.3f (attendu 0.70)\n', amplitude(kSecteur));
fprintf('  raie a 120 Hz : amplitude %.3f (attendu 1.00)\n', amplitude(kUtile));
assert(abs(amplitude(kSecteur) - 0.7) < 0.1);
assert(abs(amplitude(kUtile) - 1.0) < 0.1);

% La densité spectrale de puissance, plus lisible sur du bruit.
[dsp, fDsp] = pwelch(x, hamming(256), 128, 512, Fe);
[~, kPic] = max(dsp);
fprintf('  pic de la densite spectrale : %.1f Hz\n', fDsp(kPic));
assert(abs(fDsp(kPic) - 120) < 5 || abs(fDsp(kPic) - 50) < 5);

%% 3. Le filtre coupe-bande
% Pour ôter le secteur sans toucher au reste : un coupe-bande étroit
% autour de cinquante hertz. L'ordre décide de la raideur, la largeur de
% ce qu'on sacrifie autour.
[bCoupe, aCoupe] = butter(2, [48 52] / (Fe / 2), 'stop');
sansSecteur = filtfilt(bCoupe, aCoupe, x);
spectreFiltre = abs(fft(sansSecteur)) / N * 2;
fprintf('\nCoupe-bande 48-52 Hz :\n');
fprintf('  raie a  50 Hz : %.3f -> %.3f\n', amplitude(kSecteur), spectreFiltre(kSecteur));
fprintf('  raie a 120 Hz : %.3f -> %.3f\n', amplitude(kUtile), spectreFiltre(kUtile));
assert(spectreFiltre(kSecteur) < amplitude(kSecteur) / 5, ...
       'le secteur doit etre attenue d''au moins cinq fois');
assert(abs(spectreFiltre(kUtile) - amplitude(kUtile)) < 0.15, ...
       'la raie utile ne doit pas bouger');

%% 4. Le filtre passe-bande
% Ne garder que la bande utile. FILTFILT filtre deux fois, en avant puis
% en arrière : la phase s'annule, et le signal filtré n'est pas décalé —
% ce qu'un filtre causal ne peut pas offrir.
[bBande, aBande] = butter(4, [100 140] / (Fe / 2), 'bandpass');
propre = filtfilt(bBande, aBande, x);
correlationAvant = corr(x, utile);
correlationApres = corr(propre, utile);
fprintf('\nPasse-bande 100-140 Hz :\n');
fprintf('  correlation avec le signal utile : %.4f -> %.4f\n', ...
        correlationAvant, correlationApres);
assert(correlationApres > 0.95, 'le signal utile doit ressortir');
assert(correlationApres > correlationAvant);
% Un filtre à phase nulle ne décale rien : le maximum de
% l'intercorrélation reste à zéro.
[correlations, decalages] = xcorr(propre, utile, 50);
[~, kMax] = max(correlations);
fprintf('  decalage introduit : %d echantillon(s)\n', decalages(kMax));
assert(abs(decalages(kMax)) <= 1);

%% 5. Ce que le filtre fait, lu sur sa réponse
[reponse, pulsations] = freqz(bBande, aBande, 512, Fe);
gain = abs(reponse);
[~, kBande] = min(abs(pulsations - 120));
[~, kHors] = min(abs(pulsations - 50));
fprintf('\nReponse du passe-bande :\n');
fprintf('  gain a 120 Hz (dans la bande) : %.4f\n', gain(kBande));
fprintf('  gain a  50 Hz (hors bande)    : %.6f\n', gain(kHors));
assert(gain(kBande) > 0.9);
assert(gain(kHors) < 0.05);
% Le filtre est stable : ses pôles sont dans le disque unité.
assert(all(abs(roots(aBande)) < 1));

%% 6. Fenêtres et fuite spectrale
% Une sinusoïde dont la fréquence ne tombe pas sur une raie de la
% transformée étale son énergie sur les raies voisines. Une fenêtre
% adoucit les bords et réduit cette fuite, au prix d'un lobe plus large.
nFenetre = 512;
tCourt = (0:nFenetre - 1)' / Fe;
sinusoide = sin(2 * pi * 100.5 * tCourt);   % entre deux raies
fuite = @(f) sum(abs(f(20:end - 20))) / max(abs(f));
brut = abs(fft(sinusoide));
fenetre = abs(fft(sinusoide .* hann(nFenetre)));
fprintf('\nFuite spectrale a 100.5 Hz :\n');
fprintf('  sans fenetre : %.1f, avec Hann : %.1f\n', fuite(brut), fuite(fenetre));
assert(fuite(fenetre) < fuite(brut) / 2, 'la fenetre doit reduire la fuite');

%% 7. Rééchantillonnage
% Passer de mille à cinq cents hertz. Le contenu utile à 120 Hz reste
% sous la nouvelle limite de Nyquist, à 250 Hz : rien n'est replié.
reduit = resample(propre, 1, 2);
fprintf('\nReechantillonnage 1000 -> 500 Hz : %d -> %d points\n', ...
        numel(propre), numel(reduit));
spectreReduit = abs(fft(reduit)) / numel(reduit) * 2;
fReduit = (0:numel(reduit) - 1)' * (Fe / 2) / numel(reduit);
[~, kReduit] = min(abs(fReduit - 120));
fprintf('  raie a 120 Hz apres reduction : %.3f\n', spectreReduit(kReduit));
assert(spectreReduit(kReduit) > 0.7);

fprintf('\nToutes les verifications passent.\n');
