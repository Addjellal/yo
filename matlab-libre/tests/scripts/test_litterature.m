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

%% ----------------------------------------------------------------- radar
% Exemples de la documentation de MathWorks (Radar Toolbox) : radareqpow,
% radareqrng et radareqsnr, aux quatre chiffres imprimés, monostatique et
% bistatique ; l'équation du radar (Skolnik, Introduction to Radar
% Systems) les relie : les trois se recoupent à 1e-12 près.
c = physconst('LightSpeed');
assert(round(radareqpow(c / 1e9, 50e3, 6, 1e-6), -1) == 2.1996e5);
assert(round(radareqpow(c / 10e9, 50e3, 10, 1e-6, 'RCS', 0.5, 'Gain', 30, 'Ts', 300, ...
                        'Loss', 3), -2) == 2.2809e6);
assert(round(radareqpow(c / 10e9, [50e3 75e3], 6, 10e-6, 'Gain', [40 20]), 0) == 49492);
assert(round(radareqrng(c / 10e9, 6, 1e6, 10e-6)) == 41057);
assert(round(radareqrng(c / 10e9, 6, 1e6, 10e-6, 'Gain', 40, 'RCS', 0.1, 'Loss', 3), -1) ...
       == 1.9426e5);
assert(round(radareqsnr(c / 1e9, 50e3, 1e6, 0.2e-6), 4) == 5.5868);
assert(round(radareqsnr(c / 10e9, 100e3, 1e6, 1e-6, 'RCS', 0.5, 'Gain', 40, 'Ts', 300, ...
                        'Loss', 3), 4) == 14.3778);
assert(round(radareqsnr(c / 10e9, [50e3 75e3], 1e6, 1e-6, 'Gain', [40 20]), 4) == 9.0547);
% Une valeur de RSB par cible donne une puissance par cible ; une perte
% atmosphérique scalaire vaut pour l'aller et compte aussi au retour.
P = radareqpow(c / 10e9, 50e3, [6; 10], 1e-6, 'RCS', 0.5, 'Gain', 30, 'Ts', 300, 'Loss', 3);
assert(isequal(size(P), [2 1]) && round(P(2), -2) == 2.2809e6);
assert(abs(radareqsnr(c / 1e9, 50e3, 1e6, 0.2e-6) - ...
           radareqsnr(c / 1e9, 50e3, 1e6, 0.2e-6, 'AtmosphericLoss', 1) - 2) < 1e-12);
portee = radareqrng(c / 10e9, 13, 1e6, 1e-6, 'Gain', 30);
assert(abs(radareqsnr(c / 10e9, portee, 1e6, 1e-6, 'Gain', 30) - 13) < 1e-12);
assert(abs(radareqpow(c / 10e9, portee, 13, 1e-6, 'Gain', 30) / 1e6 - 1) < 1e-12);
% Compression d'impulsion d'un chirp (Cook et Bernfeld, Radar Signals) :
% premier lobe secondaire à -13,26 dB pour un produit BT grand ; ici
% BT = 200, -13,39 dB recoupé par NumPy. Résolution c / 2B.
fe = 100e6; duree = 10e-6; bande = 20e6;
n = round(duree * fe);
t = ((0:n - 1) - n / 2) / fe;
chirp = exp(1i * pi * (bande / duree) * t .^ 2);
[sortie, retards] = pulseCompression([zeros(1, 100), chirp, zeros(1, 100)], chirp);
module = abs(sortie);
[sommet, ip] = max(module);
assert(retards(ip) == 100);
droite = ip;
while module(droite + 1) < module(droite), droite = droite + 1; end
gauche = ip;
while module(gauche - 1) < module(gauche), gauche = gauche - 1; end
pslr = 20 * log10(max(max(module(1:gauche - 1)), max(module(droite + 1:end))) / sommet);
assert(abs(pslr - (-13.392875439097)) < 1e-9);
assert(abs(bw2rangeres(20e6) - c / 40e6) < 1e-12 && abs(rangeres2bw(bw2rangeres(5e6)) - 5e6) < 1e-6);
fprintf('radar : exemples de MathWorks, chirp a -13,39 dB\n');

