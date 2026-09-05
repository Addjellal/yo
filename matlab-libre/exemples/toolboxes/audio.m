% audio.m — Audio Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/audio.m
%
% Le cas : décrire un son pour le reconnaître. Les descripteurs employés
% ici — niveau, centroïde, taux de passages par zéro, coefficients
% cepstraux — sont ceux de toute chaîne de reconnaissance de parole ou de
% classification de sons.

fprintf('=== Audio : decrire un son pour le reconnaitre ===\n\n');

%% 1. Les signaux d'essai
Fe = 16000;
duree = 1;
t = (0:1 / Fe:duree - 1 / Fe)';
grave = sin(2 * pi * 220 * t);
aigu = sin(2 * pi * 3000 * t);
rng(1);
souffle = randn(size(t)) * 0.3;
fprintf('Trois sons de %g s a %d Hz :\n', duree, Fe);
fprintf('  grave  : sinus a 220 Hz\n');
fprintf('  aigu   : sinus a 3000 Hz\n');
fprintf('  souffle: bruit blanc\n');

%% 2. Le niveau
% Le décibel pleine échelle : zéro pour un signal qui remplit la
% dynamique, négatif pour tout le reste. C'est l'unité de la mesure de
% niveau en numérique, parce qu'elle a un maximum, contrairement au
% décibel acoustique.
niveaux = [dbfs(grave), dbfs(grave * 0.5), dbfs(grave * 0.1)];
fprintf('\nNiveau :\n');
fprintf('  sinus pleine echelle : %.4f dBFS\n', niveaux(1));
fprintf('  a la moitie          : %.4f dBFS\n', niveaux(2));
fprintf('  au dixieme           : %.4f dBFS\n', niveaux(3));
% Diviser l'amplitude par deux ote six decibels : c'est 20 log10(2).
assert(abs((niveaux(1) - niveaux(2)) - 20 * log10(2)) < 1e-9);
assert(abs((niveaux(1) - niveaux(3)) - 20) < 1e-9);
assert(niveaux(1) < 0.1, 'un sinus pleine echelle est proche de zero dBFS');

%% 3. Le centroïde spectral
% Le « centre de gravité » du spectre. C'est le descripteur qui
% correspond le mieux à ce qu'on appelle la brillance d'un son.
centroides = [spectralCentroid(grave, Fe), spectralCentroid(aigu, Fe), ...
              spectralCentroid(souffle, Fe)];
fprintf('\nCentroide spectral :\n');
fprintf('  grave   : %8.1f Hz (fondamentale 220)\n', centroides(1));
fprintf('  aigu    : %8.1f Hz (fondamentale 3000)\n', centroides(2));
fprintf('  souffle : %8.1f Hz\n', centroides(3));
assert(centroides(1) < centroides(2), 'un son plus aigu a un centroide plus haut');
assert(abs(centroides(1) - 220) / 220 < 0.2);
assert(abs(centroides(2) - 3000) / 3000 < 0.2);
% Un bruit blanc a son energie repartie partout : son centroide tombe
% vers le milieu de la bande, soit un quart de la frequence
% d'echantillonnage.
assert(abs(centroides(3) - Fe / 4) / (Fe / 4) < 0.25);

%% 4. Le taux de passages par zéro
% Combien de fois le signal change de signe. C'est une mesure de hauteur
% qui ne coûte presque rien : ni transformée ni multiplication, ce qui
% l'a rendue populaire quand le calcul était cher.
taux = [zerocrossrate(grave), zerocrossrate(aigu), zerocrossrate(souffle)];
fprintf('\nTaux de passages par zero :\n');
fprintf('  grave   : %.6f\n', taux(1));
fprintf('  aigu    : %.6f\n', taux(2));
fprintf('  souffle : %.6f\n', taux(3));
% Une sinusoide passe deux fois par zero par periode : le taux vaut donc
% 2 f / Fe.
assert(abs(taux(1) - 2 * 220 / Fe) < 0.005);
assert(abs(taux(2) - 2 * 3000 / Fe) < 0.01);
assert(taux(1) < taux(2), 'plus aigu, plus de passages');
% Un bruit passe bien plus souvent qu'une sinusoide de meme centroide :
% c'est ce qui distingue un son bruite d'un son tonal, et c'est pourquoi
% les deux descripteurs se completent.
assert(taux(3) > taux(2));

