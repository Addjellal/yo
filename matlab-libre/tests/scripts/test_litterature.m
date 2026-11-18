% Cas de la littérature : un par boîte à outils.
%
% Chaque valeur attendue vient d'une source publiée — article d'origine,
% ouvrage de référence, données certifiées du NIST, exemple de la
% documentation de MathWorks — et a été recoupée par un calcul
% indépendant de MatLibre : SciPy, scikit-learn, statsmodels,
% PyWavelets, ou une formule exacte. Les tolérances sont celles que la
% source permet : quinze chiffres pour une formule fermée, ceux que le
% NIST certifie pour Longley, les décimales imprimées pour un exemple de
% livre.
%
% Simulink et Control System Toolbox ont leurs cas de la littérature dans
% test_simulink.m (section 110) et test_automatique.m.
disp('--- litterature ---');

%% ----------------------------------------------------------------- signal
% Butterworth (1930), « On the Theory of Filter Amplifiers » : la réponse
% est maximalement plate, et vaut 1/sqrt(2) — -3,0103 dB — à la coupure.
% Coefficients de butter(4, 0.2) recoupés avec scipy.signal.butter.
[b, a] = butter(4, 0.2);
bRef = [0.0048243433577162282 0.019297373430864913 0.028946060146297369 ...
        0.019297373430864913 0.0048243433577162282];
aRef = [1 -2.3695130071820381 2.3139884144158809 -1.0546654058785681 0.18737949236818502];
assert(max(abs(b - bRef)) < 1e-15 && max(abs(a - aRef)) < 1e-14);
h = freqz(b, a, [0 0.2 * pi]);
assert(abs(abs(h(1)) - 1) < 1e-12);                       % gain unité en continu
assert(abs(20 * log10(abs(h(2))) - 20 * log10(1 / sqrt(2))) < 1e-10);
% Maximalement plat : le module décroît sans ondulation.
[hb, wb] = freqz(b, a, 512);
assert(all(diff(abs(hb)) <= 1e-12));
fprintf('signal : butter(4,0.2) a -3.0103 dB a la coupure\n');

%% ----------------------------------------------------------------- images
% Otsu (1979), « A Threshold Selection Method from Gray-Level Histograms » :
% le seuil maximise la variance inter-classes. Image déterministe — un
% disque clair sur un fond sombre, aux niveaux qui se chevauchent —, seuil
% recoupé avec skimage.filters.threshold_otsu (94).
[ii, jj] = ndgrid(1:64, 1:64);
disque = (ii - 32.5) .^ 2 + (jj - 32.5) .^ 2 <= 18 ^ 2;
fond = 40 + mod(37 * ii + 11 * jj, 71);
objet = 95 + mod(13 * ii + 29 * jj, 81);
imageOtsu = uint8(fond);
imageOtsu(disque) = objet(disque);
niveau = graythresh(imageOtsu);
assert(round(niveau * 255) == 94);
% La définition même : la variance inter-classes est maximale au seuil.
p = accumarray(double(imageOtsu(:)) + 1, 1, [256 1]) / numel(imageOtsu);
omega = cumsum(p);
mu = cumsum(p .* (0:255)');
interClasses = (mu(end) * omega - mu) .^ 2 ./ max(omega .* (1 - omega), realmin);
[~, rangMax] = max(interClasses);
assert(rangMax - 1 == 94);
binaire = imbinarize(imageOtsu, niveau);
assert(nnz(binaire) == 1713);
fprintf('images : seuil d''Otsu 94/255, comme skimage\n');

%% ---------------------------------------------------------- statistiques
% Fisher (1936), « The use of multiple measurements in taxonomic
% problems » : les iris. load trouve fisheriris.mat sur le chemin.
load fisheriris
assert(isequal(size(meas), [150 4]) && numel(species) == 150);
assert(isequal(meas(38, :), [4.9 3.6 1.4 0.1]));   % valeurs du papier de Fisher
% ACP : parts de variance, recoupées avec sklearn.decomposition.PCA.
[~, ~, ~, ~, explained] = pca(meas);
assert(max(abs(explained' / 100 - [0.9246187232017341 0.05306648311706383 ...
                                   0.017102609807927525 0.00521218387327465])) < 1e-12);