%% -------------------------------------------------------------------- rf
% Pozar, Microwave Engineering : une charge de 100 ohms sur une ligne de
% 50 ohms réfléchit un tiers de l'onde, ROS 2, perte de retour 9,54 dB.
% L'atténuateur adapté de 3 dB en T (R1 = 8,55 ohms, R2 = 141,9 ohms) a
% S11 = 0 et S21 = 10^(-3/20) ; les conversions S, Z, Y et ABCD
% (tableau 4.2) se défont l'une l'autre.
gamma = z2gamma(100, 50);
assert(abs(gamma - 1/3) < 1e-15 && abs(vswr(gamma) - 2) < 1e-14);
assert(abs(-20 * log10(gamma) - 9.5424250943932) < 1e-12);
K = 10 ^ (3 / 20);
R1 = 50 * (K - 1) / (K + 1);
R2 = 100 * K / (K ^ 2 - 1);
assert(round(R1, 2) == 8.55 && round(R2, 1) == 141.9);
Sattenuateur = z2s([R1 + R2, R2; R2, R1 + R2]);
assert(max(abs(diag(Sattenuateur))) < 1e-14 && abs(Sattenuateur(2, 1) - 1 / K) < 1e-14);
assert(norm(s2z(Sattenuateur) - [R1 + R2, R2; R2, R1 + R2]) < 1e-10);
assert(norm(abcd2s(s2abcd(Sattenuateur)) - Sattenuateur) < 1e-14);
assert(norm(y2s(s2y(Sattenuateur)) - Sattenuateur) < 1e-14);
assert(abs(gammain([0 1; 1 0], 50, 100) - 1/3) < 1e-15);
% L'impédance série de 100 ohms : ABCD = [1 100 ; 0 1], S11 = 1/2.
Sserie = abcd2s([1 100; 0 1]);
assert(abs(Sserie(1, 1) - 0.5) < 1e-15 && abs(Sserie(2, 1) - 0.5) < 1e-15);
fprintf('rf : Pozar, attenuateur de 3 dB en T\n');

%% --------------------------------------------------------------- antennes
% Balanis, Antenna Theory, § 4.6 : le dipôle demi-onde a une directivité
% de 4 / Cin(2 pi) = 1,6409 (2,15 dBi) et ouvre à 78° ; un réseau
% uniforme de dix éléments à lambda/2 a une directivité de N = 10, une
% ouverture de 10,21° et son premier zéro à asin(1/(N d)) = 11,54°.
% Valeurs exactes recoupées par scipy.special.sici et scipy.optimize.
theta = linspace(1e-9, pi - 1e-9, 200001);
E = dipolePattern(theta, 0.5);
assert(abs(directivity(theta, E) - 1.6409223769845853) < 1e-9);
assert(abs(rad2deg(beamwidth(theta, E)) - 78.07771889112405) < 1e-4);
AF = arrayFactor(10, 0.5, theta);
assert(abs(directivity(theta, AF) - 10) < 1e-9);
assert(abs(rad2deg(beamwidth(theta, AF)) - 10.209175947792808) < 1e-4);
assert(abs(friis(1, 1, 1, 1, 1 / (4 * pi)) - 1) < 1e-15);
fprintf('antennes : dipole demi-onde de Balanis, reseau de dix elements\n');

%% ---------------------------------------------------- reseaux d'antennes
% Exemples de la documentation de MathWorks : steervec (avec et sans
% quantification des phases sur 3 bits), sensorcov, rootmusicdoa et
% espritdoa. Avec la covariance exacte, MUSIC (Schmidt, 1986) et ESPRIT
% (Roy et Kailath, 1989) retrouvent les directions -25, 0 et 30 degrés.
sv = steervec((0:0.1:0.4) / (c / 1e9), [45; 0]);
assert(max(abs(round(sv * 1e4) / 1e4 - [1; 0.0887 + 0.9961i; -0.9843 + 0.1767i; ...
                                         -0.2633 - 0.9647i; 0.9376 - 0.3478i])) < 1e-12);
assert(max(abs(steervec((0:0.1:0.4) / (c / 1e9), [45; 0], 3) - [1; 1i; -1; -1i; 1])) < 1e-12);
xcov = sensorcov((0:2) * 0.5, [30 60]);
assert(abs(round(xcov(1, 2) * 1e4) / 1e4 - (-0.9127 - 1.4086i)) < 1e-12);
xcov = sensorcov((0:2) * 0.5, [30 35], db2pow(-10), [1 0.8; 0.8 1]);
assert(round(real(xcov(2, 2)), 4) == 3.6574 && round(real(xcov(3, 3)), 4) == 3.5321);
R = sensorcov((0:9) * 0.5, [0 -25 30], db2pow(-5));
assert(max(abs(sort(rootmusicdoa(R, 3)) - [-25 0 30])) < 1e-6);
assert(max(abs(sort(espritdoa(R, 3)) - [-25 0 30])) < 1e-10);
R = sensorcov((0:9) * 0.4, [0 -25 30], db2pow(-5));
assert(max(abs(sort(espritdoa(R, 3, 'ElementSpacing', 0.4)) - [-25 0 30])) < 1e-10);
covmat = sensorcov((0:10) * 0.5, [-60.2 -20.7 0.5 84.8], db2pow(-5));
assert(isequal(round(sort(musicdoa(covmat, 4, 'ScanAngles', -70:0.1:90)) * 10), ...
               [-602 -207 5 848]));
