% test_econometrie.m — séries temporelles, racines unitaires, cointégration
% et modèles ARIMA/GARCH.
%
% Chaque vérification confronte une fonction à la propriété qui la
% définit : la taille et la puissance d'un test sur des séries dont on
% connaît la nature, une statistique à sa forme fermée, une prévision à
% l'expression analytique de l'espérance conditionnelle.
disp('--- econometrie ---');

%% --------------------------------------------- racine unitaire et stationnarité
rng(7);
% ADFTEST : l'hypothèse nulle est la racine unitaire. La proportion de
% rejets sur une marche aléatoire est le seuil, celle sur un bruit blanc
% la puissance.
fauxAdf = 0; vusAdf = 0;
for essai = 1:40
    if adftest(cumsum(randn(1, 300))), fauxAdf = fauxAdf + 1; end
    if adftest(randn(1, 300)),         vusAdf = vusAdf + 1;  end
end
assert(fauxAdf <= 8, sprintf('adftest : %d faux rejets sur 40', fauxAdf));
assert(vusAdf >= 36, sprintf('adftest : %d bruits vus sur 40', vusAdf));

% Les trois modèles et les deux formes de statistique tournent.
serieMarche = cumsum(randn(1, 300));
for modele = {'AR', 'ARD', 'TS'}
    for forme = {'t1', 't2'}
        [~, ~, statistique, critique] = adftest(serieMarche, ...
            'Model', modele{1}, 'Test', forme{1}, 'Lags', 2);
        assert(isfinite(statistique) && isfinite(critique));
    end
end
% La forme abrégée ADFTEST(Y,L) veut dire L retards.
[~, ~, abrege] = adftest(serieMarche, 3);
[~, ~, nomme] = adftest(serieMarche, 'Lags', 3);
assert(abs(abrege - nomme) < 1e-12);

% Les valeurs critiques tabulées reproduisent celles que publient Dickey
% et Fuller, à quelques centièmes près.
[~, ~, ~, critiqueAR]  = adftest(serieMarche, 'Model', 'AR');
[~, ~, ~, critiqueARD] = adftest(serieMarche, 'Model', 'ARD');
[~, ~, ~, critiqueTS]  = adftest(serieMarche, 'Model', 'TS');
assert(abs(critiqueAR  - (-1.95)) < 0.08);
assert(abs(critiqueARD - (-2.86)) < 0.08);
assert(abs(critiqueTS  - (-3.41)) < 0.08);

% PPTEST : même hypothèse nulle, correction non paramétrique.
fauxPp = 0; vusPp = 0;
for essai = 1:20
    if pptest(cumsum(randn(1, 300))), fauxPp = fauxPp + 1; end
    if pptest(randn(1, 300)),         vusPp = vusPp + 1;  end
end
assert(fauxPp <= 4 && vusPp >= 17);
for modele = {'AR', 'ARD', 'TS'}
    [~, ~, statistique] = pptest(randn(1, 200), 'Model', modele{1});
    assert(isfinite(statistique));
end

% KPSSTEST : l'hypothèse nulle est ici la stationnarité, à l'inverse.
fauxKpss = 0; vusKpss = 0;
for essai = 1:20
    if kpsstest(randn(1, 300)),          fauxKpss = fauxKpss + 1; end
    if kpsstest(cumsum(randn(1, 300))),  vusKpss = vusKpss + 1;  end
end
assert(fauxKpss <= 4 && vusKpss >= 17);

% LMCTEST : même hypothèse nulle que KPSS, correction paramétrique.
fauxLmc = 0; vusLmc = 0;
for essai = 1:10
    if lmctest(randn(1, 200)),          fauxLmc = fauxLmc + 1; end
    if lmctest(cumsum(randn(1, 200))),  vusLmc = vusLmc + 1;  end
end
assert(fauxLmc <= 3 && vusLmc >= 8);
assert(isfinite(lmctest(randn(1, 150), 'Trend', false)));

