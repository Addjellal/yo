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

%% ------------------------------ quantification, source, entrelacement
% Le seuil appartient a l'intervalle du dessous.
[indicesQuant, valeursQuant, distorsionQuant] = ...
    quantiz([-2 -1 0 1 2], [-1 0 1], [-1.5 -0.5 0.5 1.5]);
assert(isequal(indicesQuant, [0 0 1 2 3]));
assert(isequal(valeursQuant, [-1.5 -1.5 -0.5 0.5 1.5]));
assert(abs(distorsionQuant - mean(([-2 -1 0 1 2] - valeursQuant) .^ 2)) < 1e-15);

% Lloyd : les deux conditions d'optimalite tiennent, et la distorsion
% baisse quand on ajoute des niveaux.
donneesQuant = cos((1:1500) / 7) + 0.4 * sin((1:1500) / 3);
distorsionPrecedente = Inf;
for niveauxQuant = [2 4 8]
    [seuilsQuant, dictionnaireQuant, distorsionQuant] = lloyds(donneesQuant, niveauxQuant);
    assert(numel(dictionnaireQuant) == niveauxQuant);
    assert(numel(seuilsQuant) == niveauxQuant - 1);
    assert(distorsionQuant < distorsionPrecedente);
    distorsionPrecedente = distorsionQuant;
    % Chaque niveau est le barycentre de sa cellule.
    indicesQuant = quantiz(donneesQuant, seuilsQuant);
    for jQuant = 1:niveauxQuant
        dedansQuant = indicesQuant == jQuant - 1;
        if sum(dedansQuant) > 0
            assert(abs(mean(donneesQuant(dedansQuant)) - dictionnaireQuant(jQuant)) < 1e-5);
        end
    end
    % Chaque seuil est au milieu de deux niveaux.
    assert(max(abs(seuilsQuant - (dictionnaireQuant(1:end-1) + ...
                                  dictionnaireQuant(2:end)) / 2)) < 1e-12);
end
% Lloyd bat le quantificateur uniforme de meme taille.
[seuilsLloyd, dictionnaireLloyd, distorsionLloyd] = lloyds(donneesQuant, 8);
bornesUniformes = linspace(min(donneesQuant), max(donneesQuant), 9);
[~, ~, distorsionUniforme] = quantiz(donneesQuant, bornesUniformes(2:end-1), ...
    (bornesUniformes(1:end-1) + bornesUniformes(2:end)) / 2);
assert(distorsionLloyd < distorsionUniforme);

% Huffman : longueur moyenne entre l'entropie et l'entropie plus un, code
% prefixe, et aller-retour exact.
[dictionnaireHuffman, longueurHuffman] = huffmandict({'a', 'b', 'c'}, [0.5 0.25 0.25]);
assert(abs(longueurHuffman - 1.5) < 1e-12);
for essaiHuffman = 1:10
    nHuffman = 2 + floor(rand * 8);
    probabilites = rand(1, nHuffman);
    probabilites = probabilites / sum(probabilites);
    [dictHuffman, longueur] = huffmandict(1:nHuffman, probabilites);
    entropie = -sum(probabilites(probabilites > 0) .* log2(probabilites(probabilites > 0)));
    assert(longueur >= entropie - 1e-9 && longueur <= entropie + 1 + 1e-9);
    for aHuffman = 1:nHuffman
        for bHuffman = 1:nHuffman
            if aHuffman ~= bHuffman
                motA = dictHuffman{aHuffman, 2};
                motB = dictHuffman{bHuffman, 2};
                if numel(motA) <= numel(motB)
                    assert(~isequal(motA, motB(1:numel(motA))));
                end
            end
        end
    end
    signalHuffman = zeros(1, 40);
    for kHuffman = 1:40
        signalHuffman(kHuffman) = find(cumsum(probabilites) >= rand, 1);
    end
    assert(isequal(huffmandeco(huffmanenco(signalHuffman, dictHuffman), dictHuffman), ...
                   signalHuffman));
end
% Base trois : les chiffres vont de zero a deux.
dictionnaireTernaire = huffmandict(1:5, [0.4 0.2 0.2 0.1 0.1], 3);
for kHuffman = 1:5
    assert(all(dictionnaireTernaire{kHuffman, 2} >= 0));
    assert(all(dictionnaireTernaire{kHuffman, 2} <= 2));
end
assert(isequal(huffmandeco(huffmanenco([1 2 3 4 5 1 1], dictionnaireTernaire), ...
                           dictionnaireTernaire), [1 2 3 4 5 1 1]));

% Bruit blanc de puissance donnee, et motifs d'erreurs.
bruitMesure = wgn(1, 200000, 0);
assert(abs(10 * log10(mean(bruitMesure .^ 2))) < 0.1);
assert(abs(10 * log10(mean(wgn(1, 200000, 3) .^ 2)) - 3) < 0.1);
assert(abs(10 * log10(mean(wgn(1, 200000, 30, 'dBm') .^ 2))) < 0.1);
assert(abs(mean(wgn(1, 200000, 4, 'linear') .^ 2) - 4) < 0.2);
assert(abs(10 * log10(mean(wgn(1, 200000, 0, 50) .^ 2) / 50)) < 0.1);
bruitComplexe = wgn(1, 200000, 0, 'complex');
assert(~isreal(bruitComplexe));
assert(abs(10 * log10(mean(abs(bruitComplexe) .^ 2))) < 0.1);
assert(all(sum(randerr(4, 15, 2), 2) == 2));
assert(all(sum(randerr(5, 10), 2) == 1));
assert(isequal(size(randerr(3)), [3 3]));
assert(all(ismember(sum(randerr(300, 10, [0 1 3]), 2), [0 1 3])));
assert(abs(mean(sum(randerr(4000, 10, [0 2; 0.25 0.75]), 2) == 2) - 0.75) < 0.05);

% Entrelaceurs helicoidal et multiplexe.
for specHelice = {[3 4 1], [4 5 2], [2 6 1], [5 5 3]}
    lignesHelice = specHelice{1}(1);
    colonnesHelice = specHelice{1}(2);
    pasHelice = specHelice{1}(3);
    suiteHelice = 1:(lignesHelice * colonnesHelice);
    entrelaceeHelice = helscanintrlv(suiteHelice, lignesHelice, colonnesHelice, pasHelice);
    assert(numel(unique(entrelaceeHelice)) == numel(suiteHelice));
    assert(isequal(helscandeintrlv(entrelaceeHelice, lignesHelice, colonnesHelice, ...
                                   pasHelice), suiteHelice));
end
retardsMux = [0 2 4];
suiteMux = 1:40;
sortieMux = muxdeintrlv(muxintrlv(suiteMux, retardsMux), retardsMux);
retardTotal = max(retardsMux) * numel(retardsMux);
assert(all(sortieMux(1:retardTotal) == 0));
assert(isequal(sortieMux((retardTotal + 1):end), suiteMux(1:(end - retardTotal))));
% L'etat permet d'enchainer deux blocs sans rompre la rotation des voies.
[premierBloc, etatMux] = muxintrlv(1:20, retardsMux);
secondBloc = muxintrlv(21:40, retardsMux, etatMux);
assert(isequal([premierBloc, secondBloc], muxintrlv(1:40, retardsMux)));

% Spectre des distances : les valeurs connues des codes convolutifs.
for specConv = {{3, [7 5], 5}, {4, [17 13], 6}, {5, [35 23], 7}, ...
                {6, [75 53], 8}, {7, [171 133], 10}}
    treillisConv = poly2trellis(specConv{1}{1}, specConv{1}{2});
    spectreConv = distspec(treillisConv, 3);
    assert(spectreConv.dfree == specConv{1}{3}, mat2str(specConv{1}{2}));
end
% Et la verification par enumeration, sur deux d'entre eux.
for specConv = {{3, [7 5]}, {4, [17 13]}}
    treillisConv = poly2trellis(specConv{1}{1}, specConv{1}{2});
    poidsMinimal = Inf;
    for codeConv = 1:(2 ^ 10 - 1)
        bitsConv = zeros(1, 10);
        resteConv = codeConv;
        for bConv = 1:10
            bitsConv(bConv) = mod(resteConv, 2);
            resteConv = floor(resteConv / 2);
        end
        poidsConv = sum(convenc([bitsConv, zeros(1, specConv{1}{1} - 1)], treillisConv));
        if poidsConv > 0 && poidsConv < poidsMinimal
            poidsMinimal = poidsConv;
        end
    end
    assert(distspec(treillisConv).dfree == poidsMinimal, mat2str(specConv{1}{2}));
end
% Le spectre du code (7,5) est celui des livres.
spectreClassique = distspec(poly2trellis(3, [7 5]), 3);
assert(isequal(spectreClassique.weight, [1 4 12]));
% Un codeur catastrophique est reconnu comme tel.
assert(~iscatastrophic(poly2trellis(3, [7 5])));
assert(iscatastrophic(poly2trellis(3, [6 5])));

% Masque de decalage, integration et vidage, suite de Zadoff-Chu.
polynomeMasque = [1 0 0 1 1];
assert(isequal(shift2mask(polynomeMasque, 0), [0 0 0 1]));
for decalageMasque = [1 2 5 9]
    [~, resteMasque] = gfdeconv([zeros(1, decalageMasque), 1], fliplr(polynomeMasque), 2);
    assert(isequal(shift2mask(polynomeMasque, decalageMasque), ...
                   fliplr(completerLongueur(gftrunc(resteMasque), 4))));