% La super-résolution : deux sources à 0 et 6 degrés, plus proches que
% l'ouverture (10,2 degrés) ; la formation de voies n'y voit qu'un pic,
% MUSIC en voit deux.
Rproche = sensorcov((0:9) * 0.5, [0 6], db2pow(-20));
[~, ~, angles] = musicdoa(Rproche, 2, 'ScanAngles', -30:0.1:30);
A = steervec((0:9) * 0.5, angles);
voies = real(sum(conj(A) .* (Rproche * A), 1));
% Un seul lobe, centré entre les deux sources, sans creux qui les sépare.
[~, ipic] = max(voies);
entre = voies(angles > 0 & angles < 6);
creux = nnz(entre(2:end - 1) < entre(1:end - 2) & entre(2:end - 1) < entre(3:end));
assert(abs(angles(ipic) - 3) < 1e-9 && creux == 0);
assert(isequal(sort(musicdoa(Rproche, 2)), [0 6]));
fprintf('reseaux d''antennes : exemples de MathWorks, MUSIC et ESPRIT\n');

%% -------------------------------------------------------------------- dsp
% firls (moindres carrés intégrés, Parks et Burrus, Digital Filter
% Design) recoupé avec scipy.signal.firls pour le type I, et avec une
% quadrature de Gauss-Legendre indépendante pour les types II et III ;
% le transformateur de Hilbert approche h(±1) = ±2/pi. levinson résout le
% système de Toeplitz hermitien comme scipy.linalg.solve_toeplitz ;
% upfirdn rend la longueur et les valeurs de scipy.signal.upfirdn.
b = firls(40, [0 .3 .4 1], [1 1 0 0]);
assert(max(abs([b(1) b(11) b(21) sum(b) sum(b .^ 2)] - [0.00025702984090014095 ...
       -0.021924854828191596 0.3491555470669215 1.003700623758178 0.3337777638736499])) < 1e-14);
b = firls(40, [0 .3 .4 1], [1 1 0 0], [1 100]);
assert(max(abs([b(1) b(11) b(21)] - [0.0015157599889283526 -0.020877935359264244 ...
       0.33979526753844197])) < 1e-13);
b = firls(41, [0 .3 .4 1], [1 1 0 0]);
assert(max(abs([b(1) b(21) b(22)] - [-0.0012514185211521043 0.3328986093953944 ...
       0.3328986093953944])) < 1e-13);
b = firls(30, [.1 .9], [1 1], 'hilbert');
assert(max(abs([b(1) b(13) b(15) b(17) b(31)] - [0.0025778536998605946 0.19530983926210657 ...
       0.6308181948790426 -0.6308181948790426 -0.0025778536998605946])) < 1e-13);
assert(b(16) == 0 && abs(b(15) - 2 / pi) < 0.01);
[a, e, k] = levinson([3, 1 + 1i, 0.5 - 0.25i, 0.1i], 3);
assert(max(abs(a(2:end) - [-0.5234449760765549 - 0.7205741626794258i, ...
       -0.38038277511961716 + 0.6849282296650716i, 0.5023923444976075 - 0.05837320574162678i])) ...
       < 1e-14);
assert(abs(e - 1.3887200956937802) < 1e-14 && abs(k(end) - a(end)) < 1e-15);
[a, e] = levinson([16 8 -2] / 9, 2);
assert(max(abs(a - [1 -0.75 0.5])) < 1e-15 && abs(e - 1) < 1e-15);
assert(isequal(upfirdn([1 2 3], [1 1 1], 2), [1 1 3 2 5 3 3]));
assert(max(abs(upfirdn(1:7, [.5 1 .5 .25], 3, 2) - [0.5 0.5 2 2 1.5 4 3.5 2.5 6 5 3.5])) < 1e-15);
fprintf('dsp : firls, levinson et upfirdn comme SciPy\n');

