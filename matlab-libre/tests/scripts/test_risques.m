% test_risques.m — capital réglementaire, concentration, matrices de
% transition, modèle de Merton, portefeuilles de crédit, contrôle a
% posteriori et grilles de score.
%
% Chaque vérification confronte une fonction à ce qui la définit : un
% indice qui atteint son minimum quand tout est égal, une matrice de
% transition retrouvée sur des migrations simulées, les deux équations de
% Merton satisfaites à l'optimum, une aire sous la courbe mesurée par
% comparaison de paires.
disp('--- gestion des risques ---');

% ASRF : le capital croit avec la probabilite de defaut, la perte en cas
% de defaut et la correlation.
c = asrf(0.01, 0.45, 0.2);
fprintf('capital ASRF : %.6f\n', c);
assert(c > 0 && c < 0.45);
assert(asrf(0.02, 0.45, 0.2) > c);
assert(asrf(0.01, 0.9, 0.2) > c);
assert(asrf(0.01, 0.45, 0.4) > c);
% Sans correlation, le capital est nul : le portefeuille est parfaitement
% diversifie et il ne reste que la perte attendue, deja provisionnee.
assert(abs(asrf(0.01, 0.45, 0)) < 1e-12);
% Avec une correlation de un, la perte conditionnelle est totale.
assert(abs(asrf(0.01, 0.45, 1 - 1e-12) - 0.45 * (1 - 0.01)) < 1e-6);
% La formule de Bale decroit avec la probabilite de defaut.
cFaible = asrf(0.001, 0.45, [], 'CorrelationType', 'basel');
cForte = asrf(0.1, 0.45, [], 'CorrelationType', 'basel');
fprintf('Bale : PD=0.1%% -> %.6f, PD=10%% -> %.6f\n', cFaible, cForte);
assert(cForte > cFaible);
% L'exposition multiplie.
assert(abs(asrf(0.01, 0.45, 0.2, 'EAD', 1000) - 1000 * c) < 1e-9);
% Concentration : parts egales donnent le minimum, une seule le maximum.
egal = concentrationIndices([100 100 100 100]);
seul = concentrationIndices([400 0 0 0]);
fprintf('egal : HH=%.4f Gini=%.4f HT=%.4f TE=%.4f CR=%.4f\n', ...
        egal.HH, egal.Gini, egal.HT, egal.TE, egal.CR);
fprintf('seul : HH=%.4f Gini=%.4f HT=%.4f TE=%.4f CR=%.4f\n', ...
        seul.HH, seul.Gini, seul.HT, seul.TE, seul.CR);
assert(abs(egal.HH) < 1e-12 && abs(seul.HH - 1) < 1e-12);
assert(abs(egal.Gini) < 1e-12 && abs(seul.Gini - 1) < 1e-12);
assert(abs(egal.HT) < 1e-12 && abs(seul.HT - 1) < 1e-12);
assert(abs(egal.TE) < 1e-12 && abs(seul.TE - 1) < 1e-12);
assert(abs(egal.CR - 0.25) < 1e-12 && abs(seul.CR - 1) < 1e-12);
% Un portefeuille intermediaire tombe entre les deux.
milieu = concentrationIndices([200 100 60 40]);
fprintf('milieu : HH=%.4f Gini=%.4f HT=%.4f TE=%.4f\n', ...
        milieu.HH, milieu.Gini, milieu.HT, milieu.TE);
for champ = {'HH', 'Gini', 'HT', 'TE', 'CR'}
    assert(milieu.(champ{1}) > egal.(champ{1}) - 1e-12);
    assert(milieu.(champ{1}) < seul.(champ{1}) + 1e-12);
end
% A l'ordre deux, Hannah et Kay redonne la somme des carres des parts.
brut = concentrationIndices([200 100 60 40], 'ScaleIndices', false);
parts = [200 100 60 40] / 400;
fprintf('HK ordre 2 : %.6f, somme des carres : %.6f\n', brut.HK, sum(parts .^ 2));
assert(abs(brut.HK - sum(parts .^ 2)) < 1e-12);
assert(abs(brut.HH - sum(parts .^ 2)) < 1e-12);
% La part des deux plus grosses.
deux = concentrationIndices([200 100 60 40], 'CRIndex', 2);
assert(abs(deux.CR - 0.75) < 1e-12);
% Les deciles croissent jusqu'a un.
[~, d] = concentrationIndices(rand(100, 1));
assert(all(diff(d) >= -1e-12) && abs(d(end) - 1) < 1e-12);