%% ------------------------------------------------- rapport des variances
% Sous une marche aléatoire la variance croît proportionnellement à
% l'horizon : le rapport vaut un. Pour un accroissement AR(1) de
% paramètre p, il vaut 1 + 2*somme((1-k/q) p^k).
fauxVr = 0; vusVr = 0;
for essai = 1:20
    if vratiotest(cumsum(randn(1, 600))), fauxVr = fauxVr + 1; end
    if vratiotest(cumsum(filter(1, [1 -0.6], randn(1, 600))))
        vusVr = vusVr + 1;
    end
end
assert(fauxVr <= 4 && vusVr >= 17);
[~, ~, ~, ~, rapports] = vratiotest(cumsum(randn(1, 5000)), 'Period', [2 4 8]);
assert(max(abs(rapports - 1)) < 0.25);
% La valeur théorique du rapport pour un AR(1) de paramètre 0,7 à
% l'horizon 4.
rho = 0.7;
attendu = 1 + 2 * sum((1 - (1:3) / 4) .* rho .^ (1:3));
[~, ~, ~, ~, mesure] = vratiotest(cumsum(filter(1, [1 -rho], randn(1, 20000))), ...
                                  'Period', 4);
assert(abs(mesure - attendu) < 0.2, ...
       sprintf('rapport %.4f, attendu %.4f', mesure, attendu));
% Les deux estimations de la variance de la statistique, sur la même série.
serieRapport = cumsum(randn(1, 4000));
[~, ~, sIid] = vratiotest(serieRapport, 'Period', 4, 'IID', true);
[~, ~, sRobuste] = vratiotest(serieRapport, 'Period', 4, 'IID', false);
assert(isfinite(sIid) && isfinite(sRobuste));

%% ------------------------------------------- autocorrélation et hétéroscédasticité
fauxLbq = 0; vusLbq = 0;
for essai = 1:20
    if lbqtest(randn(1, 300)), fauxLbq = fauxLbq + 1; end
    if lbqtest(filter(1, [1 -0.5], randn(1, 300))), vusLbq = vusLbq + 1; end
end
assert(fauxLbq <= 4 && vusLbq >= 17);
fauxArch = 0;
for essai = 1:20
    if archtest(randn(1, 300)), fauxArch = fauxArch + 1; end
end
assert(fauxArch <= 4);