%% ------------------------------------------------------------------ audio
% Exemples de la documentation de MathWorks pour zerocrossrate ; échelles
% perceptives d'O'Shaughnessy (Mel, 1987 : 1000 Hz valent 1000 mels),
% de Traunmüller (Bark, 1990, avec ses corrections aux deux bouts) et de
% Glasberg et Moore (ERB, 1990) ; centroïde spectral de Peeters (2004).
x = [1 -1 1 -1 1 -1 1 -1 1 -1];
assert(abs(zerocrossrate(x) - 0.95) < 1e-15);
assert(abs(zerocrossrate(x, 'Method', 'comparison') - 0.9) < 1e-15);
assert(abs(zerocrossrate(x, 'ZeroPositive', true) - 0.9) < 1e-15);
assert(abs(zerocrossrate(x, 'InitialState', 1) - 0.9) < 1e-15);
assert(abs(hz2mel(1000) - 999.9855371396244) < 1e-12);
assert(abs(hz2bark(1000) - 8.527432432432432) < 1e-13);
assert(abs(hz2bark(50) - 0.4163781094527363) < 1e-13);
assert(abs(hz2bark(15000) - 23.859642924528302) < 1e-12);
assert(abs(hz2erb(1000) - 15.572016680910268) < 1e-12);
f = [20 100 500 1000 4000 8000 15000];
assert(max(abs(mel2hz(hz2mel(f)) - f) ./ f) < 1e-14);
assert(max(abs(bark2hz(hz2bark(f)) - f) ./ f) < 1e-13);
assert(max(abs(erb2hz(hz2erb(f)) - f) ./ f) < 1e-13);
fe = 8000;
t = (0:fe - 1).' / fe;
centroides = spectralCentroid(sin(2 * pi * 1000 * t), fe);
assert(numel(centroides) == 98 && max(abs(centroides - 1000)) < 1e-9);
fprintf('audio : zerocrossrate de MathWorks, echelles de Mel, Bark et ERB\n');