end
assert(isequal(intdump([1 1 1 1 3 3 3 3], 4), [1 3]));
assert(isequal(intdump((1:8)', 2), [1.5; 3.5; 5.5; 7.5]));
assert(isequal(size(intdump(ones(8, 3), 4)), [2 3]));
suiteZadoff = zadoffChuSeq(25, 139);
assert(max(abs(abs(suiteZadoff) - 1)) < 1e-12);
autocorrelation = ifft(fft(suiteZadoff) .* conj(fft(suiteZadoff)));
assert(max(abs(autocorrelation(2:end))) / abs(autocorrelation(1)) < 1e-10);
assert(abs(abs(sum(suiteZadoff .* conj(zadoffChuSeq(34, 139)))) / 139 - 1 / sqrt(139)) < 1e-9);
for essaiZadoff = {{25, 138}, {0, 139}, {139, 139}, {5, 25}}
    refuseZadoff = false;
    try
        zadoffChuSeq(essaiZadoff{1}{1}, essaiZadoff{1}{2});
    catch
        refuseZadoff = true;
    end
    assert(refuseZadoff);
end

% Intervalle de confiance exact d'un taux d'erreur mesure.
[intervalleBer, tauxBer] = berconfint(10, 10000);
assert(abs(tauxBer - 0.001) < 1e-12);
assert(intervalleBer(1) < tauxBer && intervalleBer(2) > tauxBer);
assert(abs(1 - binocdf(9, 10000, intervalleBer(1)) - 0.025) < 1e-6);
assert(abs(binocdf(10, 10000, intervalleBer(2)) - 0.025) < 1e-6);
intervalleVide = berconfint(0, 1000);
assert(intervalleVide(1) == 0);
assert(abs(intervalleVide(2) - (1 - 0.025 ^ (1 / 1000))) < 1e-9);
intervalleLarge = berconfint(10, 10000, 0.99);
intervalleEtroit = berconfint(10, 10000, 0.90);
assert(intervalleLarge(1) < intervalleEtroit(1));
assert(intervalleLarge(2) > intervalleEtroit(2));

% Bornes des systemes codes : la decision douce vaut mieux que la dure,
% et le codage mieux que rien.
spectreBorne = distspec(poly2trellis(3, [7 5]), 4);
for decisionBorne = {'soft', 'hard'}
    courbeBorne = bercoding(0:8, 'conv', decisionBorne{1}, 1/2, ...
                            spectreBorne.dfree, spectreBorne.weight);
    assert(all(diff(courbeBorne) < 0));
end
assert(bercoding(6, 'conv', 'soft', 1/2, spectreBorne.dfree, spectreBorne.weight) < ...
       bercoding(6, 'conv', 'hard', 1/2, spectreBorne.dfree, spectreBorne.weight));
assert(bercoding(6, 'conv', 'soft', 1/2, spectreBorne.dfree, spectreBorne.weight) < ...
       berawgn(6, 'psk', 2));
assert(all(diff(bercoding(0:8, 'block', 'hard', 15, 7, 5)) < 0));
assert(bercoding(6, 'block', 'soft', 15, 7, 5) < bercoding(6, 'block', 'hard', 15, 7, 5));

% Defauts de synchronisation : sans defaut, on retombe sur la theorie.
assert(max(abs(bersync(0:8, 0, 'timing') - berawgn(0:8, 'psk', 2))) < 1e-12);
assert(all(bersync(0:8, 0.2, 'timing') > bersync(0:8, 0, 'timing')));
assert(all(bersync(0:8, pi/6, 'carrier') > bersync(0:8, 0, 'carrier')));
assert(abs(bersync(20, pi/2, 'carrier') - 0.5) < 1e-9);

% Methode semi-analytique : sur un canal parfait, elle rend exactement la
% courbe theorique, sans avoir tire un seul echantillon de bruit.
symbolesBpsk = pskmod(randi([0 1], 400, 1), 2);
assert(max(abs(semianalytic(symbolesBpsk, symbolesBpsk, 'psk', 2, 1, 1, 1, 0:2:10) - ...
               berawgn(0:2:10, 'psk', 2))) < 1e-12);
% Une attenuation uniforme ne change rien, une distorsion degrade.
assert(abs(semianalytic(symbolesBpsk, 0.7 * symbolesBpsk, 'psk', 2, 1, 1, 1, 6) - ...
           semianalytic(symbolesBpsk, symbolesBpsk, 'psk', 2, 1, 1, 1, 6)) < 1e-12);
assert(semianalytic(symbolesBpsk, filter([1 0.3], 1, symbolesBpsk), 'psk', 2, 1, 1, 1, 6) > ...
       semianalytic(symbolesBpsk, symbolesBpsk, 'psk', 2, 1, 1, 1, 6));

%% ------------------------------------------ corps de Galois
% L'arithmetique modulaire, verifiee sur ce qui la definit.
assert(isequal(gftrunc([1 0 1 0 0]), [1 0 1]));
assert(isequal(gftrunc([0 0 0]), 0));
assert(isequal(gfadd([1 1 0 1], [1 0 1]), [0 1 1 1]));
assert(isequal(gfadd([2 3], [4 4], 5), [1 2]));
assert(isequal(gfsub([1 2], [4 4], 5), [2 3]));
assert(isequal(gfadd([1 1], [1 0], 2, 5), [0 1 0 0 0]));
% Dans GF(2) l'addition est sa propre inverse.
motGalois = [1 0 1 1 0];
autreGalois = [0 1 1 0 1];
assert(isequal(gfadd(gfadd(motGalois, autreGalois), autreGalois), motGalois));
% Associativite, commutativite, et la soustraction qui defait la somme.
unGalois = [1 2 3]; deuxGalois = [4 0 2]; troisGalois = [3 3 1];
assert(isequal(gfadd(gfadd(unGalois, deuxGalois, 5), troisGalois, 5), ...
               gfadd(unGalois, gfadd(deuxGalois, troisGalois, 5), 5)));
assert(isequal(gfadd(unGalois, deuxGalois, 5), gfadd(deuxGalois, unGalois, 5)));
assert(isequal(gfsub(gfadd(unGalois, deuxGalois, 5), deuxGalois, 5), unGalois));
% Un ordre de corps non premier est refuse plutot que calcule de travers.
refuseCorps = false;
try
    gfadd(1, 1, 4);
catch
    refuseCorps = true;
end
assert(refuseCorps);

% Produit et quotient terme a terme : la division defait la
% multiplication partout ou le diviseur n'est pas nul.
assert(isequal(gfmul([2 3 4], [3 3 3], 5), [1 4 2]));
assert(isequal(gfdiv([1 4 2], [3 3 3], 5), [2 3 4]));
assert(gfdiv(1, 0, 5) == -1);
[~, valideGalois] = gfdiv([1 2], [0 3], 5);
assert(isequal(valideGalois, [false true]));
for ordreGalois = [2 3 5 7 11]
    aGalois = mod(1:20, ordreGalois);
    bGalois = mod((1:20) + 3, ordreGalois);
    [quotientGalois, okGalois] = gfdiv(gfmul(aGalois, bGalois, ordreGalois), ...
                                       bGalois, ordreGalois);
    assert(isequal(quotientGalois(okGalois), aGalois(okGalois)));
end

% Polynomes : la division euclidienne se recompose exactement.
assert(isequal(gfconv([1 1], [1 1]), [1 0 1]));
assert(isequal(gfconv([1 1], [1 1], 3), [1 2 1]));
for ordreGalois = [2 3 5]
    for essaiGalois = 1:15
        aPoly = mod(round(rand(1, 7) * 10), ordreGalois);
        bPoly = mod(round(rand(1, 3) * 10), ordreGalois);
        if all(bPoly == 0), bPoly(1) = 1; end
        [qPoly, rPoly] = gfdeconv(aPoly, bPoly, ordreGalois);
        assert(isequal(gftrunc(gfadd(gfconv(qPoly, bPoly, ordreGalois), rPoly, ordreGalois)), ...
                       gftrunc(aPoly)));
        assert(numel(gftrunc(rPoly)) < numel(gftrunc(bPoly)) || isequal(gftrunc(rPoly), 0));
    end
end

% Polynomes primitifs : le comptage connu phi(p^m-1)/m les valide tous.
assert(gfprimck([1 1 0 0 1]) == 1);
assert(gfprimck([1 1 1 1 1]) == 0);
assert(gfprimck([1 0 1]) == -1);
assert(gfprimck([0 1 1]) == -1);
for degreGalois = 2:6
    comptePrimitifs = size(gfprimfd(degreGalois, 'all'), 1);
    ordreCyclique = 2 ^ degreGalois - 1;
    indicateur = ordreCyclique;
    resteIndicateur = ordreCyclique;
    diviseur = 2;
    while diviseur * diviseur <= resteIndicateur
        if mod(resteIndicateur, diviseur) == 0
            indicateur = indicateur / diviseur * (diviseur - 1);
            while mod(resteIndicateur, diviseur) == 0
                resteIndicateur = resteIndicateur / diviseur;
            end
        end
        diviseur = diviseur + 1;
    end
    if resteIndicateur > 1
        indicateur = indicateur / resteIndicateur * (resteIndicateur - 1);
    end
    assert(comptePrimitifs == indicateur / degreGalois, sprintf('degre %d', degreGalois));
end
for degreGalois = 1:8
    assert(gfprimck(gfprimdf(degreGalois)) == 1);
end
assert(isequal(gfprimdf(4), [1 1 0 0 1]));
assert(isequal(gfprimdf(5), [1 0 1 0 0 1]));
assert(isequal(gfprimdf(8), [1 0 1 1 1 0 0 0 1]));
assert(gfprimck(gfprimdf(2, 3), 3) == 1);
assert(isequal(gfprimfd(4, 2), gfprimfd(4, 'max')));

% Table du corps : chaque element non nul y figure une fois et une seule.
tableGalois = gftable(3);
assert(isequal(size(tableGalois), [8 3]));
assert(isequal(tableGalois(1, :), [0 0 0]) && isequal(tableGalois(2, :), [1 0 0]));
assert(numel(unique(tableGalois(2:end, :) * [1; 2; 4])) == 7);
tableSeize = gftable(4);
assert(numel(unique(tableSeize(2:end, :) * [1; 2; 4; 8])) == 15);
refuseTable = false;
try
    gftable(3, [1 1 1 1]);   % pas primitif
catch
    refuseTable = true;
end
assert(refuseTable);

% Classes cyclotomiques : elles partagent exactement les exposants.
classesGalois = gfcosets(3);
assert(classesGalois(1, 1) == 0);
listeClasses = cosets(3);
assert(numel(listeClasses) == 3 && isequal(listeClasses{2}, [1 2 4]));
assert(sum(sum(~isnan(gfcosets(4)))) == 15);

% Rang sur un corps fini : ce n'est pas celui des reels.
assert(gfrank([1 1; 1 1]) == 1);
assert(gfrank([1 0; 0 1]) == 2);
assert(gfrank([2 4; 1 2], 5) == 1);
assert(rank([1 1; 1 3]) == 2 && gfrank([1 1; 1 3], 2) == 1);

% Racines dans une extension, et polynome minimal.
assert(isequal(gfroots([1 1 1], 2), [1; 2]));
racinesGalois = gfroots([1 1 0 1], 3);
assert(numel(racinesGalois) == 3);
racinesAvecZero = gfroots([0 1 1], 2);
assert(any(isinf(racinesAvecZero)) && any(racinesAvecZero == 0));
[~, minimauxGalois] = gfroots([1 1 0 1], 3);
assert(isequal(gftrunc(minimauxGalois{1}), [1 1 0 1]));

% Distance minimale d'un code : elle dit ce qu'il corrige.
[controleHamming, generatriceHamming] = hammgen(3);
assert(gfweight(generatriceHamming) == 3);
assert(gfweight(controleHamming, 'par') == 3);
assert(gfweight([1 1 0 1], 7) == 3);
assert(gfweight(ones(1, 5)) == 5);
assert(gfweight([eye(3), ones(3, 1)]) == 2);

% Filtrage dans GF(2) : boucle par un primitif, la suite est de periode
% maximale.
suiteGalois = gffilter(1, [1 1 0 1], [1 zeros(1, 20)]);
assert(isequal(suiteGalois(1:7), suiteGalois(8:14)));
assert(isequal(suiteGalois(8:14), suiteGalois(15:21)));
assert(sum(suiteGalois(1:7)) > 0);
suiteCourte = gffilter(1, [1 1 1], [1 zeros(1, 12)]);
assert(isequal(suiteCourte(1:3), suiteCourte(4:6)));
assert(isequal(gffilter([1 2], 1, [1 0 0 0], 5), [1 2 0 0]));
refuseFiltre = false;
try
    gffilter(1, [0 1], [1 0]);
catch
    refuseFiltre = true;
end
assert(refuseFiltre);

% Le zero du modulo ne doit pas etre negatif : sinon 1/mod(-4,2) vaudrait
% moins l'infini, et le signe se propagerait dans tout un calcul en corps
% fini.
assert(1 / mod(-4, 2) == Inf);
assert(1 / mod(-3, 3) == Inf);
assert(1 / rem(-4, 2) == Inf);
assert(mod(-4.5, 2) == 1.5);

%% -------------------------------- tableaux de corps et codes correcteurs
% Le corps GF(16) au complet : associativite, distributivite, inverses.
for iCorps = 0:15
    xCorps = gf(iCorps, 4);
    for jCorps = 0:15
        yCorps = gf(jCorps, 4);
        for kCorps = 0:3
            zCorps = gf(kCorps, 4);
            assert(double((xCorps + yCorps) + zCorps) == double(xCorps + (yCorps + zCorps)));
            assert(double((xCorps .* yCorps) .* zCorps) == double(xCorps .* (yCorps .* zCorps)));
            assert(double(xCorps .* (yCorps + zCorps)) == ...
                   double(xCorps .* yCorps + xCorps .* zCorps));
        end
    end
    if iCorps > 0
        assert(double(xCorps .* (gf(1, 4) ./ xCorps)) == 1);
    end
end
% La caracteristique vaut deux : ajouter deux fois ne change rien.
tableauCorps = gf([1 2 3], 3);
assert(all(double(tableauCorps + tableauCorps) == 0));
assert(all(double(tableauCorps ./ tableauCorps) == 1));
% L'ordre du groupe multiplicatif de GF(16) est quinze.
assert(double(gf(2, 4) .^ 15) == 1);
assert(double(gf(2, 4) .^ 0) == 1);
assert(double(gf(2, 4) .^ -1) == double(gf(1, 4) ./ gf(2, 4)));
assert(log(gf(1, 4)) == 0 && log(gf(2, 4)) == 1);
% Produit matriciel, concatenation, indexation.
matriceCorps = gf([1 2; 3 4], 4);
autreCorps = gf([5 6; 7 8], 4);
assert(double(matriceCorps(1, 1) .* autreCorps(1, 1) + ...
              matriceCorps(1, 2) .* autreCorps(2, 1)) == ...
       double(subsref(matriceCorps * autreCorps, substruct('()', {1, 1}))));
assert(isequal(double((matriceCorps * autreCorps) * matriceCorps), ...
               double(matriceCorps * (autreCorps * matriceCorps))));
assert(isequal(double(matriceCorps * gf(eye(2), 4)), double(matriceCorps)));
assert(isequal(size([matriceCorps, autreCorps]), [2 4]));
assert(isequal(size([matriceCorps; autreCorps]), [4 2]));
assert(isequal(double(matriceCorps.'), double(matriceCorps).'));
matriceCorps(1, 1) = gf(9, 4);
assert(double(matriceCorps(1, 1)) == 9);
matriceCorps(2, 2) = 11;
assert(double(matriceCorps(2, 2)) == 11);
assert(numel(matriceCorps) == 4 && ~isempty(matriceCorps) && isempty(gf([], 4)));
% Deux corps differents ne se melangent pas.
refuseMelange = false;
try
    gf(1, 3) + gf(1, 4);
catch
    refuseMelange = true;
end
assert(refuseMelange);
assert(double(gf(3, 4) + 1) == 2);

% BCH : le generateur divise x^n - 1, et la distance vaut au moins 2t+1.
for specBch = {[15 11], [15 7], [15 5], [31 26], [31 21], [63 57], [7 4]}
    nBch = specBch{1}(1);
    kBch = specBch{1}(2);
    [genBch, tBch] = bchgenpoly(nBch, kBch, [], 'double');
    assert(numel(genBch) - 1 == nBch - kBch);
    [~, resteBch] = gfdeconv([1, zeros(1, nBch - 1), 1], fliplr(genBch), 2);
    assert(isequal(gftrunc(resteBch), 0), sprintf('BCH(%d,%d)', nBch, kBch));
    assert(tBch >= 1);
end
assert(gfweight(fliplr(bchgenpoly(15, 7, [], 'double')), 15) >= 5);
assert(isa(bchgenpoly(15, 5), 'gf'));

% Le codage BCH est systematique, et tout mot non nul pese au moins la
% distance minimale.
messageBch = gf([1 0 1 1 0 0 1], 1);
motBch = bchenc(messageBch, 15, 7);
assert(isequal(double(motBch(9:15)), double(messageBch)));
for formeBch = {'end', 'beg', 'none'}
    [~, resteForme] = gfdeconv(fliplr(double(bchenc(messageBch, 15, 7, formeBch{1}))), ...
                               fliplr(bchgenpoly(15, 7, [], 'double')), 2);
    assert(isequal(gftrunc(resteForme), 0), formeBch{1});
end
motDebut = bchenc(messageBch, 15, 7, 'beg');
assert(isequal(double(motDebut(1:7)), double(messageBch)));
assert(isequal(size(bchenc(gf([1 0 1 1 0 0 1; 0 1 1 0 1 0 1], 1), 15, 7)), [2 15]));
for codeBch = 0:63
    bitsBch = zeros(1, 7);
    resteBits = codeBch;
    for bBch = 1:7
        bitsBch(bBch) = mod(resteBits, 2);
        resteBits = floor(resteBits / 2);
    end
    motEssai = double(bchenc(gf(bitsBch, 1), 15, 7));
    if any(bitsBch)
        assert(sum(motEssai) >= 5);
    else
        assert(all(motEssai == 0));
    end
end

% Le decodage BCH corrige toutes les configurations jusqu'a t erreurs.
[sortieBch, erreursBch] = bchdec(motBch, 15, 7);
assert(erreursBch == 0 && isequal(double(sortieBch), double(messageBch)));
for posBch = 1:15
    recuBch = double(motBch);
    recuBch(posBch) = 1 - recuBch(posBch);
    [sortieBch, erreursBch] = bchdec(gf(recuBch, 1), 15, 7);
    assert(erreursBch == 1 && isequal(double(sortieBch), double(messageBch)));
end
compteBch = 0;
for p1Bch = 1:15
    for p2Bch = (p1Bch + 1):15
        recuBch = double(motBch);
        recuBch(p1Bch) = 1 - recuBch(p1Bch);
        recuBch(p2Bch) = 1 - recuBch(p2Bch);
        [sortieBch, erreursBch] = bchdec(gf(recuBch, 1), 15, 7);
        if erreursBch == 2 && isequal(double(sortieBch), double(messageBch))
            compteBch = compteBch + 1;
        end
    end
end
assert(compteBch == 105);
for specBch = {[15 5 3], [31 21 2], [63 51 2], [7 4 1]}
    nBch = specBch{1}(1);
    kBch = specBch{1}(2);
    tBch = specBch{1}(3);
    for essaiBch = 1:10
        msgBch = gf(double(rand(1, kBch) > 0.5), 1);
        recuBch = double(bchenc(msgBch, nBch, kBch));
        posBch = randperm(nBch);
        posBch = posBch(1:tBch);
        recuBch(posBch) = 1 - recuBch(posBch);
        [sortieBch, erreursBch] = bchdec(gf(recuBch, 1), nBch, kBch);
        assert(erreursBch == tBch && isequal(double(sortieBch), double(msgBch)), ...
               sprintf('BCH(%d,%d)', nBch, kBch));
    end
end

% Reed-Solomon : les syndromes d'un mot de code sont tous nuls.
messageRs = gf([1 2 3 4 5 6 7 8 9 10 11], 4);
motRs = rsenc(messageRs, 15, 11);
assert(isequal(double(motRs(1:11)), double(messageRs)));
[journalRs, exposantsRs] = matlibre_gf_journal(4, motRs.prim_poly);
for iRs = 1:4
    sommeRs = 0;
    for posRs = 1:15
        if double(motRs(posRs)) ~= 0
            eRs = mod(iRs * (15 - posRs), 15);
            sommeRs = bitxor(sommeRs, ...
                matlibre_gf_mul(double(motRs(posRs)), exposantsRs(eRs + 1), 4, motRs.prim_poly));
        end
    end
    assert(sommeRs == 0, sprintf('syndrome %d', iRs));
end
for specRs = {[7 3], [15 9], [31 21], [63 55]}
    [genRs, tRs] = rsgenpoly(specRs{1}(1), specRs{1}(2));
    assert(tRs == (specRs{1}(1) - specRs{1}(2)) / 2);
    assert(numel(double(genRs)) - 1 == specRs{1}(1) - specRs{1}(2));
end

% Le decodage corrige un symbole quelconque, a n'importe quelle position.
[sortieRs, erreursRs] = rsdec(motRs, 15, 11);
assert(erreursRs == 0 && isequal(double(sortieRs), double(messageRs)));
for posRs = 1:15
    for valeurRs = 1:15
        recuRs = double(motRs);
        recuRs(posRs) = bitxor(recuRs(posRs), valeurRs);
        [sortieRs, erreursRs] = rsdec(gf(recuRs, 4), 15, 11);
        assert(erreursRs == 1 && isequal(double(sortieRs), double(messageRs)), ...
               sprintf('position %d valeur %d', posRs, valeurRs));
    end
end
for specRs = {[7 3], [15 9], [31 21]}
    nRs = specRs{1}(1);
    kRs = specRs{1}(2);
    mRs = round(log2(nRs + 1));
    tRs = (nRs - kRs) / 2;
    for essaiRs = 1:10
        msgRs = gf(floor(rand(1, kRs) * 2 ^ mRs), mRs);
        recuRs = double(rsenc(msgRs, nRs, kRs));
        posRs = randperm(nRs);
        posRs = posRs(1:tRs);
        for jRs = 1:tRs
            recuRs(posRs(jRs)) = bitxor(recuRs(posRs(jRs)), 1 + floor(rand * (2 ^ mRs - 1)));
        end
        [sortieRs, erreursRs] = rsdec(gf(recuRs, mRs), nRs, kRs);
        assert(erreursRs == tRs && isequal(double(sortieRs), double(msgRs)), ...
               sprintf('RS(%d,%d)', nRs, kRs));
    end
end

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
% Les familles de filtres se construisent au lieu d'etre recopiees, et
% chacune se verifie sur ce qui la definit.
for N = 1:8
    filtreDb = dbaux(N);
    assert(numel(filtreDb) == 2 * N && abs(sum(filtreDb) - 1) < 1e-12);
    assert(abs(sum(dbaux(N, 0) .^ 2) - 1) < 1e-10);
    filtreSym = symaux(N);
    assert(numel(filtreSym) == 2 * N && abs(sum(filtreSym) - 1) < 1e-12);
end
assert(isequal(dbwavf('haar'), dbwavf('db1')));
assert(max(abs(dbwavf('db4') - dbaux(4))) < 1e-15);
assert(max(abs(symwavf('sym4') - symaux(4))) < 1e-15);
% Les moments nuls de dbN : la somme alternee ponderee par n^k s'annule
% pour k jusqu'a N-1. C'est ce qui definit l'ondelette.
filtreOrtho = dbaux(5, 0);
rangs = 0:(numel(filtreOrtho) - 1);
for k = 0:4
    assert(abs(sum((-1) .^ rangs .* rangs .^ k .* filtreOrtho)) < 1e-8);
end
% Le symlet est plus symetrique que la Daubechies de meme ordre.
asymetrie = @(h) sum((h - fliplr(h)) .^ 2);
assert(asymetrie(symaux(6, 0)) < asymetrie(dbaux(6, 0)));

% Biorthogonales : la reconstruction est parfaite et le repliement
% s'annule, ce qui ne va pas de soi puisque le banc n'est pas orthogonal.
famille = {'haar', 'db4', 'sym6', 'bior1.1', 'bior1.3', 'bior1.5', ...
           'bior2.2', 'bior2.4', 'bior2.6', 'bior2.8', 'bior3.1', ...
           'bior3.3', 'bior3.5', 'bior3.7', 'bior3.9', 'bior4.4', ...
           'rbio1.3', 'rbio2.2', 'rbio4.4'};
signalLong = cos((1:128) / 7) + (1:128) / 90;
for k = 1:numel(famille)
    [lod, hid, lor, hir] = wfilters(famille{k});
    alterne = (-1) .^ (0:(numel(lod) - 1));
    distorsion = conv(lod, lor) + conv(hid, hir);
    repliement = conv(lod .* alterne, lor) + conv(hid .* alterne, hir);
    [~, pic] = max(abs(distorsion));
    assert(abs(distorsion(pic) - 2) < 1e-10, famille{k});
    assert(max(abs(distorsion([1:pic-1, pic+1:end]))) < 1e-10, famille{k});
    assert(max(abs(repliement)) < 1e-10, famille{k});
    [aUn, dUn] = dwt(signalLong, famille{k});
    assert(max(abs(idwt(aUn, dUn, famille{k}) - signalLong)) < 1e-9, famille{k});
    [cBior, lBior] = wavedec(signalLong, 3, famille{k});
    assert(max(abs(waverec(cBior, lBior, famille{k}) - signalLong)) < 1e-9, famille{k});
end
% Les filtres biorthogonaux sont symetriques ; aucun filtre orthogonal a
% support compact ne l'est, sauf Haar. Les zeros de complement, eux, ne
% sont pas repartis symetriquement : c'est l'alignement des deux filtres
% qui commande leur place, non l'esthetique.
utile = @(v) v(find(abs(v) > 1e-12, 1):find(abs(v) > 1e-12, 1, 'last'));
[rfBior, dfBior] = biorwavf('bior2.2');
assert(max(abs(utile(rfBior) - fliplr(utile(rfBior)))) < 1e-15);
assert(max(abs(utile(dfBior) - fliplr(utile(dfBior)))) < 1e-15);
assert(numel(utile(rfBior)) == 3 && numel(utile(dfBior)) == 5);
% bior4.4 est le couple 9/7 de JPEG 2000 : neuf et sept coefficients.
[rf44, df44] = biorwavf('bior4.4');
assert(sum(abs(rf44) > 1e-12) == 7 && sum(abs(df44) > 1e-12) == 9);
% rbio echange les deux roles.
[rfR, dfR] = rbiowavf('rbio2.2');
assert(max(abs(rfR - dfBior)) < 1e-15 && max(abs(dfR - rfBior)) < 1e-15);
% Les deux noms que la construction spline ne donne pas sont refuses.
for nomRefuse = {'bior5.5', 'bior6.8'}
    refuse = false;
    try
        biorwavf(nomRefuse{1});
    catch
        refuse = true;
    end
    assert(refuse, nomRefuse{1});
end
% IDWT sait tronquer a la longueur voulue.
[aImpair, dImpair] = dwt(1:7, 'db2');
assert(numel(idwt(aImpair, dImpair, 'db2', 7)) == 7);

% Meyer : sa fonction auxiliaire est le polynome plat aux deux bouts.
assert(abs(meyeraux(0)) < 1e-15 && abs(meyeraux(1) - 1) < 1e-15);
for t = [0.1 0.3 0.5 0.7 0.9]
    assert(abs(meyeraux(t) + meyeraux(1 - t) - 1) < 1e-12);
end
[psiMeyer, xMeyer] = meyer(-8, 8, 1024);
assert(abs(trapz(xMeyer, psiMeyer)) < 1e-4);
assert(abs(trapz(xMeyer, psiMeyer .^ 2) - 1) < 1e-2);
[phiMeyer, xPhi] = meyer(-8, 8, 1024, 'phi');
assert(abs(trapz(xPhi, phiMeyer) - 1) < 1e-2);

% Ondelettes continues complexes : energie unite et moyenne nulle a tout
% ordre, spectre centre sur la frequence demandee.
for ordre = 1:8
    [psiC, xC] = cgauwavf(-8, 8, 4001, ordre);
    assert(abs(trapz(xC, abs(psiC) .^ 2) - 1) < 1e-6);
    assert(abs(trapz(xC, psiC)) < 1e-6);
end
psiMorlet = cmorwavf(-16, 16, 4096, 1, 2);
spectre = fftshift(abs(fft(psiMorlet)));
frequences = (-2048:2047) / 32;
[~, iPic] = max(spectre);
assert(abs(frequences(iPic) - 2) < 0.05);
% Shannon : le spectre occupe exactement [fc-fb/2, fc+fb/2].
psiShannon = shanwavf(-64, 64, 8192, 1, 1.5);
spectreShannon = fftshift(abs(fft(psiShannon)));
fShannon = (-4096:4095) / 128;
dans = spectreShannon > 0.3 * max(spectreShannon);
assert(abs(min(fShannon(dans)) - 1) < 0.05 && abs(max(fShannon(dans)) - 2) < 0.05);
% L'ondelette spline d'ordre un est celle de Shannon.
assert(max(abs(fbspwavf(-20, 20, 1000, 1, 1, 1.5) - ...
                shanwavf(-20, 20, 1000, 1, 1.5))) < 1e-14);

% La liste des noms couvre ce que WFILTERS sait construire :
% haar, db1 a db45, sym1 a sym45 et coif1 a coif5.
nomsOrtho = wavenames('orthogonal');
assert(numel(nomsOrtho) == 1 + 45 + 45 + 5);
assert(any(strcmp(nomsOrtho, 'haar')));
for k = 1:45
    assert(any(strcmp(nomsOrtho, sprintf('db%d', k))));
    assert(any(strcmp(nomsOrtho, sprintf('sym%d', k))));
end
for k = 1:5
    assert(any(strcmp(nomsOrtho, sprintf('coif%d', k))));
end
nomsBior = wavenames('biorthogonal');
assert(any(strcmp(nomsBior, 'bior4.4')) && any(strcmp(nomsBior, 'rbio4.4')));
for k = 1:numel(nomsBior)
    [loBanc, ~, ~, ~] = wfilters(nomsBior{k});
    assert(abs(sum(loBanc) - sqrt(2)) < 1e-10, nomsBior{k});
end
assert(numel(wavenames) == numel(wavenames('orthogonal')) + ...
       numel(wavenames('biorthogonal')) + numel(wavenames('continuous')));

% Mesures de qualite : elles se verifient sur des ecarts connus.
[psnrEssai, mseEssai, maxEssai, ratioEssai] = measerr(0:255, (0:255) + 0.5);
assert(abs(mseEssai - 0.25) < 1e-12 && abs(maxEssai - 0.5) < 1e-12);
assert(abs(psnrEssai - 10 * log10(255 ^ 2 / 0.25)) < 1e-12);
assert(ratioEssai > 1);
assert(isinf(measerr(0:255, 0:255)));

% Le mode de prolongement se lit et se pose ; MatLibre n'analyse qu'en
% periodique, et refuse les autres au lieu de faire semblant.
assert(strcmp(dwtmode('status'), 'per'));
dwtmode('per', 'nodisp');
for modeRefuse = {'sym', 'zpd', 'inconnu'}
    refuse = false;
    try
        dwtmode(modeRefuse{1});
    catch
        refuse = true;
    end
    assert(refuse, modeRefuse{1});
end

% Debruitage par l'interface d'origine : les quatre regles et les deux
% seuillages ramenent tous le bruit.
[propreW, bruiteW] = wnoise(3, 10, 7, 5);
distanceDepart = norm(bruiteW - propreW);
for regleSeuil = {'sqtwolog', 'rigrsure', 'heursure', 'minimaxi'}
    for typeSeuil = {'s', 'h'}
        debruite = wden(bruiteW, regleSeuil{1}, typeSeuil{1}, 'sln', 4, 'db4');
        assert(norm(debruite - propreW) < distanceDepart, regleSeuil{1});
    end
end
for echelleBruit = {'one', 'sln', 'mln'}
    assert(numel(wden(bruiteW, 'sqtwolog', 's', echelleBruit{1}, 4, 'sym4')) == numel(bruiteW));
end
[cBruit, lBruit] = wavedec(bruiteW, 4, 'db4');
assert(max(abs(wden(cBruit, lBruit, 'sqtwolog', 's', 'sln', 4, 'db4') - ...
                wden(bruiteW, 'sqtwolog', 's', 'sln', 4, 'db4'))) < 1e-12);

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
% Energie d'une image decomposee : elle se repartit et somme a cent.
[cEnergie, sEnergie] = wavedec2(image16, 2, 'haar');
[energieA, energieD] = wenergy2(cEnergie, sEnergie);
assert(isequal(size(energieD), [2 3]));
assert(abs(energieA + sum(energieD(:)) - 100) < 1e-9);
[energieA4, energieH, energieV, energieDia] = wenergy2(cEnergie, sEnergie);
assert(abs(energieA4 - energieA) < 1e-12);
assert(abs(energieA + sum(energieH) + sum(energieV) + sum(energieDia) - 100) < 1e-9);

% Reconstruction directe d'un coefficient d'image : un detail remonte
% garde sa moyenne nulle, une approximation son integrale.
motif = upcoef2('h', 1, 'haar', 2);
assert(isequal(size(motif), [4 4]) && abs(sum(motif(:))) < 1e-12);
assert(abs(sum(sum(upcoef2('a', 1, 'haar', 2))) - 4) < 1e-12);

% Remonter d'un niveau ne change pas ce que la decomposition represente.
[cTrois, sTrois] = wavedec2(image16, 3, 'db2');
[cDeux, sDeux, approximationRemontee] = upwlev2(cTrois, sTrois, 'db2');
assert(size(sDeux, 1) == size(sTrois, 1) - 1);
assert(isequal(size(approximationRemontee), sDeux(1, :)));
assert(max(max(abs(waverec2(cDeux, sDeux, 'db2') - ...
                   waverec2(cTrois, sTrois, 'db2')))) < 1e-9);

% Seuillage des coefficients d'image : annuler un bloc retire sa seule
% energie, attenuer le divise exactement.
[cSeuil, sSeuil] = wavedec2(image16, 2, 'db2');
sansH = wthcoef2('h', cSeuil, sSeuil, 1);
[~, energieAvant] = wenergy2(cSeuil, sSeuil);
[~, energieApres] = wenergy2(sansH, sSeuil);
assert(energieAvant(1, 1) > 0 && energieApres(1, 1) < 1e-12);
assert(sum(cSeuil ~= sansH) == prod(sSeuil(3, :)));
attenue = wthcoef2('v', cSeuil, sSeuil, 2, 0.5);
change = find(cSeuil ~= attenue);
assert(~isempty(change) && max(abs(attenue(change) * 2 - cSeuil(change))) < 1e-12);
assert(all(abs(wthcoef2('t', cSeuil, sSeuil, 1:2, 3, 's')) <= abs(cSeuil) + 1e-12));
sansApproximation = wthcoef2('a', cSeuil, sSeuil);
assert(all(sansApproximation(1:prod(sSeuil(1, :))) == 0));

% Transformee stationnaire d'image : redondante, inversible, invariante
% par translation.
imageSwt = magic(16) + 0.1 * (1:16)' * (1:16);
for nomSwt = {'haar', 'db2', 'sym4', 'bior2.2'}
    [sa, sh, sv, sd] = swt2(imageSwt, 2, nomSwt{1});
    assert(isequal(size(sa), [16 16 2]), nomSwt{1});
    assert(max(max(abs(iswt2(sa, sh, sv, sd, nomSwt{1}) - imageSwt))) < 1e-9, nomSwt{1});
end
[saUn, ~, ~, ~] = swt2(imageSwt, 1, 'db2');
[saDecale, ~, ~, ~] = swt2(circshift(imageSwt, [3 5]), 1, 'db2');
assert(max(max(abs(circshift(saUn, [3 5]) - saDecale))) < 1e-12);
% La stationnaire a une dimension marche aussi pour les biorthogonales.
signalSwt = cos((1:64) / 5) + (1:64) / 40;
for nomSwt = {'haar', 'db4', 'bior2.2', 'bior4.4', 'rbio2.2'}
    [sa1, sd1] = swt(signalSwt, 3, nomSwt{1});
    assert(max(abs(iswt(sa1, sd1, nomSwt{1}) - signalSwt)) < 1e-9, nomSwt{1});
end

% Fonctions bidimensionnelles : ce sont les produits des fonctions a une
% dimension, et le detail garde sa moyenne nulle.
[phiDeux, psiH, psiV, psiD, grille] = wavefun2('db2', 6);
pasGrille = grille(2) - grille(1);
assert(isequal(size(phiDeux), [numel(grille) numel(grille)]));
assert(abs(sum(phiDeux(:)) * pasGrille ^ 2 - 1) < 1e-6);
for detailDeux = {psiH, psiV, psiD}
    assert(abs(sum(detailDeux{1}(:)) * pasGrille ^ 2) < 1e-6);
end
[phiUn, psiUn] = wavefun('db2', 6);
assert(max(max(abs(psiD - psiUn(:) * psiUn(:).'))) < 1e-15);

% Debruitage d'image : les quatre regles ramenent le bruit.
grilleX = linspace(-3, 3, 64);
[maillageX, maillageY] = meshgrid(grilleX);
imagePropre = 40 * exp(-(maillageX .^ 2 + maillageY .^ 2) / 4) + 10 * (maillageX > 0);
imageBruitee = imagePropre + 3 * randn(64);
distanceImage = norm(imageBruitee - imagePropre, 'fro');
for methodeImage = {'Bayes', 'UniversalThreshold', 'SURE', 'Minimax'}
    debruitee = wdenoise2(imageBruitee, 'DenoisingMethod', methodeImage{1});
    assert(norm(debruitee - imagePropre, 'fro') < distanceImage, methodeImage{1});
end
autreReglage = wdenoise2(imageBruitee, 3, 'Wavelet', 'sym4', ...
                         'ThresholdRule', 'Hard', 'NoiseEstimate', 'LevelDependent');
assert(isequal(size(autreReglage), size(imageBruitee)));
assert(norm(autreReglage - imagePropre, 'fro') < distanceImage);
imageCouleur = wdenoise2(cat(3, imageBruitee, imageBruitee, imageBruitee));
assert(isequal(size(imageCouleur), [64 64 3]));
assert(max(max(abs(imageCouleur(:, :, 1) - imageCouleur(:, :, 3)))) < 1e-12);

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

% Variance et correlation par echelle : la MODWT conserve l'energie, si
% bien que les variances d'echelle somment a celle du signal.
marche = cumsum(randn(1, 1024));
wMarche = modwt(marche, 'db2', 4);
variancesEchelle = modwtvar(wMarche);
assert(abs(sum(variancesEchelle) - sum(marche .^ 2) / 1024) < 1e-9);
varianceBords = modwtvar(wMarche, 'db2');
assert(numel(varianceBords) == numel(variancesEchelle));
[~, bornesVariance] = modwtvar(wMarche, 'db2', 0.95);
assert(all(bornesVariance(:, 1) <= varianceBords) && ...
       all(bornesVariance(:, 2) >= varianceBords));
% Un signal est parfaitement correle avec lui-meme, a toutes les echelles.
assert(max(abs(modwtcorr(wMarche, wMarche, 'db2') - 1)) < 1e-12);
[~, bornesCorrelation] = modwtcorr(wMarche, modwt(cumsum(randn(1, 1024)), 'db2', 4), 'db2');
assert(isequal(size(bornesCorrelation), [5 2]));
% La correlation croisee retrouve le decalage.
[croisee, decalages] = modwtxcorr(modwt(marche, 'db2', 3), ...
                                  modwt(circshift(marche, [0 8]), 'db2', 3), 'db2', 30);
[~, iCroisee] = max(croisee{4});
assert(abs(abs(decalages(iCroisee)) - 8) <= 1);

% Transformee continue inverse : le filtre que forment analyse et somme
% est mesure puis inverse, ce qui rend le signal a quelques centiemes.
tempsCwt = (0:1023) / 1024;
echellesCwt = 2 .^ (0:0.125:7);
centreCwt = 300:724;
for essaiCwt = {sin(2 * pi * 32 * tempsCwt), ...
                sin(2 * pi * 16 * tempsCwt) + 0.5 * cos(2 * pi * 64 * tempsCwt)}
    for nomCwt = {'morl', 'mexh'}
        reconstruit = icwt(cwt(essaiCwt{1}, echellesCwt, nomCwt{1}), echellesCwt, nomCwt{1});
        rapport = norm(reconstruit(centreCwt) - essaiCwt{1}(centreCwt)) / ...
                  norm(essaiCwt{1}(centreCwt));
        assert(rapport < 0.05, nomCwt{1});
    end
end

% Mouvement brownien fractionnaire : la variance des increments croit
% comme k^(2H), et les trois estimateurs retrouvent H.
for hurst = [0.3 0.5 0.7 0.9]
    trajectoire = wfbm(hurst, 8192);
    pas = 2 .^ (0:9);
    variancesPas = zeros(size(pas));
    for kPas = 1:numel(pas)
        ecartPas = trajectoire(1 + pas(kPas):end) - trajectoire(1:end - pas(kPas));
        variancesPas(kPas) = var(ecartPas);
    end
    penteIncrements = polyfit(log2(pas), log2(variancesPas), 1);
    assert(abs(penteIncrements(1) / 2 - hurst) < 0.1, sprintf('H=%g', hurst));
    estimationsHurst = wfbmesti(trajectoire);
    assert(numel(estimationsHurst) == 3);
    assert(max(abs(estimationsHurst - hurst)) < 0.1, sprintf('esti H=%g', hurst));
end
[trajectoire, increments] = wfbm(0.6, 512);
assert(max(abs(cumsum(increments) - trajectoire)) < 1e-9);
for hurstRefuse = [0 1 1.5]
    refuse = false;
    try
        wfbm(hurstRefuse, 100);
    catch
        refuse = true;
    end
    assert(refuse);
end


% ------------------------------------------------ paquets d'ondelettes
% Les indices de noeuds : aller-retour sur tout un arbre.
assert(depo2ind(2, [0 0]) == 0 && depo2ind(2, [3 5]) == 12);
assert(isequal(ind2depo(2, [1 2 3]), [1 0; 1 1; 2 0]));
for ordreArbre = [2 4]
    for indiceEssai = 0:60
        assert(depo2ind(ordreArbre, ind2depo(ordreArbre, indiceEssai)) == indiceEssai);
    end
end
refuseIndice = false;
try
    depo2ind(2, [2 4]);
catch
    refuseIndice = true;
end
assert(refuseIndice);

% Un arbre complet de profondeur trois : huit feuilles, reconstruction
% exacte, et la somme des composantes des feuilles redonne le signal.
signalPaquet = cos((1:64) / 5) + (1:64) / 40;
for nomPaquet = {'haar', 'db2', 'db4', 'sym4', 'bior2.2'}
    arbrePaquet = wpdec(signalPaquet, 3, nomPaquet{1});
    assert(ntnode(arbrePaquet) == 8 && treedpth(arbrePaquet) == 3, nomPaquet{1});
    assert(max(abs(wprec(arbrePaquet) - signalPaquet)) < 1e-9, nomPaquet{1});
    sommeFeuilles = zeros(1, 64);
    listeFeuilles = leaves(arbrePaquet);
    for kFeuille = 1:numel(listeFeuilles)
        sommeFeuilles = sommeFeuilles + wprcoef(arbrePaquet, listeFeuilles(kFeuille));
    end
    assert(max(abs(sommeFeuilles - signalPaquet)) < 1e-9, nomPaquet{1});
end
arbrePaquet = wpdec(signalPaquet, 3, 'db2');
assert(isequal(leaves(arbrePaquet)', 7:14));
assert(isequal(leaves(arbrePaquet, 'dp'), [3 * ones(8, 1), (0:7)']));
assert(isequal(tnodes(arbrePaquet), leaves(arbrePaquet)));
[~, taillesFeuilles] = leaves(arbrePaquet);
assert(all(taillesFeuilles(:, 2) == 8));
assert(isequal(wpcoef(arbrePaquet, 5), wpcoef(arbrePaquet, [2 2])));

% Scinder et refermer : l'arbre change de forme sans rien perdre.
arbreUn = wpsplt(wpdec(signalPaquet, 1, 'db2'), 1);
assert(isequal(leaves(arbreUn)', [2 3 4]));
arbreReferme = wpjoin(arbrePaquet, 1);
assert(isequal(leaves(arbreReferme)', [1 11 12 13 14]));
assert(max(abs(wprec(arbreReferme) - signalPaquet)) < 1e-9);
assert(isequal(leaves(wpjoin(arbreReferme, 2))', [1 2]));
assert(max(abs(wprec(wpjoin(arbreReferme, 2)) - signalPaquet)) < 1e-9);

% Paquets d'image : quatre enfants par noeud.
imagePaquet = magic(16) + 0.1 * (1:16)' * (1:16);
for nomPaquet = {'haar', 'db2', 'sym4', 'bior2.2'}
    arbreImage = wpdec2(imagePaquet, 2, nomPaquet{1});
    assert(ntnode(arbreImage) == 16, nomPaquet{1});
    assert(max(max(abs(wprec2(arbreImage) - imagePaquet))) < 1e-9, nomPaquet{1});
end
arbreImage = wpdec2(imagePaquet, 2, 'db2');
sommeImage = zeros(16, 16);
feuillesImage = leaves(arbreImage);
for kFeuille = 1:numel(feuillesImage)
    sommeImage = sommeImage + wprcoef(arbreImage, feuillesImage(kFeuille));
end
assert(max(max(abs(sommeImage - imagePaquet))) < 1e-9);
assert(ntnode(wpjoin(wpsplt(wpdec2(imagePaquet, 1, 'db2'), 2), 2)) == 4);

% L'entropie est additive : c'est ce dont BESTTREE a besoin.
assert(abs(wentropy([1 0 0 0], 'shannon')) < 1e-15);
assert(abs(wentropy([1 1 1 1] / 2, 'shannon') - log(4)) < 1e-12);
assert(wentropy([3 1 0.1], 'threshold', 0.5) == 2);
assert(abs(wentropy([3 4], 'norm', 2) - 25) < 1e-12);
vecteurEntropie = cos((1:64) / 3);
assert(abs(wentropy(vecteurEntropie, 'shannon') - ...
           wentropy(vecteurEntropie(1:32), 'shannon') - ...
           wentropy(vecteurEntropie(33:64), 'shannon')) < 1e-10);
refuseEntropie = false;
try
    wentropy([1 2], 'norm');
catch
    refuseEntropie = true;
end
assert(refuseEntropie);

% BESTTREE elague sans jamais empirer l'entropie ni casser la
% reconstruction.
signalBest = sin((1:256) / 3) + 0.3 * cos((1:256) / 17);
arbreComplet = wpdec(signalBest, 4, 'db2');
[arbreMeilleur, entropiesRetenues, entropiesPropres] = besttree(arbreComplet);
assert(ntnode(arbreMeilleur) <= ntnode(arbreComplet));
assert(entropiesRetenues(1) <= entropiesPropres(1) + 1e-12);
assert(max(abs(wprec(arbreMeilleur) - signalBest)) < 1e-9);
arbreImageMeilleur = besttree(wpdec2(magic(16), 2, 'haar'));
assert(max(max(abs(wprec2(arbreImageMeilleur) - magic(16)))) < 1e-9);

% Seuillage des paquets : l'approximation est epargnee quand on le
% demande, et pas autrement.
arbreSeuil = wpdec(1:64, 3, 'db2');
approximationAvant = wpcoef(arbreSeuil, 7);
assert(max(abs(wpcoef(wpthcoef(arbreSeuil, 1, 's', 2), 7) - approximationAvant)) < 1e-15);
assert(max(abs(wpcoef(wpthcoef(arbreSeuil, 0, 's', 2), 7) - approximationAvant)) > 0);

% Debruitage par paquets : la meilleure base est cherchee avant de
% seuiller.
[proprePaquet, bruitePaquet] = wnoise(3, 10, 7, 5);
distancePaquet = norm(bruitePaquet - proprePaquet);
for typeSeuilPaquet = {'s', 'h'}
    [debruitePaquet, ~, part0, partL2] = wpdencmp(bruitePaquet, typeSeuilPaquet{1}, ...
                                                  4, 'db4', 'shannon', 0, 1);
    assert(norm(debruitePaquet - proprePaquet) < distancePaquet);
    assert(part0 > 50 && partL2 > 90);
end
assert(norm(wpdencmp(bruitePaquet, 's', 4, 'db4', 'threshold', 3, 1) - proprePaquet) ...
       < distancePaquet);
arbreDeja = wpdec(bruitePaquet, 4, 'db4');
assert(max(abs(wpdencmp(arbreDeja, 's', 'shannon', 0, 1) - ...
                wpdencmp(bruitePaquet, 's', 4, 'db4', 'shannon', 0, 1))) < 1e-12);
% Sur une image lisse, le debruitage par paquets gagne aussi.
imageLisse = 40 * exp(-(maillageX .^ 2 + maillageY .^ 2) / 4);
imageLisseBruitee = imageLisse + 3 * randn(64);
assert(norm(wpdencmp(imageLisseBruitee, 's', 3, 'sym4', 'shannon', 0, 1) - imageLisse, 'fro') ...
       < norm(imageLisseBruitee - imageLisse, 'fro'));

% Fonctions de paquets : W0 est la fonction d'echelle, les autres sont de
% moyenne nulle, toutes sont d'energie un et orthogonales entre elles.
[fonctionsPaquet, grillePaquet] = wpfun('db2', 3, 8);
assert(size(fonctionsPaquet, 1) == 4);
assert(abs(trapz(grillePaquet, fonctionsPaquet(1, :)) - 1) < 0.02);
for kFonction = 1:4
    assert(abs(trapz(grillePaquet, fonctionsPaquet(kFonction, :) .^ 2) - 1) < 0.02);
    if kFonction > 1
        assert(abs(trapz(grillePaquet, fonctionsPaquet(kFonction, :))) < 0.02);
    end
end
for a = 1:4
    for b = (a + 1):4
        assert(abs(trapz(grillePaquet, fonctionsPaquet(a, :) .* fonctionsPaquet(b, :))) < 5e-3);
    end
end

% Paquets a chevauchement maximal : reconstruction exacte, energie
% conservee, et les bandes rangees par frequence croissante.
signalModwpt = cos((1:256) / 7) + 0.4 * sin((1:256) / 2);
for nomModwpt = {'haar', 'db2', 'sym4'}
    for niveauModwpt = [2 3]
        bandes = modwpt(signalModwpt, nomModwpt{1}, niveauModwpt);
        assert(size(bandes, 1) == 2 ^ niveauModwpt);
        assert(max(abs(imodwpt(bandes, nomModwpt{1}) - signalModwpt)) < 1e-9);
    end
end
[bandes, energiesBandes] = modwpt(signalModwpt, 'sym4', 3);
assert(abs(sum(energiesBandes) - 1) < 1e-12);
assert(abs(sum(sum(bandes .^ 2)) - sum(signalModwpt .^ 2)) < 1e-6);
tempsModwpt = (0:1023) / 1024;
for frequenceEssai = [40 150 300 450]
    [~, energiesEssai] = modwpt(sin(2 * pi * frequenceEssai * tempsModwpt), 'sym4', 3);
    [~, bandeTrouvee] = max(energiesEssai);
    assert(bandeTrouvee == floor(frequenceEssai / 1024 * 16) + 1, ...
           sprintf('f=%d', frequenceEssai));
end

% Ruptures de variance : la programmation dynamique les trouve
% exactement, et n'en invente pas sur du bruit homogene.
serieRompue = [randn(1, 200), 4 * randn(1, 200), randn(1, 200)];
[ruptures, nombreRuptures] = wvarchg(serieRompue, 4);
assert(nombreRuptures == 2);
assert(abs(ruptures(1) - 200) < 25 && abs(ruptures(2) - 400) < 25);
[rupturesVides, aucune] = wvarchg(randn(1, 600), 4);
assert(aucune == 0 && isempty(rupturesVides));
[uneRupture, compte] = wvarchg([randn(1, 150), 5 * randn(1, 150)], 3);
assert(compte == 1 && abs(uneRupture - 150) < 25);


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

% Triangles et trapèzes : les côtés de largeur nulle valent un.
assert(isequal(trimf(0:10, [0 5 10]), [0 .2 .4 .6 .8 1 .8 .6 .4 .2 0]));
assert(isequal(trimf(0:5, [0 0 5]), [1 .8 .6 .4 .2 0]));
assert(isequal(trimf(5:10, [5 10 10]), [0 .2 .4 .6 .8 1]));
assert(isequal(trapmf(0:6, [1 2 4 5]), [0 0 1 1 1 0 0]));
assert(isequal(trapmf(0:5, [0 0 2 4]), [1 1 1 0.5 0 0]));
assert(isequal(evalmf(0:4, 'trimf', [0 2 4]), [0 0.5 1 0.5 0]));
assert(max(abs(evalmf([0 5 10], 'zmf', [2 8]) - [1 0.5 0])) < 1e-12);
assert(abs(probor(0.5, 0.5) - 0.75) < 1e-12);
assert(abs(probor([0.5 0.5]) - 0.75) < 1e-12);

% Inférence de Mamdani : un système symétrique donne une sortie symétrique,
% et le centre de gravité d'un triangle coupé se retrouve.
fisMamdani = newfis('symetrique');
fisMamdani = addvar(fisMamdani, 'input', 'x', [0 10]);
fisMamdani = addmf(fisMamdani, 'input', 1, 'bas', 'trimf', [0 0 5]);
fisMamdani = addmf(fisMamdani, 'input', 1, 'haut', 'trimf', [5 10 10]);
fisMamdani = addvar(fisMamdani, 'output', 'y', [0 1]);
fisMamdani = addmf(fisMamdani, 'output', 1, 'petit', 'trimf', [0 0 0.5]);
fisMamdani = addmf(fisMamdani, 'output', 1, 'grand', 'trimf', [0.5 1 1]);
fisMamdani = addrule(fisMamdani, [1 1 1 1; 2 2 1 1]);
assert(abs(evalfis(5, fisMamdani) - 0.5) < 1e-12);
assert(abs(evalfis(2, fisMamdani) + evalfis(8, fisMamdani) - 1) < 1e-12);
% Un jeu d'entrées par ligne.
assert(isequal(size(evalfis([0; 5; 10], fisMamdani)), [3 1]));
% Les forces d'activation sont les degrés d'appartenance.
[~, forcesMamdani] = evalfis(2, fisMamdani);
assert(max(abs(forcesMamdani' - [0.6 0])) < 1e-12);

% Inférence de Sugeno : constante puis affine, cette dernière exacte.
fisSugeno = newfis('sugeno1', 'sugeno');
assert(strcmp(fisSugeno.defuzzification, 'wtaver'));
fisSugeno = addvar(fisSugeno, 'input', 'x', [0 10]);
fisSugeno = addmf(fisSugeno, 'input', 1, 'bas', 'trimf', [0 0 10]);
fisSugeno = addmf(fisSugeno, 'input', 1, 'haut', 'trimf', [0 10 10]);
fisSugeno = addvar(fisSugeno, 'output', 'y', [0 1]);
fisSugeno = addmf(fisSugeno, 'output', 1, 'zero', 'constant', 0);
fisSugeno = addmf(fisSugeno, 'output', 1, 'un', 'constant', 1);
fisSugeno = addrule(fisSugeno, [1 1 1 1; 2 2 1 1]);
assert(max(abs(evalfis([0; 5; 10], fisSugeno) - [0; 0.5; 1])) < 1e-12);
fisAffine = newfis('sugeno2', 'sugeno');
fisAffine = addvar(fisAffine, 'input', 'x', [0 10]);
fisAffine = addmf(fisAffine, 'input', 1, 'partout', 'trimf', [-10 5 20]);
fisAffine = addvar(fisAffine, 'output', 'y', [0 100]);
fisAffine = addmf(fisAffine, 'output', 1, 'affine', 'linear', [3 2]);
fisAffine = addrule(fisAffine, [1 1 1 1]);
assert(max(abs(evalfis([0; 5; 10], fisAffine) - [2; 17; 32])) < 1e-12);
% mamfis et sugfis nomment le type.
assert(strcmp(mamfis('Name', 'a').type, 'mamdani'));
assert(strcmp(sugfis('Name', 'b').type, 'sugeno'));

% Lecture, écriture et accès aux champs.
fisPourboire = newfis('pourboire');
fisPourboire = addvar(fisPourboire, 'input', 'service', [0 10]);
fisPourboire = addmf(fisPourboire, 'input', 1, 'mauvais', 'gaussmf', [1.5 0]);
fisPourboire = addmf(fisPourboire, 'input', 1, 'bon', 'gaussmf', [1.5 5]);
fisPourboire = addmf(fisPourboire, 'input', 1, 'excellent', 'gaussmf', [1.5 10]);
fisPourboire = addvar(fisPourboire, 'input', 'nourriture', [0 10]);
fisPourboire = addmf(fisPourboire, 'input', 2, 'passable', 'trapmf', [0 0 1 3]);
fisPourboire = addmf(fisPourboire, 'input', 2, 'delicieuse', 'trapmf', [7 9 10 10]);
fisPourboire = addvar(fisPourboire, 'output', 'pourboire', [0 30]);
fisPourboire = addmf(fisPourboire, 'output', 1, 'bas', 'trimf', [0 5 10]);
fisPourboire = addmf(fisPourboire, 'output', 1, 'moyen', 'trimf', [10 15 20]);
fisPourboire = addmf(fisPourboire, 'output', 1, 'haut', 'trimf', [20 25 30]);
fisPourboire = addrule(fisPourboire, [1 1 1 1 2; 2 0 2 1 1; 3 2 3 1 2]);
assert(getfis(fisPourboire, 'numinputs') == 2);
assert(getfis(fisPourboire, 'numrules') == 3);
assert(strcmp(getfis(fisPourboire, 'name'), 'pourboire'));
assert(getfis(fisPourboire, 'input', 1, 'nummfs') == 3);
assert(isequal(getfis(fisPourboire, 'input', 1, 'mf', 2, 'params'), [1.5 5]));
assert(strcmp(getfis(setfis(fisPourboire, 'defuzzmethod', 'bisector'), 'defuzzmethod'), 'bisector'));
assert(isequal(getfis(setfis(fisPourboire, 'input', 1, 'mf', 2, 'params', [2 5]), ...
                      'input', 1, 'mf', 2, 'params'), [2 5]));
% Aller-retour par fichier : la sortie doit être identique au bit près.
avantEcriture = evalfis([3 8], fisPourboire);
cheminFis = fullfile(tempdir, 'matlibre_essai_pourboire.fis');
writefis(fisPourboire, cheminFis);
fisRelu = readfis(cheminFis);
assert(strcmp(fisRelu.nom, 'pourboire'));
assert(numel(fisRelu.entrees) == 2 && numel(fisRelu.sorties) == 1);
assert(isequal(fisRelu.regles, fisPourboire.regles));
assert(abs(evalfis([3 8], fisRelu) - avantEcriture) < 1e-12);
delete(cheminFis);
% Retraits : les règles suivent.
fisSansMf = rmmf(fisPourboire, 'input', 2, 'mf', 1);
assert(numel(fisSansMf.entrees{2}.mf) == 1);
assert(size(fisSansMf.regles, 1) == 2);
assert(isequal(fisSansMf.regles(2, 1:2), [3 1]));
fisSansVar = rmvar(fisPourboire, 'input', 2);
assert(numel(fisSansVar.entrees) == 1);
assert(size(fisSansVar.regles, 2) == size(fisPourboire.regles, 2) - 1);


% ------------------------------------- ecriture moderne d'un systeme flou
% Les deux courbes lineaires : complementaires et bornees.
assert(isequal(linsmf([0 2 5 8 10], [2 8]), [0 0 0.5 1 1]));
assert(isequal(linzmf([0 2 5 8 10], [2 8]), [1 1 0.5 0 0]));
assert(max(abs(linsmf(0:10, [2 8]) + linzmf(0:10, [2 8]) - 1)) < 1e-15);
assert(isequal(evalmf(0:10, 'linsmf', [2 8]), linsmf(0:10, [2 8])));
assert(isequal(linsmf([1 3 5], [3 3]), [0 1 1]));

% ADDINPUT pose une partition reguliere dont les modalites somment a un.
fisModerne = addInput(mamfis('Name', 'moderne'), [0 10], ...
                      'Name', 'service', 'NumMFs', 3);
fisModerne = addOutput(fisModerne, [0 30], 'Name', 'pourboire', 'NumMFs', 3);
assert(numel(fisModerne.entrees{1}.mf) == 3);
assert(strcmp(fisModerne.entrees{1}.nom, 'service'));
grilleMf = 0:0.5:10;
sommeMf = zeros(size(grilleMf));
for kMf = 1:3
    modalite = fisModerne.entrees{1}.mf{kMf};
    sommeMf = sommeMf + evalmf(grilleMf, modalite.type, modalite.parametres);
end
assert(max(abs(sommeMf - 1)) < 1e-12);
for typeMf = {'trapmf', 'gaussmf', 'gbellmf'}
    assert(numel(addInput(mamfis, [0 1], 'NumMFs', 4, ...
                          'MFType', typeMf{1}).entrees{1}.mf) == 4);
end
assert(strcmp(addInput(mamfis, [0 1]).entrees{1}.nom, 'input1'));

% Les regles s'ecrivent en clair, en francais comme en anglais.
fisEcrit = addInput(mamfis('Name', 'ecrit'), [0 10], 'Name', 'service', 'NumMFs', 2);
fisEcrit = addOutput(fisEcrit, [0 30], 'Name', 'pourboire', 'NumMFs', 2);
fisEcrit = addRule(fisEcrit, {'si service est mf1 alors pourboire est mf1', ...
                              'si service est mf2 alors pourboire est mf2'});
assert(size(fisEcrit.regles, 1) == 2);
assert(isequal(fisEcrit.regles(1, 1:2), [1 1]));
assert(isequal(fisEcrit.regles(2, 1:2), [2 2]));
assert(evalfis(fisEcrit, 10) > evalfis(fisEcrit, 0));
fisAnglais = addInput(mamfis, [0 1], 'Name', 'a', 'NumMFs', 2);
fisAnglais = addInput(fisAnglais, [0 1], 'Name', 'b', 'NumMFs', 2);
fisAnglais = addOutput(fisAnglais, [0 1], 'Name', 'c', 'NumMFs', 2);
fisAnglais = addRule(fisAnglais, {'if a is mf1 or b is mf2 then c is mf1'});
assert(fisAnglais.regles(1, end) == 2);
% EVALFIS accepte les deux ordres d'arguments.
assert(abs(evalfis(fisMamdani, 5) - evalfis(5, fisMamdani)) < 1e-15);

% ADDMF par nom, et l'ancienne forme a genre et rang.
fisNomme = addMF(addInput(mamfis, [0 10], 'Name', 'service'), ...
                 'service', 'trimf', [0 0 5], 'Name', 'faible');
assert(strcmp(fisNomme.entrees{1}.mf{1}.nom, 'faible'));
fisAncien = addMF(addvar(newfis('x'), 'input', 'a', [0 1]), ...
                  'input', 1, 'basse', 'trimf', [0 0 0.5]);
assert(strcmp(fisAncien.entrees{1}.mf{1}.nom, 'basse'));

% Les retraits tiennent les regles a jour.
fisRetrait = addInput(mamfis('Name', 'r'), [0 1], 'Name', 'a', 'NumMFs', 2);
fisRetrait = addInput(fisRetrait, [0 1], 'Name', 'b', 'NumMFs', 2);
fisRetrait = addOutput(fisRetrait, [0 1], 'Name', 'c', 'NumMFs', 2);
fisRetrait = addRule(fisRetrait, [1 1 1 1 1; 2 2 2 1 1]);
sansPremiere = removeInput(fisRetrait, 'a');
assert(numel(sansPremiere.entrees) == 1 && strcmp(sansPremiere.entrees{1}.nom, 'b'));
assert(size(sansPremiere.regles, 2) == size(fisRetrait.regles, 2) - 1);
assert(numel(removeOutput(fisRetrait, 'c').sorties) == 0);
% Retirer une modalite renumerote celles qui la suivaient.
fisTrois = addInput(mamfis, [0 1], 'Name', 'a', 'NumMFs', 3);
fisTrois = addOutput(fisTrois, [0 1], 'Name', 'b', 'NumMFs', 2);
fisTrois = addRule(fisTrois, [1 1 1 1; 3 2 1 1]);
fisDeux = removeMF(fisTrois, 'a', 'mf2');
assert(numel(fisDeux.entrees{1}.mf) == 2);
assert(fisDeux.regles(2, 1) == 2);
assert(size(removeRule(fisTrois, 1).regles, 1) == 1);
refuseRegle = false;
try
    removeRule(fisTrois, 5);
catch
    refuseRegle = true;
end
assert(refuseRegle);

% Les structures d'options : chaque champ se pose, et une faute de frappe
% est refusee plutot qu'ignoree.
assert(gensurfOptions('NumGridPoints', 31).NumGridPoints == 31);
assert(evalfisOptions('NumSamplePoints', 501).NumSamplePoints == 501);
optionsFcm = genfisOptions('FCMClustering', 'NumClusters', 4);
assert(strcmp(optionsFcm.Methode, 'fcm') && optionsFcm.NumClusters == 4);
assert(genfisOptions('GridPartition').NumMembershipFunctions == 2);
assert(genfisOptions('SubtractiveClustering').ClusterInfluenceRange == 0.5);
assert(anfisOptions('EpochNumber', 40).EpochNumber == 40);
assert(subclustOptions('ClusterInfluenceRange', 0.3).ClusterInfluenceRange == 0.3);
assert(fcmOptions('Exponent', 1.5).Exponent == 1.5);
assert(strcmp(tunefisOptions('Method', 'anfis').Method, 'anfis'));
refuseOption = false;
try
    gensurfOptions('Toto', 1);
catch
    refuseOption = true;
end
assert(refuseOption);

% La surface de reponse se calcule sur les champs du systeme.
fisSurface = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
fisSurface = addInput(fisSurface, [0 10], 'Name', 'b', 'NumMFs', 2);
fisSurface = addOutput(fisSurface, [0 1], 'Name', 'c', 'NumMFs', 2);
fisSurface = addRule(fisSurface, [1 1 1 1 1; 2 2 2 1 1]);
[grilleA, grilleB, surface] = gensurf(fisSurface);
assert(isequal(size(surface), [15 15]));
assert(isequal(size(grilleA), size(grilleB)));
assert(surface(end, end) > surface(1, 1));
[~, ~, surfaceFine] = gensurf(fisSurface, gensurfOptions('NumGridPoints', 9));
assert(isequal(size(surfaceFine), [9 9]));

% Parametres reglables : aller-retour sans perte, bornes respectees.
[reglagesEntree, reglagesSortie, reglagesRegles] = getTunableSettings(fisEcrit);
assert(numel(reglagesEntree) == 2 && numel(reglagesSortie) == 2);
assert(numel(reglagesRegles) == 2);
valeursDepart = getTunableValues(fisEcrit, reglagesEntree);
assert(numel(valeursDepart) == 6);
fisRepose = setTunableValues(fisEcrit, reglagesEntree, valeursDepart);
assert(max(abs(getTunableValues(fisRepose, reglagesEntree) - valeursDepart)) < 1e-15);
assert(abs(evalfis(fisRepose, 5) - evalfis(fisEcrit, 5)) < 1e-12);
fisForce = setTunableValues(fisEcrit, reglagesEntree, [100 -100 0, 0 0 0]);
parametresForces = fisForce.entrees{1}.mf{1}.parametres;
assert(issorted(parametresForces));
assert(all(parametresForces >= reglagesEntree(1).Minimum - 1e-12));
assert(all(parametresForces <= reglagesEntree(1).Maximum + 1e-12));

% TUNEFIS ne degrade jamais le systeme de depart.
abscissesReglage = (0:0.25:10)';
[fisRegle, infoReglage] = tunefis(genfis1([abscissesReglage, sin(abscissesReglage)], 4), ...
                                  [], abscissesReglage, sin(abscissesReglage));
assert(infoReglage.ErreurFinale <= infoReglage.ErreurInitiale);
assert(infoReglage.Evaluations > 0);

% La traduction en Sugeno remplace chaque modalite par son centre.
fisSugeneTraduit = convertToSugeno(fisEcrit);
assert(strcmp(fisSugeneTraduit.type, 'sugeno'));
assert(strcmp(fisSugeneTraduit.sorties{1}.mf{1}.type, 'constant'));
assert(evalfis(fisSugeneTraduit, 10) > evalfis(fisSugeneTraduit, 0));
assert(strcmp(convertToSugeno(fisSugeneTraduit).type, 'sugeno'));

% La forme brute pour la generation de code : rien que des nombres.
donneesCode = getFISCodeGenerationData(fisEcrit);
assert(donneesCode.nEntrees == 1 && donneesCode.nSorties == 1);
assert(isequal(size(donneesCode.parametresEntrees), [2 3]));
assert(numel(donneesCode.operateurs) == 5);
assert(isequal(donneesCode.regles, fisEcrit.regles));

% Classification floue : deux groupes bien séparés se retrouvent.
rng(11);
nuage = [randn(60, 2) * 0.4; randn(60, 2) * 0.4 + 6];
% FINDCLUSTER mene aux memes classes, par l'une ou l'autre methode.
[centresTrouves, appartenancesTrouvees] = findcluster(nuage, 2);
assert(size(centresTrouves, 1) == 2);
assert(max(abs(sum(appartenancesTrouvees, 1) - 1)) < 1e-9);
assert(size(findcluster(nuage, 0.4, 'subtractive'), 1) == 2);
refuseMethode = false;
try
    findcluster(nuage, 2, 'inconnue');
catch
    refuseMethode = true;
end
assert(refuseMethode);
[centresFcm, appartenances, critere] = fcm(nuage, 2);
centresFcm = sortrows(centresFcm);
assert(max(max(abs(centresFcm - [0 0; 6 6]))) < 0.4);
assert(max(abs(sum(appartenances, 1) - 1)) < 1e-12);
assert(all(diff(critere) <= 1e-9));
[~, classes] = max(appartenances, [], 1);
assert(numel(unique(classes(1:60))) == 1 && numel(unique(classes(61:end))) == 1);
assert(classes(1) ~= classes(61));
% Classification soustractive : le nombre de classes sort du calcul.
assert(size(subclust(nuage, 0.4), 1) == 2);
troisGroupes = [randn(40, 2) * 0.3; randn(40, 2) * 0.3 + 5; randn(40, 2) * 0.3 + [10 0]];
assert(size(subclust(troisGroupes, 0.35), 1) == 3);

% Construction et apprentissage d'un système de Sugeno.
abscisses = (0:0.05:10)';
donneesSinus = [abscisses, sin(abscisses)];
fisGrille = genfis1(donneesSinus, 7);
assert(size(fisGrille.regles, 1) == 7);
assert(strcmp(fisGrille.sorties{1}.mf{1}.type, 'linear'));
erreurAvant = sqrt(mean((evalfis(abscisses, fisGrille) - sin(abscisses)) .^ 2));
[fisAppris, erreursAnfis] = anfis(donneesSinus, fisGrille, 15);
assert(all(diff(erreursAnfis) <= 1e-12));
assert(erreursAnfis(end) < erreurAvant / 100);
% Les moindres carrés seuls reproduisent exactement une fonction affine.
donneesAffines = [abscisses, 3 * abscisses + 2];
fisLineaire = anfis(donneesAffines, genfis1(donneesAffines, 3), 1);
assert(sqrt(mean((evalfis(abscisses, fisLineaire) - (3 * abscisses + 2)) .^ 2)) < 1e-8);
% genfis1 sur deux entrées : une règle par combinaison.
assert(size(genfis1([rand(50, 2), rand(50, 1)], 3).regles, 1) == 9);
assert(size(genfis2(abscisses, sin(abscisses), 0.25).regles, 1) >= 2);
assert(size(genfis3(abscisses, sin(abscisses), 'sugeno', 6).regles, 1) == 6);
assert(size(genfis(abscisses, sin(abscisses), struct('Methode', 'fcm', 'NumClusters', 6)).regles, 1) == 6);

% Arithmétique floue : les sommets se composent comme les nombres nets.
grilleFloue = linspace(-10, 30, 401);
nombreA = trimf(grilleFloue, [1 2 3]);
nombreB = trimf(grilleFloue, [4 6 8]);
sommeFloue = fuzarith(grilleFloue, nombreA, nombreB, 'sum');
assert(abs(grilleFloue(find(sommeFloue == max(sommeFloue), 1)) - 8) < 0.11);
differenceFloue = fuzarith(grilleFloue, nombreA, nombreB, 'sub');
assert(abs(grilleFloue(find(differenceFloue == max(differenceFloue), 1)) + 4) < 0.11);
produitFlou = fuzarith(grilleFloue, nombreA, nombreB, 'prod');
assert(abs(grilleFloue(find(produitFlou == max(produitFlou), 1)) - 12) < 0.11);
% Le support de la somme est la somme des supports.
assert(min(grilleFloue(sommeFloue > 0)) >= 5 - 0.3 && max(grilleFloue(sommeFloue > 0)) <= 11 + 0.3);

% Tracés rendus sous forme de données.
[courbesMf, grilleMf] = plotmf(fisGrille, 'input', 1);
assert(isequal(size(courbesMf), [181 7]));
assert(abs(grilleMf(1)) < 1e-12 && abs(grilleMf(end) - 10) < 1e-12);
assert(~isempty(plotfis(fisGrille)));


% Ordre des symboles : PSKMOD et QAMMOD acceptent 'bin' et 'gray'.
% Le codage de Gray est defini par une propriete : deux points voisins de
% la constellation ne different que d'un bit.
pointsGray = pskmod((0:3)', 4, pi / 4, 'gray');
pointsBinaire = pskmod((0:3)', 4, pi / 4, 'bin');
assert(max(abs(abs(pointsGray) - 1)) < 1e-12, 'la MDP est sur le cercle unite');
assert(isequal(pskdemod(pointsGray, 4, pi / 4, 'gray'), (0:3)'));
assert(isequal(pskdemod(pointsBinaire, 4, pi / 4, 'bin'), (0:3)'));
% Les deux constellations occupent les memes points, dans un autre ordre.
assert(max(abs(sort(mod(angle(pointsGray), 2 * pi)) - ...
                sort(mod(angle(pointsBinaire), 2 * pi)))) < 1e-12);
ecartsGray = matlibre_essai_voisins(pointsGray);
ecartsBinaire = matlibre_essai_voisins(pointsBinaire);
assert(all(ecartsGray == 1), 'deux voisins de Gray ne different que d''un bit');
assert(any(ecartsBinaire > 1), 'le codage binaire en change parfois deux');
% Meme chose pour la MAQ, ou Gray s'applique axe par axe.
assert(isequal(qamdemod(qammod(0:15, 16), 16), 0:15));
assert(isequal(qamdemod(qammod(0:15, 16, 'bin'), 16, 'bin'), 0:15));
% Les deux ordres placent les memes points.
assert(max(abs(sort(real(qammod(0:15, 16))) - sort(real(qammod(0:15, 16, 'bin'))))) < 1e-12);

% ENCODE et DECODE gardent la forme de leur entree, comme dans MATLAB.
motsHamming = [1 0 1 1; 0 1 1 0; 1 1 1 1];
codesHamming = encode(motsHamming, 7, 4, 'hamming/binary');
assert(isequal(size(codesHamming), [3 7]));
assert(isequal(decode(codesHamming, 7, 4, 'hamming/binary'), motsHamming));
% Un vecteur reste un vecteur, dans son orientation.
assert(isrow(encode([1 0 1 1], 7, 4, 'hamming/binary')));
assert(iscolumn(encode([1; 0; 1; 1], 7, 4, 'hamming/binary')));
assert(isequal(decode(encode([1 0 1 1], 7, 4, 'hamming/binary'), 7, 4, ...
                      'hamming/binary'), [1 0 1 1]));
% Une erreur par bloc est corrigee ; deux ne le sont pas, la distance
% minimale du code valant trois.
uneErreur = codesHamming;
uneErreur(2, 5) = 1 - uneErreur(2, 5);
assert(isequal(decode(uneErreur, 7, 4, 'hamming/binary'), motsHamming));
deuxErreurs = codesHamming;
deuxErreurs(2, [3 5]) = 1 - deuxErreurs(2, [3 5]);
assert(~isequal(decode(deuxErreurs, 7, 4, 'hamming/binary'), motsHamming));
disp('modulation et codage : ok');

disp('domaines : toutes les verifications passent');

function ecarts = matlibre_essai_voisins(points)
%MATLIBRE_ESSAI_VOISINS Bits differents entre points consecutifs du cercle.
    [~, ordre] = sort(mod(angle(points), 2 * pi));
    valeurs = ordre - 1;
    n = numel(valeurs);
    ecarts = zeros(1, n);
    for k = 1:n
        suivant = mod(k, n) + 1;
        ecarts(k) = sum(de2bi(valeurs(k), 2) ~= de2bi(valeurs(suivant), 2));
    end
end
