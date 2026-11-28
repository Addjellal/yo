% Vérifications de la boîte à outils Ondelettes.
% Chaque fonction est éprouvée sur la propriété qui la définit, jamais sur
% une table de coefficients recopiée.
disp('--- ondelettes ---');

% ---------------------------------------------------------------- coiflettes
% Une coiflette annule les 2N premiers moments de l'ondelette, comme une
% dbN, mais aussi les 2N-1 premiers moments de la fonction d'échelle.
for N = 1:5
    F = coifwavf(sprintf('coif%d', N));
    L = numel(F);
    assert(L == 6 * N);
    assert(abs(sum(F) - 1) < 1e-12);
    h = F * sqrt(2);
    % Orthonormalité du filtre.
    for k = 0:(3 * N - 1)
        d = 2 * k;
        assert(abs(sum(h(1:(L - d)) .* h((1 + d):L)) - (k == 0)) < 1e-9);
    end
    % Moments, comptés autour du centre 2N (de 0 à 6N-1) : dans l'ordre de
    % MATLAB, le plus gros coefficient y tombe, et coifwavf('coif1')
    % commence par -0.0515.
    j = ((0:(L - 1)) - 2 * N) / (2 * N);
    signes = (-1) .^ (0:(L - 1));
    for k = 0:(2 * N - 1)
        assert(abs(sum(signes .* j .^ k .* h)) < 1e-9);
    end
    for k = 1:(2 * N - 1)
        assert(abs(sum(j .^ k .* h)) < 1e-9);
    end
end
fprintf('coif1 : %s\n', mat2str(round(coifwavf('coif1') * sqrt(2), 4)));
% Le banc de filtres complet, et la reconstruction parfaite.
[lod, hid, lor, hir] = wfilters('coif3');
assert(numel(lod) == 18);
assert(abs(sum(lod .^ 2) - 1) < 1e-12);
assert(abs(sum(lod .* hid)) < 1e-12);
rng(4);
x = randn(1, 512);
[a, d] = dwt(x, 'coif3');
assert(max(abs(idwt(a, d, 'coif3') - x)) < 1e-12);
assert(any(strcmp(wavenames('orthogonal'), 'coif5')));
% Ce que les moments de la fonction d'échelle achètent : l'approximation
% d'un polynôme est l'échantillonnage de ce polynôme, à sqrt(2) près.
n = 0:511;
p = 1 + 0.01 * n + 1e-4 * n .^ 2 + 1e-6 * n .^ 3;
ecarts = zeros(1, 3);
noms = {'coif3', 'db9', 'sym9'};
for c = 1:3
    approximation = dwt(p, noms{c});
    ecarts(c) = ecartAuxEchantillons(approximation, p, 18);
end
fprintf('ecart a l''echantillonnage : coif3 %.1e, db9 %.1e, sym9 %.1e\n', ecarts);
assert(ecarts(1) < 1e-12);
assert(ecarts(2) > 1e-6);
assert(ecarts(3) > 1e-6);
disp('coiflettes : ok');

% ------------------------------------------------------- ondelette analytique
% Les trois familles culminent à deux, à la pulsation annoncée, et sont
% nulles aux pulsations négatives.
w = linspace(0, 20, 8001);
familles = {{'morse', [3 20]}, {'amor', 6}, {'bump', [5 0.6]}};
attendus = [(20 / 3) ^ (1 / 3), 6, 5];
for k = 1:3
    [psi, pic, sigmaT, sigmaW] = ondeletteAnalytique(familles{k}{1}, familles{k}{2}, w);
    % Le sommet vaut deux, et il est bien à la pulsation annoncée : la
    % grille ne la contient pas toujours, on évalue donc au point exact.
    assert(max(psi) <= 2 + 1e-12);
    assert(abs(ondeletteAnalytique(familles{k}{1}, familles{k}{2}, pic) - 2) < 1e-12);
    [~, indice] = max(psi);
    assert(abs(w(indice) - pic) < 0.01);
    assert(abs(pic - attendus(k)) < 1e-9);
    assert(all(ondeletteAnalytique(familles{k}{1}, familles{k}{2}, [-5 -1 0]) == 0));
    assert(sigmaT > 0 && sigmaW > 0);