%% ------------------------------------------------ communications sans fil
% fspl : l'exemple de la documentation de MathWorks (radar à 10 GHz sur
% 10 km, 132,4478 dB). OFDM à la numérologie d'IEEE 802.11a : 64
% sous-porteuses, 48 de données, pilotes à -21, -7, 7 et 21, préfixe de
% 16 ; le canal plus court que le préfixe s'égalise exactement, un
% coefficient par sous-porteuse. Capacité de Shannon (1948).
assert(round(fspl(10e3, c / 10e9), 4) == 132.4478);
assert(fspl(1e-3, 0.1) == 0);
rng(7);
nulles = [1:6 33 60:64].';
pilotes = [12 26 40 54].';
porteuses = setdiff((1:64).', [nulles; pilotes]);
donnees = qammod(randi([0 15], 48, 10), 16, 'UnitAveragePower', true);
emis = ofdmmod(donnees, 64, 16, nulles, pilotes, repmat([1; 1; 1; -1], 1, 10));
assert(numel(porteuses) == 48 && size(emis, 1) == 800);
canal = [1; 0.5; -0.3; 0.15];
recu = conv(emis, canal);
H = fftshift(fft(canal, 64));
egalise = ofdmdemod(recu(1:800), 64, 16, 16, nulles, pilotes) ./ H(porteuses);
assert(max(abs(egalise(:) - donnees(:))) < 1e-13);
[deDemi, pilotesRecus] = ofdmdemod(emis, 64, 16, 9, nulles, pilotes);
assert(max(abs(deDemi(:) - donnees(:))) < 1e-13 && all(pilotesRecus(4, :) == -1 + 0i | ...
       abs(pilotesRecus(4, :) + 1) < 1e-13));
assert(abs(throughputShannon(20e6, 20) / 1e6 - 20 * log2(101)) < 1e-12);
assert(abs(qammod(0, 16) - (-3 + 3i)) == 0 && qamdemod(1 - 1i, 16) == 15);
fprintf('sans fil : fspl de MathWorks, OFDM d''IEEE 802.11a\n');

%% ----------------------------------------------------------------- vision
% bboxOverlapRatio : l'exemple de la documentation de MathWorks (0,0833).
% Détecteur de Harris et Stephens (1988) sur le damier : les 49
% intersections intérieures, sans faux coin ; à l'écart de la couture
% entre les deux moitiés (où le contraste change), chaque coin tombe au
% centième de pixel près entre ses quatre pixels. Transformation
% géométrique robuste (MSAC, Torr et Zisserman, 2000) : similitude,
% rigide et projective (DLT normalisée de Hartley) retrouvées malgré
% vingt appariements aberrants sur soixante-dix.
bboxA = [150 80 100 100];
assert(round(bboxOverlapRatio(bboxA, bboxA + 50), 4) == 0.0833);
assert(bboxOverlapRatio(bboxA, bboxA + 50, 'Min') == 0.25);
coins = detectHarrisFeatures(checkerboard(10));
[gx, gy] = meshgrid(10.5:10:70.5);
attendus = [gx(:) gy(:)];
assert(size(coins, 1) == 49);
ecarts = zeros(49, 1);
for k = 1:49
    ecarts(k) = min(sqrt(sum((coins - attendus(k, :)) .^ 2, 2)));
end
assert(max(ecarts(attendus(:, 1) ~= 40.5)) < 1e-12 && max(ecarts) < 1);
rng(5);
p1 = 400 * rand(50, 2);
aberrantsA = 400 * rand(20, 2);
aberrantsB = 400 * rand(20, 2);
for type = {'similarity', 'rigid', 'projective'}
    switch type{1}
        case 'similarity'
            Tvrai = [1.5 * cosd(30), 1.5 * sind(30), 0; -1.5 * sind(30), 1.5 * cosd(30), 0; 10 -5 1];
        case 'rigid'
            Tvrai = [cosd(30), sind(30), 0; -sind(30), cosd(30), 0; 10 -5 1];
        otherwise
            Tvrai = [1 0.2 0.0004; -0.1 1.1 0.0002; 30 -20 1];
    end
    q = [p1 ones(50, 1)] * Tvrai;
    p2 = q(:, 1:2) ./ q(:, 3);
    [T, retenus] = estimateGeometricTransform2D([p1; aberrantsA], [p2; aberrantsB], type{1});
    assert(norm(T - Tvrai) < 1e-9 && all(retenus(1:50)) && ~any(retenus(51:end)));
end
fprintf('vision : IoU de MathWorks, Harris sur damier, MSAC\n');

%% ------------------------------------------------------------- robotique
% Angles d'Euler, quaternions et axe-angle comparés à
% scipy.spatial.transform.Rotation (rotations intrinsèques) ; produit,
% division et rotation de quaternions comparés aux exemples de la
% documentation de MathWorks ; trajectoires cubique (3 s^2 - 2 s^3) et
% quintique (10 s^3 - 15 s^4 + 6 s^5) en forme fermée ; profil trapézoïdal
% de durée D/V + V/a ; cinématique inverse du bras 2R (Spong).
eul = [0.3 -0.7 1.1];
Rref = struct('ZYX', [0.7306816499355122 -0.6825356334181358 -0.015793529118639904; ...
                      0.226026321249623 0.2636694534871921 -0.9377582425124971; ...
                      0.644217687237691 0.6816329865934228 0.34692944965489886], ...
              'ZYZ', [0.06806457918412756 -0.7852356838288306 -0.6154446635582734; ...
                      0.953927573102912 0.23190060505842858 -0.1903793440673726; ...
                      0.2922146442847723 -0.574131544347986 0.7648421872844884], ...
              'XYZ', [0.3469294496548989 -0.6816329865934228 -0.644217687237691; ...
                      0.7650475783754858 0.6030043987602139 -0.22602632124962302; ...
                      0.5425330955655645 -0.41444199432919854 0.7306816499355123]);
qref = struct('ZYX', [0.7650621793484506 0.5291698089444968 -0.215672410090385 0.2968915400580633], ...
              'ZYZ', [0.7184718803695529 -0.1335306957605727 -0.3158297953763279 0.6051605165247341], ...
              'XYZ', [0.8186292656554958 -0.057539988180335414 -0.36242009435522565 0.4417996722272436]);
for sequence = {'ZYX', 'ZYZ', 'XYZ'}
    s0 = sequence{1};
    assert(norm(eul2rotm(eul, s0) - Rref.(s0)) < 1e-15);
    q = eul2quat(eul, s0);
    assert(norm(q * sign(q(1)) - qref.(s0)) < 1e-15);
    assert(norm(eul2rotm(rotm2eul(Rref.(s0), s0), s0) - Rref.(s0)) < 1e-14);
    assert(norm(quat2rotm(qref.(s0)) - Rref.(s0)) < 1e-15);
end
assert(norm(rotm2axang(Rref.ZYX) - [0.8217478672997409 -0.33491771456250635 ...
       0.46104291238512146 1.3993168871760486]) < 1e-14);
assert(norm(quatmultiply([1 0 1 0], [1 0.5 0.5 0.75; 2 1 0.1 0.1]) - ...
            [0.5 1.25 1.5 0.25; 1.9 1.1 2.1 -0.9]) < 1e-15);
assert(isequal(quatmultiply([1 0 1 0]), [0 0 2 0]));
assert(norm(round(quatdivide([1 0 1 0; 2 1 0.1 0.1], [1 0.5 0.5 0.75]) * 1e4) / 1e4 - ...
            [0.7273 0.1212 0.2424 -0.6061; 1.2727 0.0121 -0.7758 -0.4606]) < 1e-12);
assert(norm(round(quatrotate([1 0 1 0; 1 0.5 0.3 0.1], [1 1 1; 2 3 4]) * 1e4) / 1e4 - ...
            [-1 1 1; 1.3333 5.1333 0.9333]) < 1e-12);
assert(quatnorm([.5 -.5 .5 0]) == 0.75);
t = linspace(0, 2, 9); s1 = t / 2;
[q, qd] = cubicpolytraj([0 1], [0 2], t);
assert(max(abs(q - (3 * s1 .^ 2 - 2 * s1 .^ 3))) < 1e-15 && max(abs(qd - 3 * (s1 - s1 .^ 2))) < 1e-15);
[q, ~, ~, pp] = quinticpolytraj([0 1 3; 5 2 0], [0 1 2], t);
assert(max(abs(q(1, 1:5) - (10 * s1(1:5) .^ 3 * 8 - 15 * s1(1:5) .^ 4 * 16 + 6 * s1(1:5) .^ 5 * 32))) < 1e-14);
assert(max(max(abs(ppval(pp, t) - q))) < 1e-14);
[q, qd, qdd, tt, pp] = trapveltraj([0 1], 101, 'PeakVelocity', 2, 'Acceleration', 8);
assert(abs(tt(end) - 0.75) < 1e-15 && abs(max(qd) - 2) < 1e-12 && abs(max(qdd) - 8) < 1e-12);
assert(max(abs(ppval(pp, tt) - q)) < 1e-15);
qHaut = ikine2R(1, 1, 1, 1, true);
assert(norm(ikine2R(1, 1, 1, 1) - [0 pi/2]) < 1e-15 && norm(qHaut - [pi/2 -pi/2]) < 1e-15);
fprintf('robotique : SciPy Rotation, quaternions de MathWorks, trajectoires exactes\n');

%% -------------------------------------------------------- identification
% Le système de Ljung, A = 1 - 1.5 q^-1 + 0.7 q^-2, B = q^-1 + 0.5 q^-2,
% C = 1 - q^-1 + 0.2 q^-2, sur des données déterministes reproduites
% dans NumPy : ARX coïncide avec numpy.linalg.lstsq, ARMAX avec le
% minimum du même critère trouvé par scipy.optimize.least_squares ; sans
% bruit, OE et N4SID retrouvent exactement le système. Les critères
% d'information suivent les formules de la documentation de MATLAB.
N = 800; k = (1:N).';
u = sign(sin(0.7 * k .^ 2)); u(u == 0) = 1;
e = (mod(k * 7919, 1009) / 1009 - 0.5) * 0.8;
y = filter([0 1 0.5], [1 -1.5 0.7], u) + filter([1 -1 0.2], [1 -1.5 0.7], e);
mArx = arx(iddata(y, u, 1), [2 2 1]);
assert(norm([mArx.A(2:3) mArx.B(2:3)] - [-1.4877558570641585 0.6885056734788418 ...
       1.004519904155692 0.5083633109218358]) < 1e-12);
mArmax = armax(iddata(y, u, 1), [2 2 2 1]);
assert(norm([mArmax.A(2:3) mArmax.B(2:3) mArmax.C(2:3)] - [-1.5004890514741955 ...
       0.6997720938555467 1.0008661155064025 0.49426965323360017 -0.824855019782917 ...
       -0.14690297451769144]) < 1e-8);
ySans = filter([0 1 0.5], [1 -1.5 0.7], u);
mOe = oe(iddata(ySans, u, 1), [2 2 1]);
assert(norm(mOe.B - [0 1 0.5]) < 1e-9 && norm(mOe.F - [1 -1.5 0.7]) < 1e-9);
mSs = n4sid(iddata(ySans, u, 1), 2);
assert(norm(sort(eig(mSs.A)) - sort(roots([1 -1.5 0.7]))) < 1e-8);
V = mArx.Report.Fit.LossFcn;
assert(abs(aic(mArx) - (log(V) + 2 * 4 / N)) < 1e-12);
assert(abs(aic(mArx, 'aic') - (N * log(V) + 8 + N * (log(2 * pi) + 1))) < 1e-8);
assert(abs(fpe(mArx) - V * (1 + 4 / N) / (1 - 4 / N)) < 1e-14);
fprintf('identification : ARX et ARMAX comme NumPy et SciPy, OE et N4SID exacts\n');

%% ------------------------------------------------------------ navigation
% Distances et caps de grand cercle sur la sphère de 6371 km, contre
% GeographicLib (aplatissement nul) ; l'exemple de Sinnott (1984), de
% Nashville à Los Angeles : 2887,26 km sur la sphère de 6372,8 km ; A* sur
% une grille à deux murs : le coût de Dijkstra (scipy.sparse.csgraph).
geo = [48.8566 2.3522 40.7128 -74.006 5837240.903825839 291.7938627483058;
       51.4778 -0.0015 -33.8688 151.2093 16987903.236853257 60.93711274880161;
       0 0 0 179.5 19959489.332698293 90;
       89.9 10 -80 -150 18913579.936230656 339.8041819164661;
       36.12 -86.67 33.94 -118.4 2886444.442837984 274.59357410546284];
for k = 1:size(geo, 1)
    assert(abs(haversine(geo(k, 1), geo(k, 2), geo(k, 3), geo(k, 4)) / geo(k, 5) - 1) < 1e-14);
    ecartCap = mod(azimuthTo(geo(k, 1), geo(k, 2), geo(k, 3), geo(k, 4)) - geo(k, 6) + 180, 360) - 180;
    assert(abs(ecartCap) < 1e-12);
end
assert(abs(haversine(36.12, -86.67, 33.94, -118.40, 6372800) - 2887259.950607111) < 1e-6);
G = zeros(30, 40);
[J, I] = meshgrid(1:40, 1:30);
G(mod(7 * I + 13 * J, 11) == 0) = 1;
G(10, 1:35) = 1; G(20, 6:40) = 1; G(9:11, 36:40) = 0; G(19:21, 1:5) = 0; G(1, 1) = 0; G(30, 40) = 0;
[chemin, cout] = astar(G, [1 1], [30 40]);
assert(cout == 138 && size(chemin, 1) == 139);
assert(all(sum(abs(diff(chemin)), 2) == 1) && ~any(G(sub2ind(size(G), chemin(:, 1), chemin(:, 2)))));
fprintf('navigation : GeographicLib, Sinnott, A* comme Dijkstra\n');

%% ---------------------------------------------------- fusion de capteurs
% Filtre de Kalman (1960) : en régime permanent, la covariance est la
% solution de l'équation de Riccati discrète (scipy.linalg.solve_discrete_are).
% Filtre de Madgwick (2010) : la trajectoire du paquet Python ahrs, au
% dernier chiffre. Affectation au plus proche voisin global : l'optimum
% de Kuhn et Munkres, comme scipy.optimize.linear_sum_assignment.
dt = 0.1; A = [1 dt; 0 1]; H = [1 0]; Q = 0.5 * [dt^3/3 dt^2/2; dt^2/2 dt];
x = [0; 0]; P = eye(2);
for k = 1:400
    [x, P] = kalmanFilter(x, P, 0, A, H, Q, 0.04);
end
assert(norm(P - [0.015071524210003292 0.035304727580025924; 0.035304727580025924 ...
       0.1884490936920618]) < 1e-15);
t = (1:300).' * 0.01;
gyr = [0.4 * sin(3 * t), 0.3 * cos(2 * t), 0.2 * sin(5 * t + 1)];
acc = [0.3 + 0.1 * sin(7 * t), -0.2 + 0.1 * cos(4 * t), 9.6 + 0.05 * sin(11 * t)];
q = [1 0 0 0];
for k = 1:300
    q = madgwickUpdate(q, gyr(k, :), acc(k, :), 0.01, 0.1);
end
assert(norm(q - [0.9987428027666099 0.0366036609856267 0.009434381564191562 ...
       0.032923826764932926]) < 1e-14);
a = trackAssign([0 0; 1 0; 5 5; 6 4], [0.4 0; -0.7 0; 5.5 4.2; 6.2 5.1; 20 20]);
assert(isequal(a.', [2 1 4 3]));
assert(isequal(trackAssign([0 0; 10 0], [0.1 -0.2; 50 50], 3).', [1 0]));
[ap, lignes, colonnes] = assignmunkres([1 2; 1.5 10], 20);
assert(isequal(sortrows(ap), [1 2; 2 1]) && isempty(lignes) && isempty(colonnes));
fprintf('fusion : Riccati, Madgwick comme ahrs, affectation de Munkres\n');

%% ------------------------------------------------------------------- mpc
% Sans contrainte et sur un horizon long, la commande prédictive rend la
% commande du régulateur LQR de même pondération (Riccati discrète de
% SciPy) ; sous bornes, le programme quadratique a la solution des
% moindres carrés bornés de scipy.optimize.lsq_linear, qu'un écrêtage de
% la solution libre n'atteindrait pas.
Am = [1 0.1; 0 1]; Bm = [0.005; 0.1]; Cm = [1 0];
ctrl = mpcSetup(Am, Bm, Cm, 300, 300, 1, 0.1);
gain = -[mpcmove(ctrl, [1; 0], 0), mpcmove(ctrl, [0; 1], 0)];
assert(norm(gain - [2.788857174991727 2.3617185162469]) < 1e-9);
ctrl = mpcSetup(Am, Bm, Cm, 20, 5, 1, 0.1);
ctrl.umin = -1.5; ctrl.umax = 1.5;
[~, U] = mpcmove(ctrl, [1; 0], 0);
assert(norm(U.' - [-1.5 -1.5 -1.5 -1.5 -1.1404399323181036]) < 1e-12);
ctrl.umin = -inf; ctrl.umax = inf;
[~, libre] = mpcmove(ctrl, [1; 0], 0);
assert(abs(min(max(libre(end), -1.5), 1.5) - U(end)) > 0.5);
fprintf('mpc : LQR a l''horizon infini, contraintes comme lsq_linear\n');

%% ----------------------------------------------------------------- lidar
% Plan dominant par RANSAC (Fischler et Bolles, 1981), réajusté au sens
% des moindres carrés orthogonaux sur ses points ralliés : la normale de
% la décomposition en valeurs singulières des vrais points du plan,
% malgré les parasites. Recalage ICP (Besl et McKay, 1992) : quand les
% appariements initiaux sont justes, la transformation exacte (Arun,
% Huang et Blostein, 1987), et toujours une rotation propre.
[gx, gy] = meshgrid(-5:0.5:5);
plan = [gx(:), gy(:), 0.5 * gx(:) - 0.2 * gy(:) + 1 + 0.01 * sin(7 * gx(:) + 3 * gy(:))];
parasites = [4 * sin(1:60).', 4 * cos(1.7 * (1:60)).', 6 + 3 * sin(2.3 * (1:60)).'];
rng(1);
[modele, rallies] = fitPlaneRansac([plan; parasites], 0.05, 300);
centre = mean(plan, 1);
[~, ~, Vp] = svd(plan - centre, 0);
normale = Vp(:, end) * sign(Vp(3, end));
assert(isequal(sort(rallies(:)).', 1:size(plan, 1)));
assert(norm(modele(1:3) * sign(modele(3)) - normale) < 1e-13);
forme = [cos(0:0.1:2*pi).', sin(0:0.1:2*pi).'] .* [2 1];
Rv = [cosd(1) -sind(1); sind(1) cosd(1)];
[R, tr] = icpRegister(forme, forme * Rv.' + [0.03 -0.02], 60);
assert(norm(R - Rv) < 1e-13 && norm(tr - [0.03 -0.02]) < 1e-13 && abs(det(R) - 1) < 1e-13);
fprintf('lidar : RANSAC reajuste, ICP exact\n');

%% -------------------------------------------------------------- vehicule
% Formule magique de Pacejka, avec les coefficients publiés par MathWorks
% pour quatre revêtements (sec, mouillé, neige, glace) : la force culmine
% à D Fz au glissement où C atan(...) = pi/2 (racine trouvée par
% scipy.optimize.brentq), et la raideur à l'origine vaut B C D Fz. Le
% modèle bicyclette cinématique (Rajamani) tourne sur un cercle de rayon
% L / tan(delta).
jeux = [10 1.9 1 0.97 0.18019439934006307; 12 2.3 0.82 1 0.08816435953597898;
        5 2 0.3 1 0.3114815449313295; 4 2 0.1 1 0.3893519311641385];
for k = 1:4
    c0 = num2cell(jeux(k, 1:4));
    assert(abs(tireForce(jeux(k, 5), 4000, c0{:}) - jeux(k, 3) * 4000) < 1e-9);
    raideur = (tireForce(1e-7, 4000, c0{:}) - tireForce(-1e-7, 4000, c0{:})) / 2e-7;
    assert(abs(raideur / (prod(jeux(k, 1:3)) * 4000) - 1) < 1e-8);
end
L = 2.7; braquage = deg2rad(10); v = 5; pas = 1e-3;
etat = [0 0 0];
nPas = round(2 * pi * (L / tan(braquage)) / v / pas);
for k = 1:nPas
    etat = bicycleModel(etat, v, braquage, L, pas);
end
assert(norm(etat(1:2)) < 0.02 * L / tan(braquage) && abs(etat(3) - 2 * pi) < 1e-2);
fprintf('vehicule : Pacejka, revetements de MathWorks ; bicyclette\n');

%% ---------------------------------------------------- conduite automatisee
% Pure pursuit (Coulter, 1992) : sur un cercle de rayon R, la courbure
% commandée 2 sin(alpha) / L vaut exactement 1/R, quel que soit le point
% visé. Le lissage de chemin converge vers la solution du système
% linéaire de ses conditions d'équilibre ; temps avant collision.
R = 20; th = linspace(0, 2 * pi, 2001).';
for vise = [1 3 8]
    assert(abs(purePursuit([R 0 pi/2], [R * cos(th), R * sin(th)], vise, 8) - 8 / R) < 1e-12);
end
brut = [0 0; 1 0.8; 2 -0.5; 3 0.6; 4 0; 5 0.4; 6 0];
lisse = smoothPath(brut, 0.5, 0.3, 1e-14);
n = size(brut, 1);
M = zeros(n); b2 = zeros(n, 2);
M(1, 1) = 1; M(n, n) = 1; b2([1 n], :) = brut([1 n], :);
for i = 2:n - 1
    M(i, i - 1:i + 1) = [-0.3, 0.5 + 0.6, -0.3];
    b2(i, :) = 0.5 * brut(i, :);
end
assert(max(max(abs(lisse - M \ b2))) < 1e-12);
assert(timeToCollision(50, 10) == 5 && isinf(timeToCollision(50, -1)));
fprintf('conduite : pure pursuit de Coulter, lissage exact\n');

disp('litterature : toutes les verifications passent');