%% ---------------------------------------------- tests d'hypothèses emboîtées
% Le test de Wald sur une seule restriction linéaire est le carré du
% rapport de Student du coefficient.
rng(11);
nWald = 200;
Xwald = [randn(nWald, 1), randn(nWald, 1)];
yWald = 1 + 2 * Xwald(:, 1) + randn(nWald, 1);
modeleWald = ols(yWald, Xwald);
covarianceWald = modeleWald.sigma2 * inv([ones(nWald, 1), Xwald].' * [ones(nWald, 1), Xwald]);
restriction = [0 1 0];
[~, ~, statWald] = waldtest(restriction * modeleWald.beta, restriction, covarianceWald);
assert(abs(statWald - modeleWald.t(2) ^ 2) < 1e-9);
% Une restriction vraie n'est pas rejetée, une restriction fausse l'est.
nulle = [0 0 1];
assert(waldtest(nulle * modeleWald.beta, nulle, covarianceWald) == 0);
assert(waldtest(restriction * modeleWald.beta, restriction, covarianceWald) == 1);

% Rapport de vraisemblance : deux fois l'écart, comparé à un khi-deux.
[hLr, pLr, statLr, critiqueLr] = lratiotest(-140.2, -145.7, 1);
assert(abs(statLr - 11) < 1e-12);
assert(abs(critiqueLr - chi2inv(0.95, 1)) < 1e-9);
assert(hLr == 1 && pLr < 0.05);
assert(lratiotest(-140.2, -140.25, 1) == 0);
assert(isequal(lratiotest([-140.2 -145.65], -145.7, 1), [1 0]));

%% --------------------------------------------------- causalité de Granger
rng(3);
vusGranger = 0; fauxGranger = 0;
for essai = 1:20
    nG = 400;
    cause = randn(nG, 1);
    effet = 0.3 * randn(nG, 1);
    effet(2:end) = effet(2:end) + 0.8 * cause(1:end-1);
    if gctest(cause, effet), vusGranger = vusGranger + 1; end
    if gctest(effet, cause), fauxGranger = fauxGranger + 1; end
end
assert(vusGranger == 20 && fauxGranger <= 4);
% La forme khi-deux vaut le nombre de retards fois la forme de Fisher, et
% avec un seul retard cette dernière est le carré du t du coefficient.
xG = randn(300, 1);
yG = [0; 0.5 * xG(1:end-1)] + randn(300, 1);
[~, ~, statChi] = gctest(xG, yG, 'NumLags', 3, 'Test', 'chi2');
[~, ~, statF] = gctest(xG, yG, 'NumLags', 3, 'Test', 'f');
assert(abs(statChi - 3 * statF) < 1e-9);
[~, ~, statUn] = gctest(xG, yG, 'NumLags', 1, 'Test', 'f');
modeleG = ols(yG(2:end), [yG(1:end-1), xG(1:end-1)]);
assert(abs(statUn - modeleG.t(3) ^ 2) < 1e-8);

%% ---------------------------------------------------------- colinéarité
% Deux colonnes presque proportionnelles : indice de conditionnement
% énorme, et proportions de variance qui les désignent toutes deux.
colonne = randn(100, 1);
Xcol = [ones(100, 1), colonne, colonne + 1e-4 * randn(100, 1)];
[valeurs, indices, proportions] = collintest(Xcol, 'display', 'off');
assert(abs(indices(1) - 1) < 1e-12 && indices(3) > 100);
assert(max(abs(sum(proportions, 1) - 1)) < 1e-10);
assert(proportions(3, 2) > 0.9 && proportions(3, 3) > 0.9);
% L'indice le plus grand est le conditionnement de la matrice réduite.
normes = sqrt(sum(Xcol .^ 2, 1));
assert(abs(cond(Xcol ./ repmat(normes, 100, 1)) - max(indices)) / max(indices) < 1e-9);
% Des colonnes orthogonales n'ont aucun indice élevé.
[~, indicesQ] = collintest([eye(3); zeros(1, 3)], 'display', 'off');
assert(max(abs(indicesQ - 1)) < 1e-10);
assert(numel(valeurs) == 3);

%% ------------------------------------------------- cointégration d'Engle-Granger
rng(23);
fauxEg = 0; vusEg = 0;
for essai = 1:20
    if egcitest([cumsum(randn(300, 1)), cumsum(randn(300, 1))])
        fauxEg = fauxEg + 1;
    end
    commune = cumsum(randn(300, 1));
    if egcitest([2 * commune + randn(300, 1), commune]), vusEg = vusEg + 1; end
end
assert(fauxEg <= 7 && vusEg >= 18);
% Plus il y a de régresseurs, plus la valeur critique est sévère.
Yeg = cumsum(randn(300, 4), 1);
[~, ~, ~, critiqueTrois] = egcitest(Yeg);
[~, ~, ~, critiqueUn] = egcitest(Yeg(:, 1:2));
assert(critiqueTrois < critiqueUn - 0.5);
% La régression rendue reconstruit les résidus, et retrouve la pente.
commune = cumsum(randn(300, 1));
Yliees = [2 * commune + 1 + randn(300, 1), commune];
[~, ~, ~, ~, regression] = egcitest(Yliees);
assert(abs(regression.coefficients(2) - 2) < 0.1);
attenduResidus = Yliees(:, 1) - [ones(300, 1), Yliees(:, 2)] * regression.coefficients;
assert(max(abs(regression.residus - attenduResidus)) < 1e-10);
% Un vecteur de cointégration donné ramène le test à une racine unitaire
% ordinaire : même valeur critique.
[~, ~, ~, critiqueDonne] = egcitest(Yliees, 'cvec', [1; -2]);
[~, ~, ~, critiqueAdf] = adftest(Yliees * [1; -2], 'Model', 'ARD');
assert(abs(critiqueDonne - critiqueAdf) < 1e-9);
for specification = {'nc', 'c', 'ct'}
    for residuelle = {'adf', 'pp'}
        for forme = {'t1', 't2'}
            [~, ~, statistique] = egcitest(Yliees, 'creg', specification{1}, ...
                'rreg', residuelle{1}, 'test', forme{1});
            assert(isfinite(statistique));
        end
    end
end

%% ---------------------------------------------------- cointégration de Johansen
rng(17);
fauxJci = 0;
for essai = 1:20
    rejets = jcitest(cumsum(randn(300, 3), 1), 'display', 'off');
    if rejets(1), fauxJci = fauxJci + 1; end
end
assert(fauxJci <= 4);
unes = 0; deux = 0;
for essai = 1:20
    commune = cumsum(randn(300, 1));
    rejets = jcitest([commune + randn(300, 1), commune, cumsum(randn(300, 1))], ...
                     'display', 'off');
    if rejets(1) == 1 && rejets(2) == 0, unes = unes + 1; end
    rejets = jcitest([commune + randn(300, 1), commune + randn(300, 1), commune], ...
                     'display', 'off');
    if rejets(1) == 1 && rejets(2) == 1 && rejets(3) == 0, deux = deux + 1; end
end
assert(unes >= 15 && deux >= 14);
% La statistique de trace est la somme des statistiques de valeur propre
% maximale à partir du rang testé.
commune = cumsum(randn(400, 1));
Yjci = [commune + randn(400, 1), commune, cumsum(randn(400, 1))];
[~, ~, statTrace] = jcitest(Yjci, 'display', 'off', 'test', 'trace');
[~, ~, statMax] = jcitest(Yjci, 'display', 'off', 'test', 'maxeig');
sommes = cumsum(statMax(end:-1:1));
assert(max(abs(statTrace - sommes(end:-1:1))) < 1e-9);
% La log-vraisemblance croît avec le rang autorisé.
[~, ~, ~, ~, estimations] = jcitest(Yjci, 'display', 'off');
vraisemblances = zeros(1, 3);
for rang = 1:3
    vraisemblances(rang) = estimations{rang}.logL;
end
assert(all(diff(vraisemblances) > 0));
% La relation trouvée rend une combinaison stationnaire là où les séries
% ne le sont pas.
combinaison = Yjci * estimations{2}.B;
[~, ~, statCombinaison] = adftest(combinaison);
[~, ~, statBrute] = adftest(Yjci(:, 2));
assert(adftest(combinaison) == 1 && adftest(Yjci(:, 2)) == 0);
assert(statCombinaison < statBrute - 3);
for modele = {'H2', 'H1*', 'H1', 'H*', 'H'}
    [~, ~, statistique] = jcitest(Yjci, 'display', 'off', 'model', modele{1}, 'lags', 2);
    assert(all(isfinite(statistique)));
end

%% ------------------------------------------------------ modèles ARIMA
rng(5);
specification = arima(2, 1, 1);
assert(specification.P == 3 && specification.D == 1 && specification.Q == 1);
% Les polynômes se développent : une différence multiplie par (1 - L).
[phi, theta, phiNiveaux] = matlibre_arima_polynomes( ...
    arima('AR', {0.5}, 'MA', {0.3}, 'Constant', 0, 'Variance', 1, 'D', 1));
assert(isequal(phi, 0.5) && isequal(theta, 0.3));
assert(max(abs(phiNiveaux - [1.5 -0.5])) < 1e-12);

% Simulation : variance et autocorrélation théoriques d'un AR(1).
modeleAR = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
serieAR = simulate(modeleAR, 20000);
assert(abs(var(serieAR) - 1 / (1 - 0.64)) < 0.25);
correlations = autocorr(serieAR, 1);
assert(abs(correlations(2) - 0.8) < 0.03);
% MA(1) : la première autocorrélation vaut theta/(1+theta^2), la seconde
% est nulle.
serieMA = simulate(arima('Constant', 0, 'MA', {0.6}, 'Variance', 1), 20000);
correlations = autocorr(serieMA, 3);
assert(abs(correlations(2) - 0.6 / 1.36) < 0.03);
assert(abs(correlations(3)) < 0.03);

% Estimation : les coefficients retrouvent ceux qui ont servi à simuler.
rng(9);
serieEstimee = simulate(arima('Constant', 0.5, 'AR', {0.7}, 'Variance', 2), 1500);
ajusteAR = estimate(arima(1, 0, 0), serieEstimee, 'Display', 'off');
assert(abs(ajusteAR.AR{1} - 0.7) < 0.05);
assert(abs(ajusteAR.Constant - 0.5) < 0.15);
assert(abs(ajusteAR.Variance - 2) < 0.25);
serieArma = simulate(arima('Constant', 0, 'AR', {0.6}, 'MA', {0.4}, 'Variance', 1), 700);
ajusteArma = estimate(arima(1, 0, 1), serieArma, 'Display', 'off');
assert(abs(ajusteArma.AR{1} - 0.6) < 0.12);
assert(abs(ajusteArma.MA{1} - 0.4) < 0.15);
% Un coefficient fixé n'est pas touché : c'est ainsi qu'on contraint.
contraint = estimate(arima('ARLags', 1, 'Constant', 0), serieArma, 'Display', 'off');
assert(contraint.Constant == 0);
% INFER blanchit la série quand le modèle est le bon, et rend la même
% vraisemblance qu'ESTIMATE.
[innovations, ~, vraisemblance] = infer(ajusteArma, serieArma);
assert(lbqtest(innovations) == 0 && lbqtest(serieArma) == 1);
assert(abs(vraisemblance - ajusteArma.LogL) < 1e-8);

% Prévision d'un AR(1) : décroissance géométrique vers la moyenne, et
% variance de l'erreur égale à la somme des carrés des poids.
rng(13);
modelePrevision = arima('Constant', 1, 'AR', {0.8}, 'Variance', 1);
seriePrevision = simulate(modelePrevision, 400);
[previsions, variances] = forecast(modelePrevision, 10, 'Y0', seriePrevision);
moyenne = 1 / (1 - 0.8);
attendu = moyenne + (0.8 .^ (1:10)).' * (seriePrevision(end) - moyenne);
assert(max(abs(previsions - attendu)) < 0.02);
assert(max(abs(variances - cumsum(0.8 .^ (2 * (0:9))).')) < 1e-9);
% À long horizon, la prévision est la moyenne et la variance celle de la
% série.
[loin, variancesLoin] = forecast(modelePrevision, 200, 'Y0', seriePrevision);
assert(abs(loin(end) - moyenne) < 1e-6);
assert(abs(variancesLoin(end) - 1 / (1 - 0.64)) < 1e-6);
% Marche aléatoire : prévision plate, variance proportionnelle à
% l'horizon.
serieMarcheAleatoire = simulate(arima('Constant', 0, 'D', 1, 'Variance', 1), 300);
[platte, croissante] = forecast(arima('Constant', 0, 'D', 1, 'Variance', 1), 5, ...
                                'Y0', serieMarcheAleatoire);
assert(max(abs(platte - serieMarcheAleatoire(end))) < 1e-9);
assert(max(abs(croissante.' - (1:5))) < 1e-9);
% Marche avec dérive : la prévision monte d'une constante par pas.
modeleDerive = arima('Constant', 0.5, 'D', 1, 'Variance', 1);
serieDerive = simulate(modeleDerive, 300);
pente = forecast(modeleDerive, 4, 'Y0', serieDerive);
assert(max(abs(diff(pente) - 0.5)) < 1e-9);
assert(abs(pente(1) - (serieDerive(end) + 0.5)) < 1e-9);

% FILTER refait pas à pas la récurrence, sur un bruit donné.
modeleFiltre = arima('Constant', 0, 'AR', {0.5}, 'MA', {0.3}, 'Variance', 4);
bruitReduit = randn(50, 1);
filtree = filter(modeleFiltre, bruitReduit);
attenduFiltre = zeros(50, 1);
bruit = 2 * bruitReduit;
for t = 1:50
    valeur = bruit(t);
    if t > 1
        valeur = valeur + 0.5 * attenduFiltre(t - 1) + 0.3 * bruit(t - 1);
    end
    attenduFiltre(t) = valeur;
end
assert(max(abs(filtree - attenduFiltre)) < 1e-12);
% Plusieurs trajectoires d'un coup.
assert(isequal(size(simulate(modelePrevision, 100, 'NumPaths', 7)), [100 7]));

%% ------------------------------------------------------- modèles GARCH
rng(21);
modeleGarch = garch('Constant', 0.1, 'GARCH', {0.8}, 'ARCH', {0.15});
[serieGarch, chocs, variancesGarch] = simulate(modeleGarch, 30000);
longTerme = 0.1 / (1 - 0.95);
assert(abs(var(serieGarch) / longTerme - 1) < 0.25);
assert(abs(mean(variancesGarch) / longTerme - 1) < 0.25);
% La série est hétéroscédastique, les innovations réduites ne le sont
% plus : c'est exactement ce que le modèle prétend.
reduites = chocs ./ sqrt(variancesGarch);
assert(archtest(serieGarch, 'Lags', 3) == 1);
assert(archtest(reduites, 'Lags', 3) == 0);
% INFER retrouve les variances qui ont servi à simuler.
[~, variancesInferees] = infer(modeleGarch, serieGarch(1:4000));
assert(corr(variancesInferees, variancesGarch(1:4000)) > 0.999);
% Estimation.
ajusteGarch = estimate(garch(1, 1), serieGarch(1:2500), 'Display', 'off');
assert(abs(ajusteGarch.GARCH{1} - 0.8) < 0.12);
assert(abs(ajusteGarch.ARCH{1} - 0.15) < 0.08);
assert(ajusteGarch.Constant > 0 && ajusteGarch.Constant < 0.3);
assert(ajusteGarch.GARCH{1} + ajusteGarch.ARCH{1} < 1);
% Prévision de variance : elle suit la récurrence déterministe et tend
% vers la variance de long terme.
prevues = forecast(modeleGarch, 300, 'Y0', serieGarch(1:2000));
[~, variancesObservees] = infer(modeleGarch, serieGarch(1:2000));
attenduGarch = zeros(5, 1);
attenduGarch(1) = 0.1 + 0.8 * variancesObservees(end) + ...
                  0.15 * serieGarch(2000) ^ 2;
for h = 2:5
    attenduGarch(h) = 0.1 + 0.95 * attenduGarch(h - 1);
end
assert(max(abs(prevues(1:5) - attenduGarch)) < 1e-10);
assert(abs(prevues(end) - longTerme) < 1e-3);
% Un modèle dont les coefficients somment au-delà de un n'a pas de
% variance de long terme : simuler doit être refusé.
refuse = false;
try
    simulate(garch('Constant', 0.1, 'GARCH', {0.8}, 'ARCH', {0.3}), 10);
catch erreur
    refuse = strcmp(erreur.identifier, 'econ:garch:Stationnarite');
end
assert(refuse);
% SUMMARIZE rend la même chose que ce qu'il écrit.
resume = summarize(ajusteGarch);
assert(resume.Estimated);
assert(numel(resume.ParameterValues) == 3);
assert(abs(resume.LogLikelihood - ajusteGarch.LogL) < 1e-12);
[aic, bic] = aicbic(ajusteGarch.LogL, 3, 2500);
assert(abs(resume.AIC - aic) < 1e-12 && abs(resume.BIC - bic) < 1e-12);

%% ------------------------------------------------- rendements et prix
rng(2);
prix = 100 * exp(cumsum(0.01 * randn(200, 1)));
rendements = price2ret(prix);
assert(numel(rendements) == 199);
assert(max(abs(ret2price(rendements, prix(1)) - prix)) < 1e-9);
% La corrélation croisée d'une série avec elle-même est maximale en zéro
% et y vaut un.
[croisees, decalages] = crosscorr(rendements, rendements, 10);
assert(abs(croisees(decalages == 0) - 1) < 1e-12);
assert(max(croisees) - 1 < 1e-12);

disp('econometrie : toutes les verifications passent');