end
% La Morlet analytique est une gaussienne : elle sature l'inégalité de
% Heisenberg, sigmaT * sigmaW = 1/2 exactement.
[~, ~, st, sw] = ondeletteAnalytique('amor', 6, 1);
fprintf('Morlet analytique : sigmaT * sigmaW = %.6f (borne 0.5)\n', st * sw);
assert(abs(st * sw - 0.5) < 1e-4);
disp('ondelettes analytiques : ok');

% ------------------------------------------------------------- bornes et banc
[fmin, fmax] = cwtfreqbounds(1024, 'Wavelet', 'amor');
% La borne haute vient de Nyquist, la basse de la longueur du signal :
% seule la seconde bouge quand le signal s'allonge.
[fmin4, fmax4] = cwtfreqbounds(4096, 'Wavelet', 'amor');
assert(abs(fmax - fmax4) < 1e-12);
assert(abs(fmin / fmin4 - 4) < 1e-9);
assert(fmax < 0.5);
[fmh, fMh] = cwtfreqbounds(1024, 1000, 'Wavelet', 'amor');
assert(abs(fmh - 1000 * fmin) < 1e-9 && abs(fMh - 1000 * fmax) < 1e-9);
fprintf('bornes amor N=1024 : [%.6f %.6f] cycles par echantillon\n', fmin, fmax);

fb = cwtfilterbank('SignalLength', 1024, 'SamplingFrequency', 1000);
t = (0:1023) / 1000;
[cfs, f, coi] = wt(fb, cos(2 * pi * 100 * t));
assert(isequal(size(cfs), [numel(f), 1024]));
assert(numel(coi) == 1024);
[~, k] = max(mean(abs(cfs(:, 200:800)), 2));
fprintf('banc continu : pic a %.2f Hz (attendu 100)\n', f(k));
% Une voix par octave couvre 2^(1/10) : l'écart ne peut pas dépasser cela.
assert(abs(log2(f(k) / 100)) < 1 / 10);
assert(all(diff(f) < 0));
assert(isequal(size(freqz(fb)), [numel(f), 1024]));
% Le facteur de qualité de la Morlet analytique se lit sur la définition.
fbAmor = cwtfilterbank('Wavelet', 'amor', 'SignalLength', 512);
assert(abs(qfactor(fbAmor) - 6 / (2 * 0.70710678)) < 1e-3);
assert(max(abs(centerPeriods(fbAmor) .* centerFrequencies(fbAmor) - 1)) < 1e-12);
disp('banc continu : ok');

% -------------------------------------------------------------- banc discret
% Pour une ondelette orthogonale les filtres équivalents partagent
% exactement l'énergie : les deux bornes du repère valent un.
for nom = {'db4', 'sym6', 'coif3', 'haar'}
    banc = dwtfilterbank('Wavelet', nom{1}, 'SignalLength', 1024);
    [basse, haute] = framebounds(banc);
    assert(abs(basse - 1) < 1e-9);
    assert(abs(haute - 1) < 1e-9);