%% ------------------------------------------ matrices de transition
% Seuils : l'aller-retour rend la matrice de depart.
P = [0.90 0.08 0.02; 0.05 0.90 0.05; 0 0 1];
S = transprobtothresholds(P);
fprintf('seuils :\n'); disp(round(S, 4));
assert(all(isinf(S(:, 1))) && all(S(:, 1) > 0));
Q = transprobfromthresholds(S);
fprintf('ecart apres aller-retour : %.3e\n', max(max(abs(Q - P))));
assert(max(max(abs(Q - P))) < 1e-12);
% Les seuils decroissent le long d'une ligne : les notations sont rangees
% de la meilleure a la pire. La derniere ligne est absorbante et ne porte
% que des infinis, la variable ne pouvant en sortir.
assert(all(all(diff(S(1:2, 2:end), 1, 2) < 0)));
assert(all(isinf(S(3, :))));
% Une matrice de transition estimee sur des migrations simulees retrouve
% celle qui a servi a les engendrer.
rng(101);
n = 4000;
annees = 6;
donnees = zeros(n * annees, 3);
ligne = 0;
for e = 1:n
    etat = 1 + (rand < 0.5);
    for annee = 0:(annees - 1)
        ligne = ligne + 1;
        donnees(ligne, :) = [e, datenum(2015 + annee, 1, 1), etat];
        cumul = cumsum(P(etat, :));
        etat = find(rand <= cumul, 1);
    end
end
[estimee, totaux] = transprob(donnees);
fprintf('estimee :\n'); disp(round(estimee, 4));
fprintf('vraie   :\n'); disp(P);
assert(max(max(abs(estimee - P))) < 0.02);
% Les lignes somment a un.
assert(max(abs(sum(estimee, 2) - 1)) < 1e-12);
% transprobbytotals retrouve la meme matrice depuis les comptages.
assert(max(max(abs(transprobbytotals(totaux) - estimee))) < 1e-12);
% Deux jeux de comptages s'additionnent.
double_ = transprobbytotals([totaux; totaux]);
assert(max(max(abs(double_ - estimee))) < 1e-12);
% L'algorithme par duree donne une matrice stochastique proche.
duree = transprob(donnees, 'algorithm', 'duration');
fprintf('par duree :\n'); disp(round(duree, 4));
assert(max(abs(sum(duree, 2) - 1)) < 1e-10);
assert(all(all(duree >= 0)));
assert(max(max(abs(duree - P))) < 0.06);
% Sur deux ans, la matrice par duree est le carre de celle sur un an.
deuxAns = transprob(donnees, 'algorithm', 'duration', 'transInterval', 2);
fprintf('ecart avec le carre : %.3e\n', max(max(abs(deuxAns - duree * duree))));
assert(max(max(abs(deuxAns - duree * duree))) < 1e-9);
% L'etat absorbant le reste.
assert(abs(duree(3, 3) - 1) < 1e-9);