% Analyse discriminante linéaire : trois fleurs mal classées sur cent
% cinquante (exemple de MathWorks : resubLoss = 0.0200 ; scikit-learn :
% exactitude 0.98, observations 71, 84 et 134).
Md = fitcdiscr(meas, species);
assert(abs(resubLoss(Md) - 0.02) < 1e-12);
assert(isequal(find(~strcmp(resubPredict(Md), species))', [71 84 134]));
classe = classify(meas, meas, species);
assert(isequal(find(~strcmp(classe, species))', [71 84 134]));
assert(abs(resubLoss(fitcdiscr(meas, species, 'DiscrimType', 'quadratic')) - 0.02) < 1e-12);

% Hald (1960), ciment de Portland : l'exemple de la documentation de PCA.
% Coefficients, T² de Hotelling et parts expliquées recoupés avec NumPy
% sous la convention de signe de MATLAB.
hald = [7 26 6 60; 1 29 15 52; 11 56 8 20; 11 31 8 47; 7 52 6 33; 11 55 9 22; ...
        3 71 17 6; 1 31 22 44; 2 54 18 22; 21 47 4 26; 1 40 23 34; 11 66 9 12; 10 68 8 12];
[coeffHald, ~, ~, t2Hald, explHald] = pca(hald);
assert(max(abs(coeffHald(:, 1)' - [-0.0678 -0.6785 0.0290 0.7309])) < 5e-5);
assert(abs(t2Hald(1) - 5.6803) < 5e-5);
assert(max(abs(explHald' - [86.5974 11.2882 2.0747 0.0397])) < 5e-5);
wcoeff = pca(hald, 'VariableWeights', 'variance');
assert(abs(wcoeff(4, 4) - 11.3273) < 5e-5);

% Longley (1967), données certifiées du NIST (Statistical Reference
% Datasets) : la régression de référence pour la précision numérique.
longley = [60323 83.0 234289 2356 1590 107608 1947; 61122 88.5 259426 2325 1456 108632 1948;
           60171 88.2 258054 3682 1616 109773 1949; 61187 89.5 284599 3351 1650 110929 1950;
           63221 96.2 328975 2099 3099 112075 1951; 63639 98.1 346999 1932 3594 113270 1952;
           64989 99.0 365385 1870 3547 115094 1953; 63761 100.0 363112 3578 3350 116219 1954;
           66019 101.2 397469 2904 3048 117388 1955; 67857 104.6 419180 2822 2857 118734 1956;
           68169 108.4 442769 2936 2798 120445 1957; 66513 110.8 444546 4681 2637 121950 1958;
           68655 112.6 482704 3813 2552 123366 1959; 69564 114.2 502601 3931 2514 125368 1960;
           69331 115.7 518173 4806 2572 127852 1961; 70551 116.9 554894 4007 2827 130081 1962];
certifies = [-3482258.63459582; 15.0618722713733; -0.358191792925910E-01; -2.02022980381683;
             -1.03322686717359; -0.511041056535807E-01; 1829.15146461355];
ecartsCertifies = [890420.383607373; 84.9149257747669; 0.334910077722432E-01; 0.488399681651699;
                   0.214274163161675; 0.226073200069370; 455.478499142212];
mdl = fitlm(longley(:, 2:7), longley(:, 1));
chiffres = @(v, ref) -log10(max(abs(v - ref) ./ abs(ref)));
% La QR pivotée de LAPACK (celle de MATLAB) en obtient onze ; MatLibre de même.
assert(chiffres(mdl.Coefficients.Estimate, certifies) > 10.5);
assert(chiffres(mdl.Coefficients.SE, ecartsCertifies) > 10.5);
assert(chiffres(mdl.RMSE, 304.854073561965) > 11);
assert(chiffres(mdl.Rsquared.Ordinary, 0.995479004577296) > 12);
[~, Flongley] = coefTest(mdl);
assert(chiffres(Flongley, 330.285339234588) > 10);
assert(chiffres(mdl.SSR, 184172401.944494) > 11 && chiffres(mdl.SSE, 836424.055505915) > 10);
assert(chiffres(regress(longley(:, 1), [ones(16, 1) longley(:, 2:7)]), certifies) > 10.5);
fprintf('statistiques : iris (ACP, LDA), Hald (ACP), Longley (NIST, %.1f chiffres)\n', ...
        chiffres(mdl.Coefficients.Estimate, certifies));

%% ---------------------------------------------------------- optimisation
% Rosenbrock (1960), « An Automatic Method for Finding the Greatest or
% Least Value of a Function » : la vallée en banane, depuis (-1.2, 1).
rosen = @(x) 100 * (x(2) - x(1) ^ 2) ^ 2 + (1 - x(1)) ^ 2;
xMin = fminunc(rosen, [-1.2 1], optimoptions('fminunc', 'Display', 'off'));
assert(norm(xMin - [1 1]) < 1e-5);
assert(norm(fminsearch(rosen, [-1.2 1]) - [1 1]) < 1e-4);
% Hillier et Lieberman, « Introduction to Operations Research », la
% verrerie Wyndor : max 3x1 + 5x2, x1 <= 4, 2x2 <= 12, 3x1 + 2x2 <= 18.
[xLp, fLp] = linprog([-3 -5], [1 0; 0 2; 3 2], [4; 12; 18], [], [], [0 0], []);
assert(norm(xLp(:)' - [2 6]) < 1e-8 && abs(-fLp - 36) < 1e-8);
fprintf('optimisation : Rosenbrock en (1,1), Wyndor x = (2,6), Z = 36\n');

%% --------------------------------------------------------------- finance
% Black et Scholes (1973) ; Hull, « Options, Futures, and Other
% Derivatives », exemple d'une option à six mois : S0 = 42, K = 40,
% r = 10 %, sigma = 20 % donnent c = 4.76 et p = 0.81. Valeurs exactes
% recoupées par la formule fermée (scipy.stats.norm).
[call, put] = blsprice(42, 40, 0.10, 0.5, 0.20);
assert(abs(call - 4.759422392871532) < 1e-12 && abs(put - 0.8085993729000922) < 1e-12);
assert(abs(round(call, 2) - 4.76) < 1e-12 && abs(round(put, 2) - 0.81) < 1e-12);
% Parité call-put : c - p = S0 - K exp(-rT).
assert(abs((call - put) - (42 - 40 * exp(-0.10 * 0.5))) < 1e-12);
fprintf('finance : Black-Scholes, exemple de Hull, c = %.2f, p = %.2f\n', call, put);

%% ----------------------------------------------------------- econometrie
% Dickey et Fuller (1979) : la statistique du test de racine unitaire,
% recoupée avec statsmodels.tsa.stattools.adfuller sur une série
% déterministe ; valeurs critiques à 5 % comparées aux surfaces de réponse
% de MacKinnon (2010) pour la taille d'échantillon effective (99).
serie = zeros(100, 1);
for m = 2:100
    serie(m) = 0.9 * serie(m - 1) + sin(0.7 * m) + 0.3 * cos(2.3 * m);
end
attendus = struct('AR', -3.682901114734154, 'ARD', -3.6664283691006996, ...
                  'TS', -3.7067019341991227);
mackinnon5 = struct('AR', -1.9440242848853808, 'ARD', -2.891208211860468, ...
                    'TS', -3.455806184392646);
for modele = {'AR', 'ARD', 'TS'}
    [hAdf, pAdf, statAdf, cAdf] = adftest(serie, 'model', modele{1}, 'lags', 0);
    assert(abs(statAdf - attendus.(modele{1})) < 1e-12, modele{1});
    assert(abs(cAdf - mackinnon5.(modele{1})) < 0.01, modele{1});
    assert(hAdf && pAdf < 0.05, modele{1});
end
fprintf('econometrie : Dickey-Fuller, statistiques de statsmodels, seuils de MacKinnon\n');

%% -------------------------------------------------------- communications
% Proakis, « Digital Communications » : en BPSK sur bruit blanc gaussien,
% Pb = Q(sqrt(2 Eb/N0)) = erfc(sqrt(Eb/N0))/2. Sklar : il faut 9,6 dB
% pour 1e-5.
ebn0 = 0:10;
berTheorique = 0.5 * erfc(sqrt(10 .^ (ebn0 / 10)));
assert(max(abs(berawgn(ebn0, 'psk', 2, 'nondiff') - berTheorique) ./ berTheorique) < 1e-12);
assert(abs(berawgn(9.6, 'psk', 2, 'nondiff') - 9.73618e-06) < 1e-10);
% Simulation de Monte-Carlo : un million de bits à 6 dB.
rng(7);
nBits = 1e6;
bits = randi([0 1], nBits, 1);
symboles = 1 - 2 * bits;                                  % BPSK : 0 -> +1, 1 -> -1
ebn0Lin = 10 ^ (6 / 10);
recu = symboles + randn(nBits, 1) / sqrt(2 * ebn0Lin);
berSimulee = mean((recu < 0) ~= bits);
pAttendu = berawgn(6, 'psk', 2, 'nondiff');
assert(abs(berSimulee - pAttendu) < 4 * sqrt(pAttendu / nBits));
fprintf('communications : BPSK, Pb(6 dB) = %.3e simule, %.3e theorique\n', berSimulee, pAttendu);

%% ------------------------------------------------------------- ondelettes
% Daubechies (1988), « Orthonormal bases of compactly supported
% wavelets » : le filtre d'échelle de db2 a une forme fermée,
% (1+sqrt3, 3+sqrt3, 3-sqrt3, 1-sqrt3) / (4 sqrt2).
[LoD, ~, LoR, HiR] = wfilters('db2');
db2Exact = [1 + sqrt(3), 3 + sqrt(3), 3 - sqrt(3), 1 - sqrt(3)] / (4 * sqrt(2));
assert(max(abs(LoR - db2Exact)) < 1e-15 && max(abs(LoD - fliplr(db2Exact))) < 1e-15);
assert(max(abs(HiR - db2Exact(end:-1:1) .* [1 -1 1 -1])) < 1e-15);
% Décomposition à deux niveaux en mode 'sym' (le défaut de MATLAB),
% recoupée avec pywt.wavedec(x, 'db2', mode='symmetric', level=2).
assert(strcmp(dwtmode('status', 'nodisp'), 'sym'));
xOnd = sin((1:64) / 5) + 0.5 * cos((1:64) / 2);
[C, L] = wavedec(xOnd, 2, 'db2');
assert(isequal(L, [18 18 33 64]));
cA2 = appcoef(C, L, 'db2', 2);
cD1 = detcoef(C, L, 1);
cD2 = detcoef(C, L, 2);
refA2 = [1.2926476181082358 1.3069314883456249 0.88705383589855247 ...
         -0.11592543943731393 1.3227706658503664];
refD2 = [-0.011556161367810111 0.015064156580831586 -0.18636573544786728 ...
         0.3630138676627197 0.31315603737038689];
refD1 = [-0.013538870840923853 0.025622471513474715 -0.034055866965311529 ...
         0.073198594958493304 0.071503363934741757];
assert(max(abs(cA2([1 2 3 17 18]) - refA2)) < 1e-13);
assert(max(abs(cD2([1 2 3 17 18]) - refD2)) < 1e-13);
assert(max(abs(cD1([1 2 3 32 33]) - refD1)) < 1e-13);
assert(abs(sum(cA2) - 3.0265098279474332) < 1e-12 && abs(norm(cD1) - 0.31230040719273588) < 1e-13);
assert(max(abs(waverec(C, L, 'db2') - xOnd)) < 1e-12);
% Coiflettes : l'orientation de MATLAB, coifwavf('coif1') commence par
% -0.0515 (Daubechies, « Ten Lectures on Wavelets », tableau 8.1).
assert(abs(coifwavf('coif1') * [1; 0; 0; 0; 0; 0] - (-0.051429728470769)) < 1e-12);
fprintf('ondelettes : db2 en forme fermee, wavedec comme PyWavelets\n');

%% ------------------------------------------------- ajustement de courbes
% NIST StRD, régression non linéaire, jeu Misra1a (Misra, 1978) : valeurs
% certifiées à onze chiffres, b1 = 238.94212918, b2 = 5.5015643181e-4.
% FIT de la Curve Fitting Toolbox, depuis le départ 1 du NIST.
xMisra = [77.6 114.9 141.1 190.8 239.9 289.0 332.8 378.4 434.8 477.3 536.8 593.1 ...
          689.1 760.0]';
yMisra = [10.07 14.73 17.94 23.93 29.61 35.18 40.02 44.82 50.76 55.05 61.01 66.40 ...
          75.47 81.78]';
bMisra = [238.94212918 5.5015643181e-4];
seMisra = [2.7070075241 7.2668688436e-6];
chiffres = @(b, c) min(-log10(abs(b(:)' - c(:)') ./ abs(c(:)')));
[ajust, qualite] = fit(xMisra, yMisra, fittype('b1*(1-exp(-b2*x))'), 'StartPoint', [500 1e-4]);
assert(chiffres(coeffvalues(ajust), bMisra) > 8);
assert(abs(qualite.sse / 1.2455138894e-1 - 1) < 1e-9);
assert(abs(qualite.rmse / 1.0187876330e-1 - 1) < 1e-9);
icMisra = confint(ajust);              % b -+ t(0.975, 12) * ecart certifie
icNist = [bMisra - tinv(0.975, 12) * seMisra; bMisra + tinv(0.975, 12) * seMisra];
assert(max(abs(icMisra(:) ./ icNist(:) - 1)) < 1e-6);
% NLINFIT, avec les réglages par défaut de statset('nlinfit') : les
% paramètres et leurs écarts types certifiés.
[bN, ~, ~, covN] = nlinfit(xMisra, yMisra, @(b, x) b(1) * (1 - exp(-b(2) * x)), [500 1e-4]);
assert(chiffres(bN, bMisra) > 8);
assert(max(abs(sqrt(diag(covN))' ./ seMisra - 1)) < 1e-5);
% MGH09 (Kowalik et Osborne), « difficulté haute » : sept chiffres au
% moins avec des tolérances serrées.
xMgh = [4 2 1 0.5 0.25 0.167 0.125 0.1 0.0833 0.0714 0.0625]';
yMgh = [0.1957 0.1947 0.1735 0.16 0.0844 0.0627 0.0456 0.0342 0.0323 0.0235 0.0246]';
serre = statset('nlinfit');
serre.TolFun = 1e-15;
serre.TolX = 1e-15;
serre.MaxIter = 2000;
bMgh = nlinfit(xMgh, yMgh, @(b, x) b(1) * (x .^ 2 + x * b(2)) ./ (x .^ 2 + x * b(3) + b(4)), ...
               [0.25 0.39 0.415 0.39], serre);
assert(chiffres(bMgh, [0.19280693458 0.19128232873 0.12305650693 0.13606233068]) > 7);
% BoxBOD depuis le départ 1 du NIST : b2 part vers l'infini, où le modèle
% ne dépend plus de lui. NLINFIT le dit, comme MATLAB, au lieu de rendre
% en silence une estimation fausse ; depuis le départ 2, neuf chiffres.
xBox = [1 2 3 5 7 10]';
yBox = [109 149 149 191 213 224]';
modeleBox = @(b, x) b(1) * (1 - exp(-b(2) * x));
etatAvertissement = warning('off', 'stats:nlinfit:ModelConstantWRTParam');
lastwarn('');
nlinfit(xBox, yBox, modeleBox, [1 1]);
[~, idBox] = lastwarn();
warning(etatAvertissement);
assert(strcmp(idBox, 'stats:nlinfit:ModelConstantWRTParam'));
assert(chiffres(nlinfit(xBox, yBox, modeleBox, [100 0.75], serre), ...
                [213.80940889 0.54723748542]) > 8);
fprintf('ajustement : NIST Misra1a, MGH09, BoxBOD (avertissement du depart 1)\n');

%% ------------------------------------------------------------- symbolique
% Bombelli (L'Algebra, 1572) : x^3 = 15x + 4 a pour racines 4 et -2 +- sqrt(3).
% La racine rationnelle est trouvée exactement ; SOLVE rend une colonne de
% SYM, comme MATLAB.
syms x n
racinesB = solve(x ^ 3 - 15 * x - 4 == 0, x);
assert(isa(racinesB, 'sym') && isequal(size(racinesB), [3 1]));
assert(double(racinesB(3)) == 4);
assert(max(abs(double(racinesB) - [-2 - sqrt(3); -2 + sqrt(3); 4])) < 1e-14);
% L'intégrale de Gauss (Laplace, 1774) : sqrt(pi), par la fonction
% d'erreur et le passage à la limite aux bornes infinies.
assert(abs(double(int(exp(-x ^ 2), x, -Inf, Inf)) - sqrt(pi)) < 1e-12);
assert(abs(double(int(1 / (1 + x ^ 2), x, 0, 1)) - pi / 4) < 1e-15);
% Une primitive discontinue sur l'intervalle est refusée : -1/x entre -1
% et 1 donnerait -2 pour une intégrale qui diverge.
refusInt = '';
try
    int(1 / x ^ 2, x, -1, 1);
catch erreurInt
    refusInt = erreurInt.identifier;
end
assert(strcmp(refusInt, 'symbolic:int:Verification'));
% Taylor (1715) : sin(x) = x - x^3/6 + x^5/120 - x^7/5040 + ...
coefficientsSin = sym2poly(taylor(sin(x), x, 0, 'Order', 8));
assert(max(abs(coefficientsSin - [-1/5040 0 1/120 0 -1/6 0 1 0])) < 1e-16);
% Bernoulli (1683) : (1 + 1/n)^n tend vers e.
assert(abs(double(limit((1 + 1 / n) ^ n, n, Inf)) - exp(1)) < 1e-10);
% MATLABFUNCTION compile des coefficients exacts : 1/120, non 0.00833333.
fExp = matlabFunction(taylor(exp(x)));
assert(abs(fExp(1) - sum(1 ./ factorial(0:5))) < 1e-15);
fprintf('symbolique : Bombelli, Gauss, Taylor, Bernoulli\n');

%% ------------------------------------------------------------------- edp
% L'exemple pdex1 de la documentation de MATLAB : pi^2 u_t = u_xx,
% u(x,0) = sin(pi x), solution exacte exp(-t) sin(pi x). Erreur en h^2.
fonctionEdp = @(x, t, u, dudx) deal(pi ^ 2, dudx, 0);
initiale = @(x) sin(pi * x);
bords = @(xl, ul, xr, ur, t) deal(ul, 0, pi * exp(-t), 1);
erreursEdp = zeros(1, 2);
for k = 1:2
    xEdp = linspace(0, 1, 20 * k);
    solEdp = pdepe(0, fonctionEdp, initiale, bords, xEdp, linspace(0, 2, 5));
    erreursEdp(k) = max(abs(solEdp(end, :, 1) - exp(-2) * sin(pi * xEdp)));
end
assert(erreursEdp(1) < 2e-3 && erreursEdp(1) / erreursEdp(2) > 3.5);
% D'Alembert : la corde pincée sur son mode fondamental revient à sa
% forme après une période 2L/c.
[uOnde, xOnde] = wave1D(@(x) sin(pi * x), 1, 1, 2, 99, 400);
assert(max(abs(uOnde(:, end) - sin(pi * xOnde(:)))) < 1e-7);
% Laplace sur le carré, un bord à 1 et trois à 0 : au centre, 1/4 par
% superposition des quatre rotations.
uLaplace = laplace2D(1, 0, 0, 0, 21, 21);
assert(abs(uLaplace(11, 11) - 0.25) < 1e-10);
% Poisson, solution sin(pi x) sin(pi y) : ordre deux.
erreursP = zeros(1, 2);
for k = 1:2
    nP = 16 * k - 1;
    [uP, xP, yP] = poisson2D(@(x, y) 2 * pi ^ 2 * sin(pi * x) .* sin(pi * y), nP, nP);
    erreursP(k) = max(max(abs(uP - sin(pi * yP(:)) * sin(pi * xP(:))')));
end
assert(erreursP(1) / erreursP(2) > 3.8);
% Éléments finis P1 en dimension un : exacts aux noeuds (Strang et Fix).
[uFem, xFem] = fem1D(@(x) ones(size(x)), 1, 10);
assert(max(abs(uFem(:) - xFem(:) .* (1 - xFem(:)) / 2)) < 1e-14);
fprintf('edp : pdex1 de MATLAB, d''Alembert, Laplace, Poisson, Galerkine\n');

%% --------------------------------------------------------------- robuste
% Le second ordre peu amorti : pic de résonance 1/(2 zeta sqrt(1-zeta^2))
% à la pulsation sqrt(1 - 2 zeta^2), norme H2 sqrt(wn/(4 zeta)).
zeta = 0.1;
Gr = tf(1, [1 2 * zeta 1]);
[picR, pulsationR] = hinfnorm(Gr);
assert(abs(picR / (1 / (2 * zeta * sqrt(1 - zeta ^ 2))) - 1) < 1e-12);
assert(abs(pulsationR - sqrt(1 - 2 * zeta ^ 2)) < 1e-6);
assert(abs(h2norm(Gr) - sqrt(1 / (4 * zeta))) < 1e-12);
% Skogestad et Postlethwaite (Multivariable Feedback Control), la colonne
% à distiller LV : G(0) = [87.8 -86.4; 108.2 -109.6], valeurs singulières
% 197.2 et 1.391, conditionnement 141.7.
G0 = [87.8 -86.4; 108.2 -109.6];
gR = tf(1, [75 1]);
Gd = [G0(1, 1) * gR, G0(1, 2) * gR; G0(2, 1) * gR, G0(2, 2) * gR];
assert(abs(hinfnorm(Gd) / max(svd(G0)) - 1) < 1e-8);
assert(round(max(svd(G0)), 1) == 197.2 && round(min(svd(G0)), 3) == 1.391);
assert(round(cond(G0), 1) == 141.7);
% Valeur singulière structurée de deux blocs scalaires complexes : pour
% trois blocs au plus, la borne de mise à l'échelle D est exacte (Doyle,
% 1982). min sur d de la norme de diag(1,d) M diag(1,1/d), recoupé par
% scipy.optimize : 5.734935367202969.
Mmu = [1 2; 3 4] + 1i * [0.5 -1; 2 0.3];
bornesMu = mussv(Mmu, [1 1; 1 1]);
assert(abs(bornesMu(1) - 5.734935367202969) < 1e-9 && bornesMu(1) - bornesMu(2) < 1e-7);
fprintf('robuste : resonance, colonne LV de Skogestad, mu de Doyle\n');

%% ------------------------------------------------------------ aerospatial
% L'atmosphère type (U.S. Standard Atmosphere 1976, OACI) : l'exemple de
% MathWorks à 1000 m, puis les tables aux bases des couches.
[T1, a1, P1, rho1] = atmosisa(1000);
assert(abs(T1 - 281.65) < 1e-12 && round(a1, 4) == 336.4340);
assert(round(P1 / 1e4, 4) == 8.9875 && round(rho1, 4) == 1.1116);
hTable = [11000 20000 32000 47000 51000 71000];
TTable = [216.65 216.65 228.65 270.65 270.65 214.65];
PTable = [22632.06 5474.889 868.0187 110.9063 66.93887 3.956420];
[TCouches, ~, PCouches] = atmosisa(hTable);
assert(max(abs(TCouches - TTable)) < 1e-9);
assert(max(abs(PCouches ./ PTable - 1)) < 1e-5);
% Hors du domaine, les valeurs de la borne, et un avertissement.
etatIsa = warning('off', 'aero:atmosisa:Domaine');
assert(isequal(atmosisa(90000), atmosisa(84852)));
warning(etatIsa);
fprintf('aerospatial : atmosphere type, sept couches\n');

%% -------------------------------------------------------- bioinformatique
% Les exemples de la documentation de MATLAB : BLOSUM50, trou de 8, score
% en bits (un tiers de bit par unité), alignement sur trois lignes.
[scoreNw, alignementNw] = nwalign('VSPAGMASGYD', 'IPGKASYD');
assert(abs(scoreNw - 22 / 3) < 1e-12);
assert(isequal(alignementNw, ['VSPAGMASGYD'; ': | | || ||'; 'I-P-GKAS-YD']));
[scorePam, alignementPam] = nwalign('VSPAGMASGYD', 'IPGKASYD', 'ScoringMatrix', 'PAM250', ...
                                    'GapOpen', 5);
assert(abs(scorePam - 6) < 1e-12 && isequal(alignementPam(2, :), ': | |:|| ||'));
assert(abs(nwalign('VSPAGMASGYD', 'IPGKASYD', 'Scale', log(2)) - 22 / 3 * log(2)) < 1e-12);
% Durbin, Eddy, Krogh et Mitchison (Biological Sequence Analysis, 1998),
% figures 2.5 et 2.6 : HEAGAWGHEE contre PAWHEAE, score global 1 et
% score local 28, recoupés avec Biopython.
[scoreDurbin, alignementDurbin] = nwalign('HEAGAWGHEE', 'PAWHEAE');
assert(abs(3 * scoreDurbin - 1) < 1e-12);
assert(isequal(alignementDurbin([1 3], :), ['HEAGAWGHE-E'; '--P-AW-HEAE']));
[scoreLocalD, alignementLocalD, debutD] = swalign('HEAGAWGHEE', 'PAWHEAE');
assert(abs(3 * scoreLocalD - 28) < 1e-12 && isequal(debutD, [5; 2]));
assert(isequal(alignementLocalD([1 3], :), ['AWGHE'; 'AW-HE']));
assert(abs(3 * swalign('VSPAGMASGYD', 'IPGKASYD') - 26) < 1e-12);
% Trous affines (Gotoh, 1982) : ouverture 10, prolongement 1 -> 9.
assert(abs(3 * nwalign('HEAGAWGHEE', 'PAWHEAE', 'GapOpen', 10, 'ExtendGap', 1) - 9) < 1e-12);
fprintf('bioinformatique : exemples de MathWorks, Durbin et al.\n');

%% ------------------------------------------------------------ cartographie
% Vincenty (1975), ligne d'essai (a) sur l'ellipsoïde de Bessel : 55°45' N
% vers 33°26' S, 108°13' E ; 14 110 526,170 m. GeographicLib (Karney) :
% 14110526.16958 m, azimut 96.60244433227 degrés.
[sBessel, azBessel] = distance(55 + 45 / 60, 0, -(33 + 26 / 60), 108 + 13 / 60, ...
                               referenceEllipsoid('bessel'));
assert(abs(sBessel - 14110526.170) < 1e-3 && abs(azBessel - 96.60244433227386) < 1e-8);
% Geoscience Australia : de Flinders Peak à Buninyong, sur GRS80,
% 54 972,271 m, azimut 306°52'05.37", retour 127°10'25.07".
dms = @(d, m, s) d + m / 60 + s / 3600;
flinders = [-dms(37, 57, 3.72030), dms(144, 25, 29.52440)];
buninyong = [-dms(37, 39, 10.15610), dms(143, 55, 35.38390)];
grs80 = referenceEllipsoid('grs80');
[sGa, azGa] = distance(flinders(1), flinders(2), buninyong(1), buninyong(2), grs80);
assert(abs(sGa - 54972.2711391288) < 1e-6);
assert(abs(azGa - dms(306, 52, 5.37)) < 0.005 / 3600);
assert(abs(azimuth(buninyong(1), buninyong(2), flinders(1), flinders(2), grs80) - ...
           dms(127, 10, 25.07)) < 0.005 / 3600);
% Le problème direct ramène au point de départ.
[latR, lonR] = reckon(flinders(1), flinders(2), sGa, azGa, grs80);
assert(abs(latR - buninyong(1)) < 1e-10 && abs(lonR - buninyong(2)) < 1e-10);
% Aires : l'octant couvre 1/8 de la sphère ; le fuseau de 30 degrés de la
% documentation de MATLAB, 1/12 (« areaquad(90,0,-90,30) = 0.0833 »).
assert(abs(areaint([0 0 90], [0 90 0]) - 1 / 8) < 1e-15);
assert(abs(areaint([-90:30:90 60:-30:-60], [zeros(1, 7) 30 * ones(1, 5)]) - 1 / 12) < 1e-15);
assert(abs(areaquad(90, 0, -90, 30) - 1 / 12) < 1e-15);
% La surface de l'ellipsoïde WGS84 : 510 065 621,724 km2.
assert(abs(areaquad(-90, -180, 90, 180, wgs84Ellipsoid('km')) - 510065621.724) < 1e-3);
fprintf('cartographie : Vincenty, Flinders Peak - Buninyong, aires\n');

%% ------------------------------------------------------- gestion des risques
% Les exemples de MathWorks pour varbacktest : 1043 observations ; à 99 %,
% 17 dépassements donnent un feu jaune, Probability 0.97991, TypeI
% 0.03686, Increase 0.26582 ; POF 3.5118 (p 0.060933) ; Bin 2.0446 (p
% 0.040896) ; à 95 %, 57 dépassements, vert, 0.77913.
cas = {0.99, 17, 'yellow', 0.97991, 0.03686, 0.26582, 3.5118, 0.060933, 2.0446, 0.040896;
       0.99, 22, 'yellow', 0.99952, 0.0011122, 0.43511, 9.8298, 0.0017171, 3.6006, 0.0003175;
       0.95, 57, 'green', 0.77913, 0.26396, 0, 0.46147, 0.49694, 0.68905, 0.49079};
for k = 1:size(cas, 1)
    rendementsR = [-ones(cas{k, 2}, 1); zeros(1043 - cas{k, 2}, 1)];
    vR = varbacktest(rendementsR, 0.5 * ones(1043, 1), 'VaRLevel', cas{k, 1});
    feu = tl(vR);
    proportion = pof(vR, 'TestLevel', 0.9);
    binomial = bin(vR, 'TestLevel', 0.9);
    proche = @(v, ref) abs(v - ref) <= 5e-5 * max(abs(ref), 1e-3) + 1e-12;
    assert(feu.TL == cas{k, 3} && proche(feu.Probability, cas{k, 4}));
    assert(proche(feu.TypeI, cas{k, 5}) && proche(feu.Increase, cas{k, 6}));
    assert(proche(proportion.LRatioPOF, cas{k, 7}) && proche(proportion.PValuePOF, cas{k, 8}));
    assert(proche(binomial.ZScoreBin, cas{k, 9}) && proche(binomial.PValueBin, cas{k, 10}));
end
% Le feu tricolore du Comité de Bâle (1996) : 250 jours à 99 %, vert
% jusqu'à 4 dépassements (probabilité cumulée 89,22 %), jaune de 5
% (95,88 %) à 9 (99,97 %), rouge à partir de 10.
zones = {'green', 'yellow', 'yellow', 'red'};
for k = 1:4
    nombreD = [4 5 9 10];
    vB = varbacktest([-ones(nombreD(k), 1); zeros(250 - nombreD(k), 1)], 0.5 * ones(250, 1), ...
                     'VaRLevel', 0.99);
    feuB = tl(vB);
    assert(feuB.TL == zones{k});
end
assert(round(tl(varbacktest([-ones(4, 1); zeros(246, 1)], 0.5 * ones(250, 1), ...
       'VaRLevel', 0.99)).Probability, 4) == 0.8922);
fprintf('risques : exemples de MathWorks, feu tricolore de Bale\n');

disp('litterature : toutes les verifications passent');
