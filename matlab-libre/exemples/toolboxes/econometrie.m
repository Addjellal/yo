% econometrie.m — Econometrics Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/econometrie.m
%
% Le cas : une série économique. La question qui précède toutes les
% autres est celle de la stationnarité — une régression entre deux séries
% non stationnaires donne des corrélations qui n'existent pas, et c'est
% le piège classique de l'économétrie.

fprintf('=== Econometrie : stationnarite, memoire, volatilite ===\n\n');

%% 1. Stationnaire ou non ?
% Une marche au hasard n'est pas stationnaire : sa variance croît avec le
% temps. Un processus autorégressif stable, si.
rng(1);
n = 500;
bruitBlanc = randn(n, 1);
marche = cumsum(bruitBlanc);
autoregressif = filter(1, [1 -0.7], bruitBlanc);
fprintf('Trois series de %d points :\n', n);
fprintf('  bruit blanc      : ecart type %.4f\n', std(bruitBlanc));
fprintf('  marche au hasard : ecart type %.4f\n', std(marche));
fprintf('  AR(1) a 0.7      : ecart type %.4f\n', std(autoregressif));
% La variance d'un AR(1) stable vaut sigma^2 / (1 - phi^2).
assert(abs(std(autoregressif) ^ 2 - 1 / (1 - 0.49)) < 0.4);

% Le test de Dickey-Fuller augmenté : l'hypothèse nulle est la présence
% d'une racine unitaire, c'est-à-dire la non-stationnarité.
[rejetMarche, pMarche] = adftest(marche);
[rejetAr, pAr] = adftest(autoregressif);
fprintf('\nTest de Dickey-Fuller augmente (H0 : racine unitaire) :\n');
fprintf('  marche au hasard : p = %.4f, %s\n', pMarche, ...
        matlibre_essai_verdict(rejetMarche));
fprintf('  AR(1)            : p = %.4f, %s\n', pAr, ...
        matlibre_essai_verdict(rejetAr));
assert(~rejetMarche, 'la marche au hasard a bien une racine unitaire');
assert(rejetAr, 'l''AR(1) stable n''en a pas');

% Le test KPSS pose l'hypothèse inverse : la nulle est la stationnarité.
% Deux tests de sens contraires valent mieux qu'un seul, car ne pas
% rejeter n'est pas accepter.
[rejetKpssMarche, pKpssMarche] = kpsstest(marche);
[rejetKpssAr, pKpssAr] = kpsstest(autoregressif);
fprintf('\nTest KPSS (H0 : stationnarite) :\n');
fprintf('  marche au hasard : p = %.4f, %s\n', pKpssMarche, ...
        matlibre_essai_verdict(rejetKpssMarche));
fprintf('  AR(1)            : p = %.4f, %s\n', pKpssAr, ...
        matlibre_essai_verdict(rejetKpssAr));
assert(rejetKpssMarche, 'KPSS doit rejeter la stationnarite de la marche');

% Différencier une marche au hasard la rend stationnaire : c'est ce que
% « intégrée d'ordre un » veut dire.
differencee = diff(marche);
[rejetDiff, pDiff] = adftest(differencee);
fprintf('  marche differenciee : p = %.4f, %s\n', pDiff, ...
        matlibre_essai_verdict(rejetDiff));
assert(rejetDiff, 'une fois differenciee, la marche est stationnaire');