%% ---------------------------------------------- modele de Merton
% Merton : les deux equations sont satisfaites a l'optimum.
E = 50; sigmaE = 0.4; L = 40; r = 0.03; T = 1;
[pd, dd, A, sA] = mertonmodel(E, sigmaE, L, r, T);
fprintf('actif %.6f, volatilite %.6f, DD %.6f, PD %.6f\n', A, sA, dd, pd);
% Premiere equation : les capitaux propres sont l'option d'achat.
appel = blsprice(A, L, r, T, sA);
fprintf('capitaux propres calcules %.8f, donnes %.8f\n', appel, E);
assert(abs(appel - E) < 1e-8);
% Seconde equation : la volatilite des capitaux propres.
delta = blsdelta(A, L, r, T, sA);
fprintf('sigmaE calcule %.8f, donne %.8f\n', delta * A * sA / E, sigmaE);
assert(abs(delta * A * sA / E - sigmaE) < 1e-8);
% La probabilite de defaut est la queue normale de la distance au defaut.
assert(abs(pd - normcdf(-dd)) < 1e-15);
% Plus la dette est lourde, plus le defaut est probable.
pdLourd = mertonmodel(50, 0.4, 80, 0.03, 1);
fprintf('PD a dette 40 : %.6f ; a dette 80 : %.6f\n', pd, pdLourd);
assert(pdLourd > pd);
% Plus l'entreprise est volatile, plus le defaut est probable quand elle
% est endettee.
pdVolatil = mertonmodel(50, 0.8, 80, 0.03, 1);
assert(pdVolatil > pdLourd);
% Une entreprise sans dette ne fait pas defaut.
pdSansDette = mertonmodel(50, 0.4, 1e-8, 0.03, 1);
fprintf('PD sans dette : %.3e\n', pdSansDette);
assert(pdSansDette < 1e-6);
% Plusieurs entreprises d'un coup.
pdVecteur = mertonmodel([50; 50], [0.4; 0.8], [40; 80], 0.03, 1);
assert(abs(pdVecteur(1) - pd) < 1e-12 && abs(pdVecteur(2) - pdVolatil) < 1e-12);
% Sur une serie : la volatilite d'actif retrouvee est proche de celle qui
% a servi a simuler.
rng(5);
n = 500; vraieSigma = 0.25; dette = 60; r = 0.03; T = 1;
actifs = 100 * exp(cumsum(vraieSigma / sqrt(252) * randn(n, 1) - vraieSigma^2/(2*252)));
capitaux = zeros(n, 1);
for t = 1:n
    capitaux(t) = blsprice(actifs(t), dette, r, T, vraieSigma);
end
[pdSerie, ddSerie, aSerie, sigmaSerie] = mertonByTimeSeries(capitaux, dette, r, T);
fprintf('volatilite retrouvee %.6f (vraie %.4f)\n', sigmaSerie, vraieSigma);
assert(abs(sigmaSerie - vraieSigma) < 0.02);
fprintf('actif retrouve %.4f (vrai %.4f)\n', aSerie(end), actifs(end));
assert(abs(aSerie(end) / actifs(end) - 1) < 0.01);
assert(abs(pdSerie - normcdf(-ddSerie)) < 1e-15);

%% --------------------------------------------- copule de defaut
rng(31);
% Un portefeuille de trois contreparties, un facteur commun.
pd = [0.02; 0.05; 0.01];
lgd = [0.4; 0.6; 0.5];
ead = [100; 200; 300];
rho = 0.3;
poids = repmat([sqrt(rho), sqrt(1 - rho)], 3, 1);
c = creditDefaultCopula(pd, lgd, ead, poids, 'VaRLevel', 0.99);
c = simulate(c, 100000);
% La perte attendue vaut la somme des PD fois LGD fois EAD : elle ne
% depend pas de la correlation.
attendue = sum(pd .* lgd .* ead);
r = portfolioRisk(c);
fprintf('perte attendue simulee %.4f, theorique %.4f\n', r.EL, attendue);
% Les pertes arrivent groupees : l'ecart type d'une estimation sur cent
% mille scenarios avoisine 1,5 % de la perte attendue, d'ou une tolerance
% qui en vaut trois.
assert(abs(r.EL / attendue - 1) < 0.05);
% La frequence de defaut de chaque contrepartie retrouve sa PD.
defauts = mean(getScenarios(c) > 0, 1)';
fprintf('frequences : %s\n', sprintf('%9.5f', defauts));
fprintf('PD         : %s\n', sprintf('%9.5f', pd));
assert(max(abs(defauts - pd) ./ pd) < 0.09);
% La correlation des indicatrices de defaut suit celle du modele.
scenarios = getScenarios(c) > 0;
correlationObservee = corr(double(scenarios(:, 1)), double(scenarios(:, 3)));
% Correlation theorique des defauts : la copule gaussienne donne la
% probabilite jointe par la normale bivariee ; on la mesure ici par
% simulation directe des latentes.
seuils = norminv(pd);
z = randn(200000, 1) * sqrt(rho);
a1 = z + randn(200000, 1) * sqrt(1 - rho);
a3 = z + randn(200000, 1) * sqrt(1 - rho);
d1 = a1 < seuils(1); d3 = a3 < seuils(3);
correlationTheorique = corr(double(d1), double(d3));
fprintf('correlation des defauts : observee %.5f, theorique %.5f\n', ...
        correlationObservee, correlationTheorique);
assert(abs(correlationObservee - correlationTheorique) < 0.03);
% Sans correlation, les defauts sont independants.
independant = creditDefaultCopula(pd, lgd, ead, [zeros(3,1), ones(3,1)], ...
                                  'VaRLevel', 0.99);