%% 5. L'échelle de Mel
% L'oreille ne perçoit pas les fréquences linéairement : deux sons
% séparés de 100 Hz s'entendent très différents dans les graves et
% presque identiques dans les aigus. Le banc de filtres de Mel épouse
% cette perception.
nFiltres = 26;
[banc, centres] = melFilterBank(nFiltres, 512, Fe);
fprintf('\nBanc de Mel : %d filtres\n', nFiltres);
fprintf('  centres de %.0f a %.0f Hz\n', centres(1), centres(end));
assert(size(banc, 1) == nFiltres);
assert(all(diff(centres) > 0), 'les centres sont croissants');
% Ils s'espacent : l'ecart entre filtres voisins croit avec la frequence.
ecarts = diff(centres);
fprintf('  ecart entre filtres : %.0f Hz en bas, %.0f Hz en haut\n', ...
        ecarts(1), ecarts(end));
assert(ecarts(end) > ecarts(1) * 2, ...
       'l''echelle de Mel s''etire vers les aigus');
% Chaque filtre est triangulaire et positif.
assert(all(banc(:) >= 0));

%% 6. Les coefficients cepstraux
% Le descripteur central de la reconnaissance de parole : le logarithme
% de l'énergie dans chaque bande de Mel, puis une transformée en cosinus
% qui décorrèle les bandes. Le résultat tient en une dizaine de nombres
% par trame.
coefficients = mfccSimple(grave, Fe);
coefficientsAigu = mfccSimple(aigu, Fe);
fprintf('\nCoefficients cepstraux :\n');
fprintf('  %d coefficients par trame, %d trames\n', ...
        size(coefficients, 2), size(coefficients, 1));
assert(size(coefficients, 2) >= 10);
% Deux sons differents donnent des coefficients differents : c'est la
% seule chose qu'on leur demande.
distance = norm(mean(coefficients, 1) - mean(coefficientsAigu, 1));
fprintf('  distance entre le grave et l''aigu : %.4f\n', distance);
assert(distance > 1, 'deux sons distincts doivent se distinguer');
% Le meme son donne les memes coefficients, quel que soit son niveau —
% sauf le premier, qui porte l'energie. C'est ce qui rend le descripteur
% utilisable quand le micro est plus ou moins loin.
attenue = mfccSimple(grave * 0.3, Fe);
ecartSansEnergie = norm(mean(coefficients(:, 2:end), 1) - ...
                        mean(attenue(:, 2:end), 1));
fprintf('  ecart entre le meme son a deux niveaux : %.4f\n', ecartSansEnergie);
assert(ecartSansEnergie < distance / 5, ...
       'le niveau ne doit presque pas changer la forme');

%% 7. Lire et écrire un fichier
% Un aller-retour par le disque doit rendre le signal intact, aux
% arrondis du format près.
fichier = [tempname '.wav'];
audiowrite(fichier, grave * 0.9, Fe);
[relu, FeRelu] = audioread(fichier);
fprintf('\nAller-retour par un fichier WAV :\n');
fprintf('  %d echantillons a %d Hz\n', numel(relu), FeRelu);
assert(FeRelu == Fe);
assert(numel(relu) == numel(grave));
ecartFichier = max(abs(relu(:) - grave * 0.9));
fprintf('  ecart maximal : %.3e (quantification sur 16 bits : %.3e)\n', ...
        ecartFichier, 2 ^ -15);
assert(ecartFichier < 2 ^ -14, ...
       'l''ecart doit rester dans le pas de quantification');
delete(fichier);

fprintf('\nToutes les verifications passent.\n');