%% 2. La mémoire d'une série
% L'autocorrélation dit à quel point le passé prédit le présent.
[correlations, decalages, seuils] = autocorr(autoregressif, 20);
fprintf('\nAutocorrelation de l''AR(1) :\n');
fprintf('  aux retards 0 a 4 : %s\n', mat2str(round(correlations(1:5)', 4)));
assert(abs(correlations(1) - 1) < 1e-12, 'elle vaut un au retard nul');
% Pour un AR(1) de coefficient phi, elle vaut phi^k : c'est sa signature.
attendues = 0.7 .^ (0:4);
fprintf('  attendues 0.7^k   : %s\n', mat2str(round(attendues, 4)));
assert(max(abs(correlations(1:5)' - attendues)) < 0.1);
% Le bruit blanc, lui, n'a pas de memoire.
correlationsBruit = autocorr(bruitBlanc, 20);
horsSeuil = sum(abs(correlationsBruit(2:end)) > seuils(1));
fprintf('  bruit blanc : %d autocorrelations hors seuil sur 20\n', horsSeuil);
assert(horsSeuil <= 3, 'un bruit blanc n''a presque pas d''autocorrelation');

% L'autocorrélation partielle isole l'effet propre de chaque retard. Pour
% un AR(1) elle s'annule après le premier : c'est ainsi qu'on lit l'ordre.
partielles = parcorr(autoregressif, 10);
fprintf('  autocorrelation partielle aux retards 1 a 4 : %s\n', ...
        mat2str(round(partielles(2:5)', 4)));
assert(abs(partielles(2) - 0.7) < 0.1);
assert(max(abs(partielles(3:end))) < 0.15, ...
       'elle s''annule apres le premier retard pour un AR(1)');

% Le test de Ljung-Box teste d'un coup toutes les autocorrélations.
[rejetBruit, pBruit] = lbqtest(bruitBlanc);
[rejetAutre, pAutre] = lbqtest(autoregressif);
fprintf('\nTest de Ljung-Box (H0 : pas d''autocorrelation) :\n');
fprintf('  bruit blanc : p = %.4f, %s\n', pBruit, matlibre_essai_verdict(rejetBruit));
fprintf('  AR(1)       : p = %.4f, %s\n', pAutre, matlibre_essai_verdict(rejetAutre));
assert(~rejetBruit && rejetAutre);

%% 3. Estimer un modèle
% Retrouver les coefficients d'un ARMA depuis ses réalisations.
coefficients = arfit(autoregressif, 1);
fprintf('\nEstimation AR(1) : phi = %.4f (vrai 0.7)\n', coefficients(1));
assert(abs(coefficients(1) - 0.7) < 0.1);
% Choisir l'ordre : les critères pénalisent la richesse.
fprintf('\nChoix de l''ordre :\n');
criteres = zeros(1, 4);
for ordre = 1:4
    modele = arima(ordre, 0, 0);
    % La log-vraisemblance est le troisieme argument de sortie, comme
    % dans MATLAB ; l'affichage du modele ajuste la donne aussi.
    [~, ~, logL] = estimate(modele, autoregressif);
    [aic, bic] = aicbic(logL, ordre + 1, n);
    criteres(ordre) = bic;
    fprintf('  ordre %d : log-vraisemblance %.2f, AIC %.2f, BIC %.2f\n', ...
            ordre, logL, aic, bic);
end
[~, retenu] = min(criteres);
fprintf('  ordre retenu par le BIC : %d (vrai 1)\n', retenu);
assert(retenu == 1, 'le critere doit designer le vrai ordre');

%% 4. Simuler et prévoir
modele = arima(1, 0, 0);
ajuste = estimate(modele, autoregressif);
assert(abs(ajuste.AR{1} - 0.7) < 0.1, 'le coefficient estime doit approcher 0.7');
rng(9);
simulee = simulate(ajuste, 200);
fprintf('\nSimulation de %d points :\n', numel(simulee));
fprintf('  ecart type simule %.4f, observe %.4f\n', std(simulee), std(autoregressif));
assert(abs(std(simulee) / std(autoregressif) - 1) < 0.35);
prevision = forecast(ajuste, 10, autoregressif);
fprintf('  prevision a 10 pas : %s\n', mat2str(round(prevision(1:5)', 4)));
% Une prevision d'AR(1) decroit geometriquement vers la moyenne : c'est
% la seule chose que le modele sache dire au-dela de quelques pas.
assert(all(abs(diff(abs(prevision))) < abs(prevision(1))), ...
       'la prevision converge vers la moyenne');
assert(abs(prevision(end)) < abs(prevision(1)));

%% 5. La volatilité qui s'agglutine
% Sur les marchés, les grandes variations suivent les grandes : la
% volatilité a de la mémoire même quand le rendement n'en a pas. Un
% modèle GARCH décrit exactement cela.
% Les coefficients decident de la force de l'agglutination : pour un
% GARCH(1,1) l'autocorrelation des carres au retard un vaut
%   a (1 - a b - b^2) / (1 - 2 a b - b^2)
% soit environ 0.49 pour a = 0.3 et b = 0.6.
rng(4);
nGarch = 1500;
alpha = 0.3;
beta = 0.6;
variance = ones(nGarch, 1);
rendements = zeros(nGarch, 1);
for k = 2:nGarch
    variance(k) = 0.01 + alpha * rendements(k - 1) ^ 2 + beta * variance(k - 1);
    rendements(k) = sqrt(variance(k)) * randn;
end
attenduCarres = alpha * (1 - alpha * beta - beta ^ 2) ...
                / (1 - 2 * alpha * beta - beta ^ 2);
fprintf('\nSerie a volatilite variable :\n');
fprintf('  autocorrelation des rendements au retard 1 : %.4f\n', ...
        matlibre_essai_correlation(rendements, 1));
fprintf('  autocorrelation des carres au retard 1     : %.4f (theorie %.4f)\n', ...
        matlibre_essai_correlation(rendements .^ 2, 1), attenduCarres);
assert(abs(matlibre_essai_correlation(rendements, 1)) < 0.15, ...
       'les rendements ne sont pas correles');
assert(matlibre_essai_correlation(rendements .^ 2, 1) > 0.2, ...
       'leurs carres, si : c''est l''agglutination de la volatilite');
% Le test ARCH le confirme.
[rejetArch, pArch] = archtest(rendements);
fprintf('  test ARCH : p = %.4g, %s\n', pArch, matlibre_essai_verdict(rejetArch));
assert(rejetArch, 'le test doit deceler l''heteroscedasticite');

%% 6. Prix et rendements
% Deux façons de regarder la même série, et la conversion entre elles.
prix = 100 * cumprod(1 + 0.01 * randn(200, 1));
variationsRelatives = price2ret(prix);
refaits = ret2price(variationsRelatives, prix(1));
fprintf('\nPrix et rendements :\n');
fprintf('  %d prix -> %d rendements -> %d prix\n', ...
        numel(prix), numel(variationsRelatives), numel(refaits));
fprintf('  ecart de l''aller-retour : %.3e\n', max(abs(refaits(:) - prix(:))));
assert(max(abs(refaits(:) - prix(:))) < 1e-9, ...
       'la conversion doit etre exactement reversible');

fprintf('\nToutes les verifications passent.\n');

function texte = matlibre_essai_verdict(rejet)
    if rejet
        texte = 'H0 rejetee';
    else
        texte = 'H0 non rejetee';
    end
end

function r = matlibre_essai_correlation(x, retard)
    x = x(:) - mean(x);
    r = sum(x(1 + retard:end) .* x(1:end - retard)) / sum(x .^ 2);
end