independant = simulate(independant, 100000);
sc = getScenarios(independant) > 0;
fprintf('correlation sans facteur : %.5f\n', corr(double(sc(:,1)), double(sc(:,3))));
assert(abs(corr(double(sc(:,1)), double(sc(:,3)))) < 0.02);
% La correlation epaissit la queue : meme perte attendue, mais des
% pertes extremes plus lourdes. Avec trois contreparties la loi des
% pertes est tres discrete, si bien que le quantile lui-meme peut ne pas
% bouger ; c'est la perte moyenne au-dela qui le montre.
rIndependant = portfolioRisk(independant);
fprintf('EL : %.2f contre %.2f ; CVaR : %.2f contre %.2f\n', ...
        r.EL, rIndependant.EL, r.CVaR, rIndependant.CVaR);
assert(abs(r.EL - rIndependant.EL) / r.EL < 0.07);
assert(r.CVaR > rIndependant.CVaR);
assert(r.CVaR > r.VaR - 1e-9);
% La probabilite que les trois fassent defaut ensemble est bien plus
% grande avec correlation qu'a independance.
troisEnsemble = mean(all(getScenarios(c) > 0, 2));
troisSeuls = mean(all(getScenarios(independant) > 0, 2));
fprintf('trois defauts ensemble : %.6f contre %.6f (produit %.3e)\n', ...
        troisEnsemble, troisSeuls, prod(pd));
assert(troisEnsemble > 5 * prod(pd));
assert(troisSeuls < 5 * prod(pd));
% Les contributions somment aux totaux.
[parts, totaux] = riskContribution(c);
fprintf('somme des EL %.4f, total %.4f\n', sum(parts.EL), totaux.EL);
assert(abs(sum(parts.EL) - totaux.EL) < 1e-9);
assert(abs(sum(parts.Std) - totaux.Std) / totaux.Std < 1e-9);
assert(abs(sum(parts.VaR) - totaux.VaR) / totaux.VaR < 1e-9);
assert(abs(sum(parts.CVaR) - totaux.CVaR) / totaux.CVaR < 1e-9);
% La contribution d'une contrepartie ne depasse pas son exposition.
assert(all(parts.EL <= lgd .* ead + 1e-9));
% L'ancienne forme de riskContribution marche toujours.
[contributions, risqueTotal] = riskContribution([0.5 0.5], [0.04 0.01; 0.01 0.09]);
assert(abs(sum(contributions) - risqueTotal) < 1e-12);
% Les bandes de confiance se resserrent.
[bandes, nombres] = confidenceBands(c, 'RiskMeasure', 'EL', 'NumPoints', 20);
largeurs = bandes(:, 3) - bandes(:, 1);
fprintf('largeur des bandes : de %.4f a %.4f\n', largeurs(1), largeurs(end));
assert(largeurs(end) < largeurs(1) / 3);
assert(all(bandes(:, 1) <= bandes(:, 2)) && all(bandes(:, 2) <= bandes(:, 3)));
% Et l'estimation finale est celle de portfolioRisk.
assert(abs(bandes(end, 2) - r.EL) < 1e-9);
% La copule de Student groupe davantage les defauts.
tCopule = simulate(creditDefaultCopula(pd, lgd, ead, poids, 'VaRLevel', 0.99), ...
                   100000, 'Copula', 't', 'DegreesOfFreedom', 3);
rT = portfolioRisk(tCopule);
fprintf('CVaR gaussienne %.2f, Student %.2f\n', r.CVaR, rT.CVaR);
assert(rT.CVaR > r.CVaR);
% Les probabilites de defaut marginales sont conservees.
frequencesT = mean(getScenarios(tCopule) > 0, 1)';
fprintf('frequences Student : %s\n', sprintf('%9.5f', frequencesT));
assert(max(abs(frequencesT - pd) ./ pd) < 0.12);
% Mais les defauts groupes sont bien plus frequents.
troisStudent = mean(all(getScenarios(tCopule) > 0, 2));
fprintf('trois defauts ensemble, Student : %.6f\n', troisStudent);
assert(troisStudent > troisEnsemble);

