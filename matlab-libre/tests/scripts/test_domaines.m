% test_domaines.m — communications, ondelettes, logique floue.
% Les références sont exactes : valeurs connues de la fonction Q,
% aller-retour de modulations, correction d'une erreur par un code de
% Hamming, identités des transformées en ondelettes, valeurs remarquables
% des fonctions d'appartenance.
disp('--- domaines ---');

%% ---------------------------------------------------- communications
assert(abs(qfunc(0) - 0.5) < 1e-12);
assert(abs(qfunc(1) - 0.15865525393146) < 1e-12);
assert(abs(qfunc(-1) - (1 - qfunc(1))) < 1e-12);
assert(abs(qfuncinv(0.5)) < 1e-12);
assert(abs(qfuncinv(qfunc(1.3)) - 1.3) < 1e-9);

% DPSK binaire : la phase bascule à chaque 1, reste à chaque 0.
assert(max(abs(dpskmod([0 1 0], 2)' - [1 -1 -1])) < 1e-12);
% Aller-retour sur quatre phases.
symboles = [0 1 2 3 1 0];
assert(isequal(dpskdemod(dpskmod(symboles, 4), 4)', symboles));

% FSK : la démodulation par corrélation retrouve les symboles.
assert(isequal(fskdemod(fskmod([0 1 1 0], 2, 100, 8, 1000), 2, 100, 8, 1000)', [0 1 1 0]));
assert(isequal(fskdemod(fskmod([0 1 2 3], 4, 100, 16, 1000), 4, 100, 16, 1000)', [0 1 2 3]));

% Hamming (7,4) : les dimensions, puis la correction d'une erreur simple
% à chaque position possible.
[H, G, n, k] = hammgen(3);
assert(n == 7 && k == 4);
assert(isequal(size(H), [3 7]));
assert(isequal(size(G), [4 7]));
% G*H' doit être nul modulo 2 : tout mot de code a un syndrome nul.
assert(all(all(mod(G * H', 2) == 0)));

message = [1 0 1 1];
code = encode(message, 7, 4, 'hamming/fmt');
assert(numel(code) == 7);
assert(isequal(decode(code, 7, 4, 'hamming/fmt'), message));
for position = 1:7
    abime = code;
    abime(position) = 1 - abime(position);
    assert(isequal(decode(abime, 7, 4, 'hamming/fmt'), message));
end

% Chiffres et bases : les deux conventions de poids.
assert(isequal(de2bi(5, 4), [1 0 1 0]));
assert(isequal(de2bi(5, 4, 2, 'left-msb'), [0 1 0 1]));
assert(bi2de([0 1 1 0]) == 6);
assert(bi2de([1 0 0 0], 2, 'left-msb') == 8);
assert(isequal(de2bi(63, 2, 8), [7 7]));
assert(isequal(bi2de(de2bi(0:15, 4)), (0:15)'));
assert(isequal(oct2dec([171 133]), [121 91]));
assert(isequal(dec2oct([121 91]), [171 133]));

% Treillis d'un codeur convolutif : le (7,5) de longueur de contrainte
% trois est celui de tous les manuels.
treillis = poly2trellis(3, [7 5]);
assert(treillis.numInputSymbols == 2);
assert(treillis.numOutputSymbols == 4);
assert(treillis.numStates == 4);
assert(isequal(treillis.nextStates, [0 2; 0 2; 1 3; 1 3]));
assert(isequal(treillis.outputs, [0 3; 3 0; 2 1; 1 2]));
assert(istrellis(treillis));
assert(~istrellis(struct('numInputSymbols', 2)));
treillisAbime = treillis;
treillisAbime.nextStates(1, 1) = 99;
assert(~istrellis(treillisAbime));
assert(isequal(convenc([1 0 1 1], treillis), [1 1 1 0 0 0 0 1]));
assert(isequal(convenc([1 0 1 1], [7 5], 3), [1 1 1 0 0 0 0 1]));
% Aller-retour, décision dure puis souple, et correction d'une erreur.
motConvolutif = [1 0 1 1 0 0 1 0 1 1 0 0];
codeConvolutif = convenc(motConvolutif, treillis);
assert(isequal(vitdec(codeConvolutif, treillis, 5, 'term', 'hard'), motConvolutif));
codeAbime = codeConvolutif;
codeAbime(7) = 1 - codeAbime(7);
assert(isequal(vitdec(codeAbime, treillis, 5, 'term', 'hard'), motConvolutif));
assert(isequal(vitdec(1 - 2 * codeConvolutif, treillis, 5, 'term', 'unquant'), motConvolutif));
% Le code de la NASA, longueur de contrainte sept.
treillisNasa = poly2trellis(7, [171 133]);
assert(treillisNasa.numStates == 64);
motNasa = [1 0 1 1 0 1 0 0 1 1 1 0 0 0 0 0 0 0];
assert(isequal(vitdec(convenc(motNasa, treillisNasa), treillisNasa, 34, 'term', 'hard'), motNasa));
% Codage par morceaux : l'état final se reprend tel quel.
[codeDebut, etatIntermediaire] = convenc([1 0 1 1], treillis);
codeSuite = convenc([0 0 1 0], treillis, etatIntermediaire);
assert(isequal([codeDebut codeSuite], convenc([1 0 1 1 0 0 1 0], treillis)));
% Rendement deux tiers.
treillisDeuxTiers = poly2trellis([5 4], [23 35 0; 0 5 13]);
motDeuxTiers = [1 0 1 1 0 0 1 1 0 1 0 0];
codeDeuxTiers = convenc(motDeuxTiers, treillisDeuxTiers);
assert(numel(codeDeuxTiers) == 18);
assert(isequal(vitdec(codeDeuxTiers, treillisDeuxTiers, 10, 'trunc', 'hard'), motDeuxTiers));

% Codes en blocs : matrices, polynômes cycliques, table de syndromes.
assert(isequal(mod(gen2par(G), 2), mod(H, 2)));
assert(isequal(mod(gen2par(H), 2), mod(G, 2)));
polynomeCyclique = cyclpoly(7, 4);
assert(isequal(size(cyclpoly(7, 4, 'all')), [2 4]));
[Hcyclique, Gcyclique, kCyclique] = cyclgen(7, polynomeCyclique);
assert(kCyclique == 4);
assert(all(all(mod(Gcyclique * Hcyclique', 2) == 0)));
assert(isequal(Gcyclique(:, 1:kCyclique), eye(kCyclique)));
% Distance minimale : trois pour le [7,4], quatre pour le [7,3].
motsCode = zeros(2 ^ kCyclique, 7);
for indiceMot = 0:2 ^ kCyclique - 1
    motsCode(indiceMot + 1, :) = mod(de2bi(indiceMot, kCyclique, 2, 'left-msb') * Gcyclique, 2);
end
assert(min(sum(motsCode(2:end, :), 2)) == 3);
[~, Gsimplexe, kSimplexe] = cyclgen(7, cyclpoly(7, 3));
motsSimplexe = zeros(2 ^ kSimplexe, 7);
for indiceMot = 0:2 ^ kSimplexe - 1
    motsSimplexe(indiceMot + 1, :) = mod(de2bi(indiceMot, kSimplexe, 2, 'left-msb') * Gsimplexe, 2);
end
assert(min(sum(motsSimplexe(2:end, :), 2)) == 4);
% Table de syndromes : sept motifs de poids un et le motif nul.
tableSyndromes = syndtable(H);
assert(isequal(size(tableSyndromes), [8 7]));
assert(isequal(sort(sum(tableSyndromes, 2))', [0 1 1 1 1 1 1 1]));
for position = 1:7
    motifErreur = zeros(1, 7);
    motifErreur(position) = 1;
    syndrome = mod(motifErreur * H', 2);
    assert(isequal(tableSyndromes(bi2de(syndrome, 2, 'left-msb') + 1, :), motifErreur));
end

% Modulations analogiques : la porteuse doit tenir sous Nyquist.
tAnalogique = (0:1999)' / 10000;
modulant = sin(2 * pi * 30 * tAnalogique);
milieuUtile = 400:1600;
signalAm = ammod(modulant, 1000, 10000);
% Le spectre d'une modulation d'amplitude a deux raies, à FC +- FM.
spectreAm = abs(fft(signalAm));
frequences = (0:1999) / 2000 * 10000;
[~, plusFortes] = sort(spectreAm(1:1000), 'descend');
assert(isequal(sort(round(frequences(plusFortes(1:2)))), [970 1030]));
recuAm = amdemod(signalAm, 1000, 10000);
assert(max(abs(recuAm(milieuUtile) - modulant(milieuUtile))) < 0.15);
% Avec porteuse, l'enveloppe ne s'annule jamais.
assert(min(abs(ammod(modulant, 1000, 10000, 0, 2))) > 0);
% Phase et fréquence se retrouvent presque exactement.
recuPm = pmdemod(pmmod(modulant, 1000, 10000, 1), 1000, 10000, 1);
assert(max(abs(recuPm(milieuUtile) - modulant(milieuUtile))) < 1e-6);
recuFm = fmdemod(fmmod(modulant, 1000, 10000, 200), 1000, 10000, 200);
assert(max(abs(recuFm(milieuUtile) - modulant(milieuUtile))) < 0.02);
% Un modulant constant donne un écart de fréquence constant.
recuConstant = fmdemod(fmmod(ones(2000, 1), 1000, 10000, 200), 1000, 10000, 200);
assert(abs(mean(recuConstant(milieuUtile)) - 1) < 1e-6);
erreurAttrapee = false;
try
    ammod(modulant, 6000, 10000);
catch
    erreurAttrapee = true;
end
assert(erreurAttrapee);

% Modulations numériques supplémentaires.
assert(isequal(pammod(0:3, 4), [-3 -1 1 3]));
assert(isequal(pamdemod([-3 -0.9 1.2 3], 4), [0 1 2 3]));
assert(isequal(pamdemod(pammod(0:7, 8), 8), 0:7));
assert(isequal(pamdemod(pammod(0:7, 8, 0, 'gray'), 8, 0, 'gray'), 0:7));
constellationLibre = [1, 1i, -1, -1i];
assert(max(abs(genqammod([0 1 2 3], constellationLibre) - constellationLibre)) < 1e-12);
assert(isequal(genqamdemod([0.9+0.1i, -0.2+1.1i], constellationLibre), [0 1]));
constellationQam = qammod(0:15, 16);
assert(abs(mean(abs(modnorm(constellationQam, 'avpow', 1) * constellationQam) .^ 2) - 1) < 1e-12);
assert(abs(max(abs(modnorm(constellationQam, 'peakpow', 1) * constellationQam) .^ 2) - 1) < 1e-12);
% Gray : deux points voisins ne diffèrent que d'un bit.
assert(isequal(bin2gray(0:7, 'psk', 8), [0 1 3 2 6 7 5 4]));
assert(isequal(gray2bin(bin2gray(0:7, 'psk', 8), 'psk', 8), 0:7));
codesGray = bin2gray(0:15, 'pam', 16);
for indiceGray = 1:15
    assert(sum(de2bi(bitxor(codesGray(indiceGray), codesGray(indiceGray + 1)), 4)) == 1);
end
assert(isequal(sort(bin2gray(0:15, 'qam', 16)), 0:15));
% MSK : enveloppe constante, phase avançant de pi/2 par symbole.
bitsMsk = [1 0 1 1 0 0 1];
signalMsk = mskmod(bitsMsk, 8);
assert(max(abs(abs(signalMsk) - 1)) < 1e-12);
assert(numel(signalMsk) == 56);
assert(isequal(mskdemod(signalMsk, 8), bitsMsk));
assert(isequal(mskdemod(mskmod(bitsMsk, 8, 'nondiff'), 8, 'nondiff'), bitsMsk));
phasesMsk = unwrap(angle([1, mskmod(bitsMsk, 8, 'nondiff')]));
assert(max(abs(abs(diff(phasesMsk(1:8:end))) - pi/2)) < 1e-12);

% Entrelacement.
assert(isequal(intrlv([10 20 30 40], [3 1 4 2]), [30 10 40 20]));
assert(isequal(deintrlv(intrlv([10 20 30 40], [3 1 4 2]), [3 1 4 2]), [10 20 30 40]));
assert(isequal(randdeintrlv(randintrlv(1:8, 42), 42), 1:8));
assert(isequal(randintrlv(1:8, 42), randintrlv(1:8, 42)));
assert(~isequal(randintrlv(1:8, 42), randintrlv(1:8, 7)));
assert(isequal(matintrlv(1:6, 2, 3), [1 4 2 5 3 6]));
assert(isequal(matdeintrlv(matintrlv(1:6, 2, 3), 2, 3), 1:6));
% Une rafale de trois erreurs consécutives se retrouve espacée de quatre.
rafale = zeros(1, 12);
rafale(4:6) = 1;
assert(isequal(find(matdeintrlv(rafale, 3, 4)), [2 6 10]));
% Canal binaire symétrique : le taux mesuré suit la probabilité.
rng(1);
[sortieBsc, erreursBsc] = bsc(zeros(1, 10000), 0.1);
assert(abs(sum(erreursBsc) / 10000 - 0.1) < 0.02);
assert(isequal(sortieBsc, erreursBsc));
assert(isequal(vec2mat(1:5, 3), [1 2 3; 4 5 0]));
[~, resteVec] = vec2mat(1:5, 3);
assert(resteVec == 1);

% Taux d'erreur sur canal de Rayleigh : la formule close pour la MDP-2.
for niveauDb = [0 5 10 20]
    gammaMoyen = 10 ^ (niveauDb / 10);
    assert(abs(berfading(niveauDb, 'psk', 2, 1) - (1 - sqrt(gammaMoyen / (1 + gammaMoyen))) / 2) < 1e-12);
end
% La diversité fait chuter le taux, et Rayleigh reste pire que le gaussien.
assert(berfading(10, 'psk', 2, 1) > berfading(10, 'psk', 2, 2));
assert(berfading(10, 'psk', 2, 2) > berfading(10, 'psk', 2, 4));
assert(berfading(15, 'qam', 16, 1) > berawgn(15, 'qam', 16));
assert(berfading(15, 'qam', 16, 1) > berfading(15, 'qam', 16, 3));
% Conversions de rapport signal sur bruit.
assert(abs(convertSNR(10, 'ebno', 'snr', 'BitsPerSymbol', 4) - (10 + 10 * log10(4))) < 1e-12);
assert(abs(convertSNR(10, 'ebno', 'esno', 'BitsPerSymbol', 4, 'CodingRate', 0.5) - (10 + 10 * log10(2))) < 1e-12);
assert(abs(convertSNR(10, 'snr', 'esno', 'SamplesPerSymbol', 8) - (10 + 10 * log10(8))) < 1e-12);
assert(abs(convertSNR(convertSNR(10, 'ebno', 'snr', 'BitsPerSymbol', 4, 'SamplesPerSymbol', 8), ...
                      'snr', 'ebno', 'BitsPerSymbol', 4, 'SamplesPerSymbol', 8) - 10) < 1e-12);

%% -------------------------------------------------------- ondelettes
% Bancs de filtres : les valeurs de db2 sont celles que publie la
% documentation, au signe près qui est celui de MATLAB.
[lod, hid, lor, hir] = wfilters('db2');
assert(max(abs(lor - [0.482962913145, 0.836516303738, 0.224143868042, -0.129409522551])) < 1e-11);
assert(max(abs(lod - lor(end:-1:1))) < 1e-15);
assert(max(abs(hid - [-0.482962913145, 0.836516303738, -0.224143868042, -0.129409522551])) < 1e-11);
assert(max(abs(hir - hid(end:-1:1))) < 1e-15);
[~, hidHaar] = wfilters('haar');
assert(max(abs(hidHaar - [-1 1] / sqrt(2))) < 1e-15);
% Le second argument sélectionne une paire de filtres.
[pd1, pd2] = wfilters('db2', 'd');
assert(isequal(pd1, lod) && isequal(pd2, hid));
[pr1, pr2] = wfilters('db2', 'r');
assert(isequal(pr1, lor) && isequal(pr2, hir));
[pl1, pl2] = wfilters('db2', 'l');
assert(isequal(pl1, lod) && isequal(pl2, lor));
[ph1, ph2] = wfilters('db2', 'h');
assert(isequal(ph1, hid) && isequal(ph2, hir));
% Les ordres élevés restent orthogonaux : construction, pas table.
[~, ~, h45] = wfilters('db45');
assert(numel(h45) == 90);
assert(abs(sum(h45 .^ 2) - 1) < 1e-8);
assert(abs(sum(h45) - sqrt(2)) < 1e-8);
% db4 : table publiée du filtre d'échelle.
[~, ~, lor4] = wfilters('db4');
assert(max(abs(lor4 - [0.230377813309, 0.714846570553, 0.630880767930, -0.027983769417, ...
                       -0.187034811719, 0.030841381836, 0.032883011667, -0.010597401785])) < 1e-11);
% Orthogonalité du banc et moments nuls du passe-haut, pour db1 à db8.
for ordre = 1:8
    [~, ~, h, g] = wfilters(sprintf('db%d', ordre));
    assert(abs(sum(h) - sqrt(2)) < 1e-9);
    assert(abs(sum(h .^ 2) - 1) < 1e-9);
    for decalage = 1:(numel(h)/2 - 1)
        assert(abs(sum(h(1:end-2*decalage) .* h(1+2*decalage:end))) < 1e-9);
    end
    for moment = 0:(ordre - 1)
        assert(abs(sum(g .* ((0:numel(g)-1) .^ moment))) < 1e-6 * max(1, 10 ^ moment));
    end
end
% orthfilt reconstruit le banc de Haar depuis le filtre brut.
[o1, o2, o3, o4] = orthfilt([1 1]);
assert(max(abs(o1 - [1 1]/sqrt(2))) < 1e-15);
assert(max(abs(o2 - [-1 1]/sqrt(2))) < 1e-15);
assert(max(abs(o3 - [1 1]/sqrt(2))) < 1e-15);
assert(max(abs(o4 - [1 -1]/sqrt(2))) < 1e-15);
assert(isequal(qmf([1 2 3 4]), [4 -3 2 -1]));
assert(isequal(wrev([1 2 3]), [3 2 1]));
assert(isequal(dyadup([1 2 3]), [1 0 2 0 3]));
assert(isequal(dyadup([1 2 3], 0), [0 1 0 2 0 3 0]));
assert(isequal(dyaddown([1 2 3 4 5]), [2 4]));

% Niveau maximal : floor(log2(L/(Lf-1))).
assert(wmaxlev(64, 'db2') == 4);
assert(wmaxlev(8, 'db1') == 3);
assert(wmaxlev(2, 'db1') == 1);

% Un niveau de Haar sur [1 2 3 4] : demi-sommes et demi-différences.
[approximation, detail] = dwt([1 2 3 4], 'haar');
assert(max(abs(approximation - [3 7] / sqrt(2))) < 1e-12);
assert(max(abs(detail - [-1 -1] / sqrt(2))) < 1e-12);

[c, l] = wavedec(1:8, 2, 'db1');
assert(numel(detcoef(c, l, 1)) == 4);
assert(numel(detcoef(c, l, 2)) == 2);
assert(numel(appcoef(c, l, 'db1')) == 2);
% Les détails d'un signal affine sont nuls au premier niveau, à la
% normalisation de Haar près : une rampe n'a pas de rupture.
d1 = detcoef(c, l, 1);
assert(max(abs(d1 - d1(1))) < 1e-12);

% Aller-retour et conservation de l'énergie : la transformée est
% orthogonale, donc la somme des carrés se conserve.
signal = cos((1:64) / 5) + (1:64) / 40;
for nom = {'haar', 'db2', 'db4', 'db6', 'sym4', 'sym8'}
    [cc, ll] = wavedec(signal, 3, nom{1});
    assert(max(abs(waverec(cc, ll, nom{1}) - signal)) < 1e-10);
    assert(abs(sum(cc .^ 2) - sum(signal .^ 2)) < 1e-9);
    [unNiveauA, unNiveauD] = dwt(signal, nom{1});
    assert(max(abs(idwt(unNiveauA, unNiveauD, nom{1}) - signal)) < 1e-10);
end
% Somme des reconstructions partielles : a3 + d3 + d2 + d1 == signal.
[cc, ll] = wavedec(signal, 3, 'db4');
recomposition = wrcoef('a', cc, ll, 'db4', 3);
for niveau = 1:3
    recomposition = recomposition + wrcoef('d', cc, ll, 'db4', niveau);
end
assert(max(abs(recomposition - signal)) < 1e-10);
% upwlev remonte d'un niveau sans rien perdre.
[cRemonte, lRemonte] = upwlev(cc, ll, 'db4');
assert(numel(lRemonte) == numel(ll) - 1);
assert(max(abs(waverec(cRemonte, lRemonte, 'db4') - signal)) < 1e-10);
% wenergy : les pourcentages somment à cent.
[energieA, energiesD] = wenergy(cc, ll);
assert(abs(energieA + sum(energiesD) - 100) < 1e-9);
assert(numel(energiesD) == 3);

% Transformée bidimensionnelle : une image constante n'a que de
% l'approximation.
[a, h, v, d] = dwt2(ones(4), 'db1');
assert(isequal(size(a), [2 2]));
assert(max(abs(a(:) - 2)) < 1e-12);
assert(max(abs(h(:))) < 1e-12);
assert(max(abs(v(:))) < 1e-12);
assert(max(abs(d(:))) < 1e-12);

% Aller-retour exact sur une image quelconque.
x = magic(4);
[a2, h2, v2, d2] = dwt2(x, 'db1');
assert(max(max(abs(idwt2(a2, h2, v2, d2, 'db1') - x))) < 1e-10);

% Décomposition bidimensionnelle multiniveaux et reconstructions partielles.
image16 = magic(16);
for nom = {'haar', 'db2', 'sym4'}
    [c2, s2] = wavedec2(image16, 2, nom{1});
    assert(max(max(abs(waverec2(c2, s2, nom{1}) - image16))) < 1e-9);
    assert(isequal(size(appcoef2(c2, s2, nom{1}, 2)), [4 4]));
    [hd, vd, dd] = detcoef2('all', c2, s2, 1);
    assert(isequal(size(hd), [8 8]) && isequal(size(vd), [8 8]) && isequal(size(dd), [8 8]));
end
[c2, s2] = wavedec2(image16, 2, 'sym4');
somme2 = wrcoef2('a', c2, s2, 'sym4', 2);
for niveau = 1:2
    somme2 = somme2 + wrcoef2('h', c2, s2, 'sym4', niveau) ...
                    + wrcoef2('v', c2, s2, 'sym4', niveau) ...
                    + wrcoef2('d', c2, s2, 'sym4', niveau);
end
assert(max(max(abs(somme2 - image16))) < 1e-9);

% Transformée stationnaire : invariante par translation, contrairement à
% la transformée décimée, et inversible exactement.
[swa, swd] = swt(signal, 3, 'db2');
assert(max(abs(iswt(swa, swd, 'db2') - signal)) < 1e-10);
[~, swdDecale] = swt(circshift(signal, 5), 3, 'db2');
assert(max(abs(circshift(swd(1, :), 5) - swdDecale(1, :))) < 1e-12);

% MODWT : cadre ajusté de constante un, donc l'énergie se conserve.
w = modwt(signal, 'db2', 4);
assert(size(w, 1) == 5);
assert(abs(sum(sum(w .^ 2)) - sum(signal .^ 2)) < 1e-8);
assert(max(abs(imodwt(w, 'db2') - signal)) < 1e-10);
assert(max(abs(sum(modwtmra(w, 'db2'), 1) - signal)) < 1e-10);

% Fonctions d'échelle et d'ondelette. Haar est connue analytiquement.
[phi, psi, xval] = wavefun('db1', 8);
assert(numel(phi) == 257);
assert(max(abs(phi - [ones(1, 256) 0])) < 1e-12);
assert(max(abs(psi - [ones(1, 128) -ones(1, 128) 0])) < 1e-12);
% Pour les autres : intégrale un, moyenne nulle, norme un, moments nuls.
for nom = {'db2', 'db4', 'sym4'}
    [phi, psi, xval] = wavefun(nom{1}, 8);
    pas = xval(2) - xval(1);
    assert(abs(sum(phi) * pas - 1) < 1e-9);
    assert(abs(sum(psi) * pas) < 1e-9);
    assert(abs(sum(phi(1:end-1) .^ 2) * pas - 1) < 1e-6);
    assert(abs(sum(psi(1:end-1) .^ 2) * pas - 1) < 1e-6);
    assert(abs(sum(phi(1:end-1) .* psi(1:end-1)) * pas) < 1e-9);
end
[~, psi4, xval4] = wavefun('db4', 8);
pas4 = xval4(2) - xval4(1);
for moment = 0:3
    assert(abs(sum(psi4(1:end-1) .* (xval4(1:end-1) .^ moment)) * pas4) < 1e-6);
end
% Le quatrième moment, lui, ne s'annule pas : db4 en a exactement quatre.
assert(abs(sum(psi4(1:end-1) .* (xval4(1:end-1) .^ 4)) * pas4) > 0.1);

% Fréquence centrale : multiple de 1/(L-1), valeurs publiées.
assert(abs(centfrq('db2') - 2/3) < 1e-9);
assert(abs(centfrq('db3') - 4/5) < 1e-9);
assert(abs(centfrq('db4') - 5/7) < 1e-9);
assert(abs(centfrq('sym4') - 5/7) < 1e-9);
assert(max(abs(scal2frq([1 2 4], 'db2', 1) - (2/3) ./ [1 2 4])) < 1e-9);
assert(abs(scal2frq(4, 'db4', 0.001) - (5/7) / 0.004) < 1e-6);

% Prolongements aux bords : les neuf modes documentés.
assert(isequal(wextend('1D', 'zpd',   [1 2 3], 2), [0 0 1 2 3 0 0]));
assert(isequal(wextend('1D', 'sp0',   [1 2 3], 2), [1 1 1 2 3 3 3]));
assert(isequal(wextend('1D', 'spd',   [1 2 3], 2), [-1 0 1 2 3 4 5]));
assert(isequal(wextend('1D', 'sym',   [1 2 3], 2), [2 1 1 2 3 3 2]));
assert(isequal(wextend('1D', 'symw',  [1 2 3], 2), [3 2 1 2 3 2 1]));
assert(isequal(wextend('1D', 'asym',  [1 2 3], 2), [-2 -1 1 2 3 -3 -2]));
assert(isequal(wextend('1D', 'asymw', [1 2 3], 2), [-3 -2 1 2 3 -2 -1]));
assert(isequal(wextend('1D', 'ppd',   [1 2 3], 2), [2 3 1 2 3 1 2]));
assert(isequal(wextend('1D', 'per',   [1 2 3], 2), [3 3 1 2 3 3 1 2]));
assert(isequal(wextend('1D', 'zpd',   [1 2 3], 2, 'l'), [0 0 1 2 3]));
assert(isequal(wextend('1D', 'zpd',   [1 2 3], 2, 'r'), [1 2 3 0 0]));
assert(isequal(wextend('2D', 'sym', [1 2; 3 4], 1), [1 1 2 2; 1 1 2 2; 3 3 4 4; 3 3 4 4]));
assert(isequal(size(wextend('2D', 'ppd', ones(4, 6), [2 2])), [8 10]));
assert(isequal(wkeep([1 2 3 4 5 6], 3), [2 3 4]));
assert(isequal(wconv1([1 2 3], [1 1]), [1 3 5 3]));

% Seuillage et débruitage.
assert(isequal(wthresh([-3 -1 1 3], 's', 2), [-1 0 0 1]));
assert(isequal(wthresh([-3 -1 1 3], 'h', 2), [-3 0 0 3]));
% Seuil universel et seuil minimax : formes closes de Donoho et Johnstone.
assert(abs(thselect(zeros(1, 1024), 'sqtwolog') - sqrt(2 * log(1024))) < 1e-12);
assert(abs(thselect(zeros(1, 1024), 'minimaxi') - (0.3936 + 0.1829 * log2(1024))) < 1e-12);
% Le signal heavysine vaut exactement -2 au milieu : 4 sin(2 pi) - 1 - 1.
heavysine = wnoise(3, 10);
assert(abs(heavysine(512) + 2) < 1e-12);
assert(numel(heavysine) == 1024);
% Estimation robuste du bruit : sur du bruit d'écart type deux, à 10 % près.
rng(3);
[cBruit, lBruit] = wavedec(2 * randn(1, 4096), 3, 'db2');
assert(abs(wnoisest(cBruit, lBruit, 1) - 2) < 0.2);
% Débruitage : l'erreur relative doit diminuer, et la plupart des
% coefficients être annulés.
[propre, bruite] = wnoise(1, 10, 7, 5);
[cN, lN] = wavedec(bruite, 3, 'db4');
seuil = thselect(bruite, 'sqtwolog') * wnoisest(cN, lN, 1);
[debruite, ~, ~, perf0, perfL2] = wdencmp('gbl', bruite, 'db4', 3, seuil, 's', 1);
assert(norm(debruite - propre) < norm(bruite - propre));
assert(perf0 > 50 && perf0 <= 100);
assert(perfL2 > 80 && perfL2 <= 100);
[seuilDefaut, genreDefaut, gardeDefaut] = ddencmp('den', 'wv', bruite);
assert(seuilDefaut > 0 && strcmp(genreDefaut, 's') && gardeDefaut == 1);
[~, genreCompression, ~, critere] = ddencmp('cmp', 'wp', bruite);
assert(strcmp(genreCompression, 'h') && strcmp(critere, 'threshold'));
% wthcoef : annulation, atténuation, seuillage.
cAnnule = wthcoef('d', cN, lN, 1:3);
assert(sum(cAnnule ~= 0) == lN(1));
assert(isequal(wthcoef('d', cN, lN, 1:3, [1 1 1]), cN));
cMoitie = wthcoef('d', cN, lN, 1, 0.5);
assert(max(abs(cMoitie(1:lN(1)) - cN(1:lN(1)))) < 1e-15);
assert(abs(sum(abs(cMoitie)) - (sum(abs(cN)) - 0.5 * sum(abs(detcoef(cN, lN, 1))))) < 1e-9);
cSeuille = wthcoef('t', cN, lN, 1:3, 100, 'h');
assert(sum(cSeuille ~= 0) == lN(1));
assert(isequal(wthcoef('a', cN, lN), [zeros(1, lN(1)), cN(lN(1)+1:end)]));

% Ondelettes continues : formes analytiques, norme, moments nuls.
[psiChapeau, xChapeau] = mexihat(-8, 8, 4000);
assert(abs(trapz(xChapeau, psiChapeau)) < 1e-9);
assert(abs(trapz(xChapeau, psiChapeau .^ 2) - 1) < 1e-6);
assert(abs(psiChapeau(2000) - 2 / (sqrt(3) * pi ^ 0.25) * (1 - xChapeau(2000)^2) * exp(-xChapeau(2000)^2/2)) < 1e-14);
[psiMorlet, xMorlet] = morlet(-8, 8, 1001);
assert(abs(psiMorlet(501) - 1) < 1e-12);
assert(max(abs(psiMorlet - exp(-xMorlet.^2/2) .* cos(5*xMorlet))) < 1e-15);
for ordreGauss = 1:6
    [psiGauss, xGauss] = gauswavf(-8, 8, 8000, ordreGauss);
    assert(abs(trapz(xGauss, psiGauss .^ 2) - 1) < 1e-6);
    for moment = 0:(ordreGauss - 1)
        assert(abs(trapz(xGauss, psiGauss .* xGauss .^ moment)) < 1e-9);
    end
end
% gaus1 vaut exactement -2x exp(-x^2) normalisé par sqrt(sqrt(2 pi)/2).
xGauss = linspace(-5, 5, 1000);
assert(max(abs(gauswavf(-5, 5, 1000, 1) - (-2 * xGauss .* exp(-xGauss .^ 2)) / sqrt(sqrt(2*pi)/2))) < 1e-15);
% Fréquences centrales publiées.
assert(abs(centfrq('mexh') - 0.25) < 1e-12);
assert(abs(centfrq('morl') - 0.8125) < 1e-12);
assert(abs(centfrq('gaus1') - 0.2) < 1e-12);
assert(abs(centfrq('gaus2') - 0.3) < 1e-12);
[psiCont, xCont] = wavefun('mexh', 10);
assert(numel(psiCont) == 1024 && abs(xCont(1) + 8) < 1e-12 && abs(xCont(end) - 8) < 1e-12);

% Transformée continue : elle retrouve la fréquence d'une sinusoïde.
tCwt = (0:1023) / 1024;
echellesCwt = 1:0.25:64;
[coefCwt, freqCwt] = cwt(sin(2*pi*60*tCwt), echellesCwt, 'morl', 1/1024);
[~, indiceCwt] = max(max(abs(coefCwt(:, 200:800)), [], 2));
assert(abs(freqCwt(indiceCwt) - 60) < 2);
assert(isequal(size(coefCwt), [numel(echellesCwt) 1024]));
% Sur une impulsion, le coefficient est l'ondelette elle-même.
impulsion = zeros(1, 401);
impulsion(201) = 1;
coefImpulsion = cwt(impulsion, 8, 'mexh');
[psiRef, xRef] = mexihat(-8, 8, 129);
assert(max(abs(coefImpulsion - interp1(xRef, psiRef, (-200:200)/8, 'linear', 0) / sqrt(8))) < 1e-12);
assert(all(isfinite(reshape(cwt(sin(2*pi*60*tCwt), 1:16, 'db4'), 1, []))));

% wdenoise : les six méthodes réduisent l'erreur, et laissent un signal
% sans bruit à peu près intact.
[propreW, bruiteW] = wnoise(3, 10, 7, 5);
for methode = {'BlockJS', 'UniversalThreshold', 'SURE', 'Minimax', 'Bayes', 'FDR'}
    xdW = wdenoise(bruiteW, 'Wavelet', 'sym4', 'DenoisingMethod', methode{1});
    assert(numel(xdW) == numel(bruiteW));
    assert(norm(xdW - propreW) < norm(bruiteW - propreW));
end
assert(norm(wdenoise(propreW, 'DenoisingMethod', 'UniversalThreshold') - propreW) < 1e-4 * norm(propreW));
assert(isequal(size(wdenoise(bruiteW')), [1024 1]));
[~, cfsDebruites, cfsOrigine] = wdenoise(bruiteW, 'DenoisingMethod', 'UniversalThreshold');
assert(numel(cfsDebruites) == numel(cfsOrigine));
assert(sum(cfsDebruites == 0) > sum(cfsOrigine == 0));

% Mise à l'échelle des indices de couleur.
assert(isequal(wcodemat([0 1], 4), [1 4]));
assert(isequal(wcodemat([5 5], 4), [1 1]));

%% ------------------------------------------------------ logique floue
% Z décroît de 1 à 0, S est son complément, et les deux valent 1/2 au
% milieu de l'intervalle.
assert(abs(zmf(0, [2 8]) - 1) < 1e-12);
assert(abs(zmf(10, [2 8])) < 1e-12);
assert(abs(zmf(5, [2 8]) - 0.5) < 1e-12);
assert(abs(smf(5, [2 8]) - 0.5) < 1e-12);
assert(abs(smf(10, [2 8]) - 1) < 1e-12);
assert(abs(zmf(4, [2 8]) + smf(4, [2 8]) - 1) < 1e-12);

% Pi vaut 1 sur le plateau, 0 en dehors.
assert(abs(pimf(5, [1 4 6 9]) - 1) < 1e-12);
assert(abs(pimf(0, [1 4 6 9])) < 1e-12);
assert(abs(pimf(10, [1 4 6 9])) < 1e-12);

% Différence et produit de sigmoïdes : proches de 1 au centre.
assert(dsigmf(0, [5 -2 5 2]) > 0.99);
assert(psigmf(0, [5 -2 -5 2]) > 0.99);

% Gaussienne à plateau : 1 entre les deux centres.
assert(abs(gauss2mf(5, [1 3 1 7]) - 1) < 1e-12);
assert(gauss2mf(0, [1 3 1 7]) < 0.02);

% Les fonctions d'appartenance restent entre 0 et 1 sur tout l'intervalle.
grille = linspace(-5, 15, 200);
for f = {@(v) zmf(v, [2 8]), @(v) smf(v, [2 8]), @(v) pimf(v, [1 4 6 9]), ...
         @(v) gauss2mf(v, [1 3 1 7])}
    valeurs = f{1}(grille);
    assert(all(valeurs >= -1e-12) && all(valeurs <= 1 + 1e-12));
end

disp('domaines : toutes les verifications passent');