end
% Une biorthogonale n'est pas un repère serré : les bornes s'écartent.
[basse, haute] = framebounds(dwtfilterbank('Wavelet', 'bior3.5', 'SignalLength', 512));
fprintf('bornes du repere : db4 [1 1], bior3.5 [%.3f %.3f]\n', basse, haute);
assert(haute - basse > 1);
banc = dwtfilterbank('Wavelet', 'db4', 'SignalLength', 1024, 'SamplingFrequency', 1000);
centres = centerfrequencies(banc);
% Chaque niveau descend d'une octave. Le premier fait exception : sa
% bande est coupée par Nyquist, ce qui tire son barycentre vers le bas.
rapports = centres(1:end-1) ./ centres(2:end);
fprintf('rapports d''octave : %s\n', mat2str(round(rapports', 3)));
assert(abs(rapports(1) - 2) < 0.15);
assert(max(abs(rapports(2:end) - 2)) < 0.05);
assert(max(abs(centerperiods(banc) .* centres - 1)) < 1e-12);
% Le facteur de qualité ne dépend pas du niveau : c'est ce qui distingue
% une analyse en ondelettes d'une analyse à fenêtre fixe.
q = qfactor(banc);
assert(std(q) / mean(q) < 0.1);
[ondes, temps] = wavelets(banc);
assert(isequal(size(ondes), [banc.Level, 1024]));
assert(numel(temps) == 1024);
assert(isequal(size(scalingfunctions(banc)), [banc.Level, 1024]));
assert(all(powerbw(banc) > 0));
disp('banc discret : ok');

% ------------------------------------------------------------------ arbre double
% Le second arbre est le premier renversé, ce qui décale les deux d'un
% demi-échantillon exactement.
df = dtfilters('qshift2');
assert(isequal(size(df{1}), [14 4]));
assert(max(abs(df{2}(:, 1) - flipud(df{1}(:, 1)))) < 1e-14);
h = df{1}(:, 1)';
L = numel(h);
for k = 0:(L / 2 - 1)
    d = 2 * k;
    assert(abs(sum(h(1:(L - d)) .* h((1 + d):L)) - (k == 0)) < 1e-10);
end
pulsations = linspace(0.05, pi / 2, 200);
H = arrayfun(@(x) sum(h .* exp(-1i * (0:L-1) * x)), pulsations);
G = arrayfun(@(x) sum(fliplr(h) .* exp(-1i * (0:L-1) * x)), pulsations);
retard = unwrap(angle(G ./ H)) ./ pulsations;
fprintf('arbre double : retard relatif median %.4f (attendu -0.5)\n', median(retard));
assert(max(abs(retard + 0.5)) < 0.05);
% Au premier étage le décalage doit valoir un échantillon entier.
premier = dtfilters('fsfarras');
assert(max(abs(premier{1}(1:end-1, 1) - premier{2}(2:end, 1))) < 1e-14);
% Reconstruction exacte, quelle que soit la longueur des filtres.
rng(7);
x = randn(256, 1);
for longueur = [10 14 16 18]
    for niveaux = 1:4
        [ap, det] = dualtree(x, 'Level', niveaux, 'FilterLength', longueur);
        assert(numel(det) == niveaux);
        assert(size(ap, 2) == 2);
        assert(~isreal(det{1}));
        y = idualtree(ap, det, 'FilterLength', longueur);
        assert(max(abs(y - x)) < 1e-11);
    end
end
% Ce que l'arbre double achète : l'énergie par niveau ne bouge presque
% plus quand le signal glisse d'un échantillon.
temps = (0:511)';
motif = exp(-((temps - 200) / 12) .^ 2) .* cos(2 * pi * temps / 9);
eDouble = zeros(1, 8);
eSimple = zeros(1, 8);
for decalage = 0:7
    glisse = circshift(motif, decalage);
    [~, det] = dualtree(glisse, 'Level', 3, 'FilterLength', 14);
    eDouble(decalage + 1) = sum(abs(det{2}(:)) .^ 2);
    [coefficients, longueurs] = wavedec(glisse, 3, 'sym4');
    eSimple(decalage + 1) = sum(detcoef(coefficients, longueurs, 2) .^ 2);
end
variationDouble = std(eDouble) / mean(eDouble);
variationSimple = std(eSimple) / mean(eSimple);
fprintf('energie du niveau 2 sur 8 decalages : arbre double %.4f, dwt %.4f\n', ...
        variationDouble, variationSimple);
assert(variationDouble < 0.01);
assert(variationSimple > 0.2);
disp('arbre double : ok');

% -------------------------------------------------------------- synchronisation
tSst = (0:2047)' / 1000;
signal = cos(2 * pi * 50 * tSst) + cos(2 * pi * 180 * tSst);
[s, fs] = wsst(signal, 1000);
assert(size(s, 2) == 2048);
assert(numel(fs) == size(s, 1));
energies = mean(abs(s(:, 300:1700)), 2);
[~, ordre] = sort(energies, 'descend');
raies = sort(fs(ordre(1:2)));
fprintf('wsst : raies a %.2f et %.2f Hz (attendu 50 et 180)\n', raies(1), raies(2));
assert(abs(raies(1) - 50) < 2);
assert(abs(raies(2) - 180) < 5);
% La synchronisation resserre ce que la transformée continue étale.
bancSst = cwtfilterbank('Wavelet', 'amor', 'SignalLength', 2048, ...
                        'SamplingFrequency', 1000, 'VoicesPerOctave', 32);
continue_ = wt(bancSst, signal);
etalement = @(m) sum(abs(m(:))) ^ 2 / sum(abs(m(:)) .^ 2);
fprintf('etalement : continue %.0f, synchronisee %.0f\n', ...
        etalement(continue_), etalement(s));
assert(etalement(s) < etalement(continue_) / 5);
disp('synchronisation : ok');

% ------------------------------------------------------------------- coherence
tCoh = (0:1023)' / 200;
xCoh = cos(2 * pi * 10 * tCoh);
rng(11);
yCoh = cos(2 * pi * 10 * tCoh + pi / 4) + 0.2 * randn(size(tCoh));
[wcoh, wcs, fCoh, coiCoh] = wcoherence(xCoh, yCoh, 200);
assert(isequal(size(wcoh), size(wcs)));
assert(numel(fCoh) == size(wcoh, 1));
assert(numel(coiCoh) == 1024);
assert(all(wcoh(:) >= 0) && all(wcoh(:) <= 1));
[~, kCoh] = min(abs(fCoh - 10));
coherence = mean(wcoh(kCoh, 200:800));
phase = mean(angle(wcs(kCoh, 200:800))) * 180 / pi;
fprintf('coherence a 10 Hz : %.4f, phase %.1f degres (attendu -45)\n', coherence, phase);
assert(coherence > 0.95);
assert(abs(phase + 45) < 5);
% Un signal est parfaitement cohérent avec lui-même.
propre = wcoherence(xCoh, xCoh, 200);
assert(mean(propre(:)) > 0.99);
disp('coherence : ok');

% ------------------------------------------------------------------ gestionnaire
assert(wavemngr('type', 'db4') == 1);
assert(wavemngr('type', 'bior2.2') == 2);
assert(wavemngr('type', 'cmor') == 5);
champs = wavemngr('fields', 'coif3');
assert(strcmp(champs.nom, 'Coiflets'));
assert(strcmp(champs.abrege, 'coif'));
[nomComplet, abrege, genre] = wavemngr('fields', 'sym8');
assert(strcmp(nomComplet, 'Symlets') && strcmp(abrege, 'sym') && genre == 1);
avant = numel(wavemngr('tfsn'));
wavemngr('add', 'MonOndelette', 'mond', 1, '1 2', 'dbwavf');
assert(numel(wavemngr('tfsn')) == avant + 1);
assert(wavemngr('type', 'mond1') == 1);
wavemngr('del', 'mond');
assert(numel(wavemngr('tfsn')) == avant);
refuse = false;
try
    wavemngr('del', 'db');
catch
    refuse = true;
end
assert(refuse);
wavemngr('restore');
assert(numel(wavemngr('tfsn')) == avant);
assert(~isempty(wavemngr('read')));
disp('gestionnaire : ok');

% ------------------------------------------------- modes de prolongement
% Les algorithmes de MATLAB, dans chacun de ses modes. Valeurs de
% pywt.dwt(1:7, 'db2', mode) — PyWavelets valide ses modes contre MATLAB.
assert(strcmp(dwtmode('status', 'nodisp'), 'sym'));
modesEssai = {'sym', 'per', 'zpd', 'asymw'};
attendusA = {[1.76776695296637 2.31078903454115 5.13921615928734 8.09705280658479 9.93417011367217], ...
             [4.27731586417979 3.72500259691424 6.55342972166043 10.1929891587747], ...
             [-0.0346751770605074 2.31078903454115 5.13921615928734 9.00291946444361 3.38074039201174], ...
             [-0.517638090205041 2.31078903454115 5.13921615928734 7.96764328403353 10.7960704087797]};
attendusD1 = [-0.612372435695794, -0.905866657858823, -0.12940952255126, 0];
for k = 1:numel(modesEssai)
    [aMode, dMode] = dwt(1:7, 'db2', 'mode', modesEssai{k});
    assert(max(abs(aMode - attendusA{k})) < 1e-13, modesEssai{k});
    assert(abs(dMode(1) - attendusD1(k)) < 1e-13, modesEssai{k});
    assert(max(abs(idwt(aMode, dMode, 'db2', 7, 'mode', modesEssai{k}) - (1:7))) < 1e-12);
end
% Le mode de la session vaut pour tous ; 'per' garde ceil(N/2) coefficients.
dwtmode('per', 'nodisp');
[aPer, ~] = dwt(1:7, 'db2');
dwtmode('sym', 'nodisp');
assert(numel(aPer) == 4);
% Une colonne donne des colonnes, comme dans MATLAB.
[cCol, lCol] = wavedec((1:20)', 2, 'db2');
assert(iscolumn(cCol) && iscolumn(lCol) && iscolumn(waverec(cCol, lCol, 'db2')));
% DETCOEF : plusieurs niveaux en cellules, ou une sortie par niveau.
[cDet, lDet] = wavedec(sin(1:40), 3, 'sym4');
blocs = detcoef(cDet, lDet, [1 3]);
[d1, d3] = detcoef(cDet, lDet, [1 3]);
assert(iscell(blocs) && isequal(blocs{1}, d1) && isequal(blocs{2}, d3));
% WRCOEF : l'approximation d'un niveau plus les détails rendent le signal.
xr = sin((1:50) / 4) + mod(1:50, 7) / 10;
[cR, lR] = wavedec(xr, 3, 'db4');
somme = wrcoef('a', cR, lR, 'db4', 2) + wrcoef('d', cR, lR, 'db4', 2) + ...
        wrcoef('d', cR, lR, 'db4', 1);
assert(max(abs(somme - xr)) < 1e-12);
% UPCOEF : convolution entière, sans coupe (pywt.upcoef('a', [1, 2], 'db2', level=2)).
attenduUp = [0.233253175473055 0.40400635094611 0.512259526419165 0.637259526419165 ...
             0.762259526419165 0.887259526419165 1.01225952641916 1.13725952641916 ...
             0.5625 0.175240473580836 -0.024519052838329 -0.274519052838329 ...
             -0.0580127018922193 0.0334936490538903];
assert(max(abs(upcoef('a', [1 2], 'db2', 2) - attenduUp)) < 1e-13);
% DYADUP au sens de MATLAB.
assert(isequal(dyadup(1:3), [0 1 0 2 0 3 0]) && isequal(dyadup(1:3, 0), [1 0 2 0 3]));
% Prolongements antisymétriques : au-delà d'une période et en point entier.
assert(isequal(wextend('1D', 'asym', [1 2 3], 5), [2 3 -3 -2 -1 1 2 3 -3 -2 -1 1 2]));
assert(isequal(wextend('1D', 'asymw', [1 2 3], 2), [-1 0 1 2 3 4 5]));
assert(isequal(size(wextend('addrow', 'per', ones(3, 5), 1)), [6 5]));
% DWT2 d'une image de tailles impaires, en 'per' et en 'sym'.
image75 = reshape(1:35, 7, 5);
[aPer2, hPer2] = dwt2(image75, 'db2', 'mode', 'per');
assert(isequal(size(aPer2), [4 3]) && abs(aPer2(1, 1) - 24.8301270189222) < 1e-12);
assert(abs(hPer2(2, 3)) < 1e-12);
[aSym2, ~, ~, dSym2] = dwt2(image75, 'db2');
assert(isequal(size(aSym2), [5 4]) && abs(aSym2(1, 1) - 6) < 1e-12 && abs(dSym2(4, 4)) < 1e-12);
assert(max(max(abs(idwt2(aSym2, zeros(5, 4), zeros(5, 4), dSym2, 'db2', [7 5]) - ...
                   idwt2(aSym2, [], [], dSym2, 'db2', [7 5])))) < 1e-12);
% Paquets : la reconstruction reprend la taille de chaque parent.
arbreImpair = wpdec(sin(1:37), 3, 'db3');
assert(max(abs(wprec(arbreImpair) - sin(1:37))) < 1e-12);
% Coiflettes dans l'ordre de MATLAB.
assert(abs(coifwavf('coif1') * [1; 0; 0; 0; 0; 0] + 0.051429728470769) < 1e-12);
disp('modes de prolongement : ok');

disp('ondelettes : toutes les verifications passent');

function ecart = ecartAuxEchantillons(approximation, signal, longueur)
%ECARTAUXECHANTILLONS Écart au meilleur alignement possible.
%   L'approximation est décalée du centre du filtre ; on cherche le
%   décalage qui la superpose le mieux aux échantillons pairs du signal.
    ecart = inf;
    plage = 40:200;
    for decalage = -longueur:longueur
        indices = 2 * plage + decalage;
        garde = indices >= 1 & indices <= numel(signal);
        if ~any(garde)
            continue
        end
        attendu = signal(indices(garde));
        obtenu = approximation(plage(garde)) / sqrt(2);
        ecart = min(ecart, max(abs(obtenu - attendu)) / max(abs(attendu)));
    end
end