%% ------------------------------------------ copule de migration
rng(19);
% Trois notations : bonne, moyenne, defaut.
P = [0.94 0.05 0.01; 0.10 0.85 0.05; 0 0 1];
valeurs = [100 96 40; 100 96 40; 100 96 40; 100 96 40];
notations = [1; 1; 2; 2];
lgd = [0.6; 0.6; 0.6; 0.6];
rho = 0.25;
poids = repmat([sqrt(rho), sqrt(1 - rho)], 4, 1);
c = creditMigrationCopula(valeurs, notations, P, lgd, poids, 'VaRLevel', 0.99);
c = simulate(c, 100000);
% Les frequences de migration retrouvent la matrice de transition.
pertesParPosition = getScenarios(c);
% Position 1 : partie de la notation 1. Perte nulle si elle y reste,
% 4 si elle tombe en 2, 100 - 40*0.4 = 84 en defaut.
perte1 = pertesParPosition(:, 1);
freqReste = mean(abs(perte1) < 1e-9);
freqBaisse = mean(abs(perte1 - 4) < 1e-9);
freqDefaut = mean(abs(perte1 - (100 - 40 * 0.4)) < 1e-9);
fprintf('depuis la notation 1 : %.5f %.5f %.5f\n', freqReste, freqBaisse, freqDefaut);
fprintf('matrice              : %.5f %.5f %.5f\n', P(1, 1), P(1, 2), P(1, 3));
assert(max(abs([freqReste freqBaisse freqDefaut] - P(1, :))) < 0.008);
% Position 3 : partie de la notation 2, elle peut monter.
perte3 = pertesParPosition(:, 3);
freqMonte = mean(abs(perte3 - (96 - 100)) < 1e-9);
freqReste3 = mean(abs(perte3) < 1e-9);
freqDefaut3 = mean(abs(perte3 - (96 - 40 * 0.4)) < 1e-9);
fprintf('depuis la notation 2 : %.5f %.5f %.5f\n', freqMonte, freqReste3, freqDefaut3);
assert(max(abs([freqMonte freqReste3 freqDefaut3] - P(2, :))) < 0.008);
% Une amelioration de notation est un gain : la perte est negative.
assert(min(perte3) < 0);
% La perte attendue du portefeuille est la somme des pertes attendues.
r = portfolioRisk(c);
attendue = 0;
for i = 1:4
    depart = notations(i);
    v = valeurs(i, :); v(3) = v(3) * (1 - lgd(i));
    attendue = attendue + sum(P(depart, :) .* (valeurs(i, depart) - v));
end
fprintf('perte attendue simulee %.5f, theorique %.5f\n', r.EL, attendue);
assert(abs(r.EL - attendue) < 0.5);
% Les contributions somment aux totaux.
[parts, totaux] = riskContribution(c);
assert(abs(sum(parts.EL) - totaux.EL) < 1e-9);
assert(abs(sum(parts.CVaR) - totaux.CVaR) / abs(totaux.CVaR) < 1e-9);
% Sans correlation, la queue est plus mince.
sansFacteur = simulate(creditMigrationCopula(valeurs, notations, P, lgd, ...
    [zeros(4,1), ones(4,1)], 'VaRLevel', 0.99), 100000);
rSans = portfolioRisk(sansFacteur);
fprintf('CVaR avec correlation %.4f, sans %.4f\n', r.CVaR, rSans.CVaR);
assert(r.CVaR > rSans.CVaR);
% La perte attendue, elle, ne depend pas de la correlation. Les pertes
% valant 84 avec une chance sur cent, l'ecart type d'une estimation sur
% deux cent mille scenarios avoisine le dixieme : les tolerances qui
% suivent en valent trois.
fprintf('EL avec correlation %.5f, sans %.5f, theorique %.5f\n', ...
        r.EL, rSans.EL, attendue);
assert(abs(r.EL - rSans.EL) < 0.6);
assert(abs(rSans.EL - attendue) < 0.5);

%% ------------------------------------------ controle a posteriori
rng(23);
n = 1000; niveau = 0.99; p = 1 - niveau;
seuil = -norminv(p);
% Un test se juge sur sa taille et sa puissance, non sur un tirage : on
% repete l'experience.
fauxRejets = 0; vusOptimiste = 0;
for essai = 1:40
    X = randn(n, 1);
    VaR = repmat(seuil, n, 1);
    if strcmp(pof(varbacktest(X, VaR, 'VaRLevel', niveau)).TestResult, 'reject')
        fauxRejets = fauxRejets + 1;
    end
    if strcmp(pof(varbacktest(X, VaR / 2, 'VaRLevel', niveau)).TestResult, 'reject')
        vusOptimiste = vusOptimiste + 1;
    end
