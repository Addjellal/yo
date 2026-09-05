% communications.m — Communications Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/communications.m
%
% Le cas : une chaîne de transmission complète. Des bits, un codage
% correcteur, une modulation, un canal bruité, et la démodulation.
% C'est le schéma que tout cours de télécommunications commence par
% dessiner.

fprintf('=== Communications : de bout en bout d''une chaine ===\n\n');

%% 1. La source
rng(1);
nBits = 4800;
bits = randi([0 1], nBits, 1);
fprintf('Source : %d bits, %.4f de uns\n', nBits, mean(bits));
assert(abs(mean(bits) - 0.5) < 0.05, 'une source equiprobable');

%% 2. La modulation
% Regrouper les bits par paquets et les envoyer comme un point du plan
% complexe. Une MDP-4 porte deux bits par symbole : deux fois plus de
% débit qu'une MDP-2, à même largeur de bande.
symboles = bi2de(reshape(bits, 2, [])', 'left-msb');
modulee = pskmod(symboles, 4, pi / 4, 'gray');
fprintf('\nModulation MDP-4 :\n');
fprintf('  %d bits -> %d symboles\n', nBits, numel(modulee));
fprintf('  energie moyenne par symbole : %.4f\n', mean(abs(modulee) .^ 2));
assert(numel(modulee) == nBits / 2);
% Tous les points sont sur le cercle unite : c'est ce que « phase shift
% keying » veut dire, et c'est pourquoi un amplificateur sature ne la
% deforme pas.
assert(max(abs(abs(modulee) - 1)) < 1e-12);
% Quatre points distincts, separes de quatre-vingt-dix degres.
angles = sort(unique(round(angle(modulee) * 180 / pi)));
fprintf('  angles : %s degres\n', mat2str(angles'));
assert(numel(angles) == 4);

% Sans bruit, la demodulation rend les symboles de depart.
retour = pskdemod(modulee, 4, pi / 4, 'gray');
assert(isequal(retour(:), symboles(:)), 'sans bruit, aucune erreur');

%% 3. Le canal
% Ajouter du bruit blanc gaussien, et mesurer combien d'erreurs il cause.
% Le rapport signal sur bruit décide de tout.
fprintf('\nCanal bruite :\n');
tauxObserves = zeros(1, 5);
rapports = 0:2:8;
for k = 1:numel(rapports)
    rng(100 + k);
    recue = awgn(modulee, rapports(k), 'measured');
    demodulee = pskdemod(recue, 4, pi / 4, 'gray');
    erreurs = sum(demodulee(:) ~= symboles(:));
    tauxObserves(k) = erreurs / numel(symboles);
    fprintf('  %d dB : %4d symboles faux sur %d, soit %.4f\n', ...
            rapports(k), erreurs, numel(symboles), tauxObserves(k));
end
% Le taux d'erreur decroit quand le rapport signal sur bruit monte :
% c'est la seule chose dont on soit sur en transmission.
assert(all(diff(tauxObserves) <= 1e-6), ...
       'le taux d''erreur doit decroitre avec le rapport signal sur bruit');
assert(tauxObserves(1) > tauxObserves(end) * 5);

%% 4. Le codage correcteur
% Ajouter de la redondance pour corriger les erreurs. Un code de Hamming
% (7,4) ajoute trois bits à quatre, et corrige une erreur par bloc — pas
% deux : c'est ce que sa distance minimale de trois permet, ni plus.
fprintf('\nCode de Hamming (7,4) :\n');
messages = reshape(bits(1:4 * 400), 400, 4);
codes = encode(messages, 7, 4, 'hamming/binary');
fprintf('  %d blocs de 4 bits -> %d bits\n', size(messages, 1), numel(codes));
assert(isequal(size(codes), [400 7]));
% Sans erreur, le decodage rend le message.
assert(isequal(decode(codes, 7, 4, 'hamming/binary'), messages));
% Une erreur par bloc : elle est corrigee.
avecUneErreur = codes;
rng(7);
for k = 1:size(codes, 1)
    position = randi(7);
    avecUneErreur(k, position) = 1 - avecUneErreur(k, position);
end
corriges = decode(avecUneErreur, 7, 4, 'hamming/binary');
fprintf('  une erreur par bloc : %d blocs sur %d retrouves\n', ...
        sum(all(corriges == messages, 2)), size(messages, 1));
assert(isequal(corriges, messages), 'une erreur par bloc doit etre corrigee');
% Deux erreurs par bloc : le code ne peut plus. Il le faut, sans quoi il
% corrigerait au-dela de sa distance minimale, ce qui est impossible.
avecDeuxErreurs = codes;
rng(8);
for k = 1:size(codes, 1)
    positions = randperm(7, 2);
    avecDeuxErreurs(k, positions) = 1 - avecDeuxErreurs(k, positions);
end
malCorriges = decode(avecDeuxErreurs, 7, 4, 'hamming/binary');
fprintf('  deux erreurs par bloc : %d blocs sur %d retrouves\n', ...
        sum(all(malCorriges == messages, 2)), size(messages, 1));
assert(~isequal(malCorriges, messages), ...
       'un code de distance 3 ne corrige pas deux erreurs');

%% 5. Le gain du codage
% Le codage coûte du débit et rend de la fiabilité. Le comparer à débit
% brut égal est ce qui montre s'il vaut la peine.
fprintf('\nCe que le codage achete :\n');
rng(21);
bruits = awgn(modulee(1:1400), 4, 'measured');
sansCodage = pskdemod(bruits, 4, pi / 4, 'gray');
tauxSansCodage = mean(sansCodage(:) ~= symboles(1:1400));
fprintf('  a 4 dB, sans codage : %.4f de symboles faux\n', tauxSansCodage);
assert(tauxSansCodage > 0, 'a 4 dB il doit rester des erreurs');

%% 6. Autres modulations
% La modulation d'amplitude en quadrature porte plus de bits par
% symbole, au prix d'une sensibilité au bruit plus grande : les points y
% sont plus serrés.
fprintf('\nComparaison des modulations a 10 dB :\n');
donnees4 = randi([0 3], 2000, 1);
donnees16 = randi([0 15], 2000, 1);
rng(31);
mdp4 = pskmod(donnees4, 4, pi / 4, 'gray');
maq16 = qammod(donnees16, 16);
maq16 = maq16 / sqrt(mean(abs(maq16) .^ 2));
erreurs4 = mean(pskdemod(awgn(mdp4, 10, 'measured'), 4, pi / 4, 'gray') ~= donnees4);
recue16 = awgn(maq16, 10, 'measured') * sqrt(10);
erreurs16 = mean(qamdemod(recue16, 16) ~= donnees16);
fprintf('  MDP-4  (2 bits/symbole) : %.4f\n', erreurs4);
fprintf('  MAQ-16 (4 bits/symbole) : %.4f\n', erreurs16);
assert(erreurs16 > erreurs4, ...
       'a energie egale, plus de points signifie plus d''erreurs');

%% 7. Le codage de Gray
% Deux points voisins de la constellation ne diffèrent que d'un bit. Une
% erreur de symbole ne coûte alors qu'un bit faux, non deux : c'est
% gratuit, et cela divise le taux d'erreur binaire par deux.
fprintf('\nCodage de Gray :\n');
pointsGray = pskmod((0:3)', 4, pi / 4, 'gray');
pointsBinaire = pskmod((0:3)', 4, pi / 4, 'bin');
[~, ordreGray] = sort(angle(pointsGray));
[~, ordreBinaire] = sort(angle(pointsBinaire));
distanceGray = distancesBinaires(ordreGray - 1);
distanceBinaire = distancesBinaires(ordreBinaire - 1);
fprintf('  bits differents entre points voisins : Gray %s, binaire %s\n', ...
        mat2str(distanceGray), mat2str(distanceBinaire));
assert(all(distanceGray == 1), 'deux voisins de Gray ne different que d''un bit');
assert(any(distanceBinaire > 1), 'le codage binaire, lui, en change parfois deux');

fprintf('\nToutes les verifications passent.\n');

function d = distancesBinaires(ordre)
%DISTANCESBINAIRES Bits differents entre points consecutifs du cercle.
    n = numel(ordre);
    d = zeros(1, n);
    for k = 1:n
        suivant = mod(k, n) + 1;
        d(k) = sum(de2bi(ordre(k), 2) ~= de2bi(ordre(suivant), 2));
    end
end