end
fprintf('Kupiec : %d faux rejets, %d modeles optimistes vus (sur 40)\n', ...
        fauxRejets, vusOptimiste);
assert(fauxRejets <= 8 && vusOptimiste == 40);
% Le feu tricolore vire au rouge quand la VaR est trop basse.
rng(23);
X = randn(n, 1);
VaR = repmat(seuil, n, 1);
v = varbacktest(X, VaR, 'VaRLevel', niveau);
mauvais = varbacktest(X, VaR / 2, 'VaRLevel', niveau);
fprintf('feu du modele juste : %s ; du modele optimiste : %s\n', ...
        tl(v).TL, tl(mauvais).TL);
assert(strcmp(tl(mauvais).TL, 'red'));
assert(tl(mauvais).Increase > tl(v).Increase - 1e-12);
% Un modele deux fois trop prudent ne depasse jamais.
prudent = varbacktest(X, VaR * 2, 'VaRLevel', niveau);
fprintf('modele prudent : %d depassements\n', summary(prudent).Failures);
assert(summary(prudent).Failures == 0);
% Le resume compte ce qu'il faut.
s = summary(v);
fprintf('%d observations, %d depassements, attendus %.1f\n', s.N, s.Failures, s.Expected);
assert(s.N == n && abs(s.Expected - n * p) < 1e-12);
assert(abs(s.ObservedLevel - (1 - s.Failures / n)) < 1e-15);
% Identite : la couverture conditionnelle est la somme de ses deux morceaux.
assert(abs(cc(v).LRatio - (pof(v).LRatio + cci(v).LRatio)) < 1e-12);
% Et les temps entre depassements contiennent la proportion.
assert(abs(tbf(v).LRatio - (pof(v).LRatio + tbfi(v).LRatio)) < 1e-12);
% Le carre de la statistique binomiale approche celle de Kupiec : les deux
% mesurent le meme ecart, l'une par une normale, l'autre par un rapport de
% vraisemblance.
fprintf('binomial z^2 = %.4f, Kupiec LR = %.4f\n', ...
        bin(v).TestStatistic ^ 2, pof(v).LRatio);
assert(abs(bin(v).TestStatistic ^ 2 - pof(v).LRatio) < 1.5);
% Des depassements groupes sont rejetes par l'independance, alors que leur
% nombre seul ne le serait pas.
groupe = randn(n, 1);
groupe(200:209) = -5;
groupeModele = varbacktest(groupe, VaR, 'VaRLevel', niveau);
fprintf('groupes : %d depassements, cci %s\n', ...
        summary(groupeModele).Failures, cci(groupeModele).TestResult);
assert(strcmp(cci(groupeModele).TestResult, 'reject'));
% RUNTESTS passe les huit tests.
r = runtests(v);
assert(numel(r) == 8);
for k = 1:numel(r)
    assert(isfield(r{k}, 'Test'));
end
% Perte moyenne au-dela : un modele juste passe, un modele qui la
% sous-estime est rejete.
ES = repmat(exp(-norminv(p) ^ 2 / 2) / (p * sqrt(2 * pi)), n, 1);
fauxRejetsES = 0; vusES = 0;
for essai = 1:20
    Y = randn(n, 1);
    if strcmp(unconditionalNormal(esbacktest(Y, VaR, ES, 'VaRLevel', niveau)).TestResult, 'reject')
        fauxRejetsES = fauxRejetsES + 1;
    end
    if strcmp(unconditionalNormal(esbacktest(Y, VaR, ES / 3, 'VaRLevel', niveau)).TestResult, 'reject')
        vusES = vusES + 1;
    end
end
fprintf('Acerbi-Szekely : %d faux rejets, %d sous-estimations vues (sur 20)\n', ...
        fauxRejetsES, vusES);
assert(fauxRejetsES <= 5 && vusES >= 18);
% La statistique vaut zero en moyenne quand le modele dit vrai.
moyenne = 0;
for essai = 1:50
    Y = randn(n, 1);
    moyenne = moyenne + unconditionalNormal(esbacktest(Y, VaR, ES, 'VaRLevel', niveau)).ZScore;
end
moyenne = moyenne / 50;
fprintf('Z moyen sous l''hypothese nulle : %.5f\n', moyenne);
assert(abs(moyenne) < 0.1);
% La valeur critique est reproductible : la loi simulee est mise en cache
% a graine fixee.
e = esbacktest(randn(n, 1), VaR, ES, 'VaRLevel', niveau);
assert(unconditionalNormal(e).CriticalValue == unconditionalNormal(e).CriticalValue);
assert(unconditionalNormal(e).CriticalValue < 0);
% Les deux lois donnent des valeurs critiques differentes.
fprintf('critique gaussienne %.5f, Student %.5f\n', ...
        unconditionalNormal(e).CriticalValue, unconditionalT(e).CriticalValue);
assert(unconditionalT(e).CriticalValue ~= unconditionalNormal(e).CriticalValue);

%% --------------------------------------------- glmfit et glmval
rng(1);
X = randn(300, 2);
p = 1 ./ (1 + exp(-(0.5 + 2 * X(:,1) - 1.5 * X(:,2))));
y = double(rand(300, 1) < p);
b = glmfit(X, y, 'binomial');
fprintf('coefficients : %s (vrais [0.5 2 -1.5])\n', mat2str(round(b', 3)));
assert(abs(b(1) - 0.5) < 0.4 && abs(b(2) - 2) < 0.5 && abs(b(3) + 1.5) < 0.5);
% glmval retrouve les valeurs ajustees de fitglm.
m = fitglm(X, y, 'Distribution', 'binomial');
predictions = glmval(b, X, 'logit');
fprintf('ecart avec fitglm : %.3e\n', max(abs(predictions - m.Fitted(:))));
assert(max(abs(predictions - m.Fitted(:))) < 1e-10);
assert(all(predictions > 0) && all(predictions < 1));
% Regression de Poisson.
lambda = exp(0.3 + 0.8 * X(:,1));
compte = poissrnd(lambda);
bp = glmfit(X(:,1), compte, 'poisson');
fprintf('poisson : %s (vrais [0.3 0.8])\n', mat2str(round(bp', 3)));
assert(abs(bp(1) - 0.3) < 0.2 && abs(bp(2) - 0.8) < 0.2);
assert(max(abs(glmval(bp, X(:,1), 'log') - exp(bp(1) + bp(2) * X(:,1)))) < 1e-12);

%% ------------------------------------------------ grille de score
rng(42);
n = 2000;
% Trois caracteristiques, dont deux qui comptent.
revenu = 20000 + 40000 * rand(n, 1);
age = round(20 + 45 * rand(n, 1));
bruit = randn(n, 1);
categories = {'A', 'B', 'C'};
region = categories(1 + floor(3 * rand(n, 1)))';
lineaire = -1 + 3 * (revenu - 40000) / 20000 + 1.5 * (age - 42) / 20;
probaBon = 1 ./ (1 + exp(-lineaire));
defaut = double(rand(n, 1) > probaBon);      % 1 = defaut, 0 = bon
donnees = struct('id', (1:n)', 'revenu', revenu, 'age', age, ...
                 'bruit', bruit, 'region', {region}, 'defaut', defaut);
sc = creditscorecard(donnees, 'IDVar', 'id', 'ResponseVar', 'defaut', ...
                     'GoodLabel', 0);
fprintf('caracteristiques : %s\n', strjoin(sc.PredictorVars, ', '));
assert(numel(sc.PredictorVars) == 4);
sc = autobinning(sc);
% Le poids de la preuve croit avec le revenu : plus il est eleve, plus la
% tranche contient de bons dossiers.
[info, iv] = bininfo(sc, 'revenu');
fprintf('revenu : %d tranches, valeur d''information %.4f\n', numel(info.WOE), iv);
fprintf('  poids : %s\n', sprintf('%8.4f', info.WOE));
assert(all(diff(info.WOE) > 0));
assert(iv > 0.5);
% Les bons et les mauvais somment au total.
assert(abs(sum(info.Good) + sum(info.Bad) - n) < 1e-9);
% Une caracteristique sans rapport a une valeur d'information faible.
[~, ivBruit] = bininfo(sc, 'bruit');
[~, ivRegion] = bininfo(sc, 'region');
fprintf('bruit %.4f, region %.4f\n', ivBruit, ivRegion);
assert(ivBruit < 0.05 && ivRegion < 0.05);
% La region est decoupee par categorie.
infoRegion = bininfo(sc, 'region');
assert(numel(infoRegion.Bin) == 3);
% bindata rend les numeros de tranche, puis les poids.
numeros = bindata(sc);
assert(all(numeros.revenu >= 1) && all(numeros.revenu <= numel(info.WOE)));
poids = bindata(sc, [], 'OutputType', 'WOEModelInput');
assert(max(abs(unique(poids.revenu) - sort(info.WOE))) < 1e-12);
% Ajustement : le coefficient de chaque caracteristique utile avoisine un.
[sc, modele] = fitmodel(sc, 'Display', 'off');
fprintf('coefficients : %s\n', mat2str(round(sc.ModelCoefficients', 3)));
rangRevenu = find(strcmp(sc.ModelVars, 'revenu'));
assert(abs(sc.ModelCoefficients(rangRevenu + 1) - 1) < 0.3);
% La selection pas a pas ecarte le bruit.
scNeuf = autobinning(creditscorecard(donnees, 'IDVar', 'id', ...
                                     'ResponseVar', 'defaut', 'GoodLabel', 0));
scSelectif = fitmodel(scNeuf, 'VariableSelection', 'stepwise', 'Display', 'off');
fprintf('retenues : %s\n', strjoin(scSelectif.ModelVars, ', '));
assert(any(strcmp(scSelectif.ModelVars, 'revenu')));
assert(~any(strcmp(scSelectif.ModelVars, 'bruit')));
% Les points somment au score, et le score se convertit en probabilite.
sc = formatpoints(sc, 'PointsOddsAndPDO', [500 2 50]);
[scores, points] = score(sc);
assert(max(abs(sum(points, 2) - scores)) < 1e-9);
pd = probdefault(sc);
% Un score plus eleve donne une probabilite de defaut plus basse.
[~, ordre] = sort(scores);
assert(all(diff(pd(ordre)) <= 1e-12));
% Doubler tous les cinquante points : les cotes doublent.
cotes = (1 - pd) ./ pd;
[~, rangMin] = min(scores);
cible = scores(rangMin) + 50;
[~, rangProche] = min(abs(scores - cible));
rapport = cotes(rangProche) / cotes(rangMin);
fprintf('cotes a +%.1f points : rapport %.4f (attendu 2)\n', ...
        scores(rangProche) - scores(rangMin), rapport);
assert(abs(log(rapport) / log(2) - (scores(rangProche) - scores(rangMin)) / 50) < 1e-9);
% Le bareme couvre l'etendue des scores.
[bareme, bas, haut] = displaypoints(sc);
fprintf('bareme : %d lignes, scores de %.2f a %.2f\n', numel(bareme), bas, haut);
assert(bas <= min(scores) + 1e-9 && haut >= max(scores) - 1e-9);
% Le pouvoir discriminant est bon, et l'aire vaut ce que dit sa definition.
[stats, tableau] = validatemodel(sc);
fprintf('AUROC %.4f, Gini %.4f, KS %.4f\n', stats.AUROC, stats.Gini, stats.KS);
assert(stats.AUROC > 0.75 && stats.AUROC <= 1);
assert(abs(stats.Gini - (2 * stats.AUROC - 1)) < 1e-12);
% L'aire est la probabilite qu'un bon depasse un mauvais : on la mesure
% directement par comparaison de paires tirees au hasard.
bonsScores = scores(defaut == 0);
mauvaisScores = scores(defaut == 1);
tirages = 20000;
a = bonsScores(randi(numel(bonsScores), tirages, 1));
b = mauvaisScores(randi(numel(mauvaisScores), tirages, 1));
parPaires = (sum(a > b) + 0.5 * sum(a == b)) / tirages;
fprintf('aire par paires : %.4f\n', parPaires);
assert(abs(stats.AUROC - parPaires) < 0.02);
% L'echelle des points ne change ni les probabilites ni l'aire.
scAutre = formatpoints(sc, 'PointsOddsAndPDO', [700 5 20]);
assert(max(abs(probdefault(scAutre) - pd)) < 1e-10);
assert(abs(validatemodel(scAutre).AUROC - stats.AUROC) < 1e-12);

disp('gestion des risques : toutes les verifications passent');
