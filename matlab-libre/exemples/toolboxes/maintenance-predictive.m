%% Maintenance prédictive : mesurer l'usure, prédire la panne
% Une machine ne tombe pas en panne sans prévenir : elle vibre autrement.
% Toute la démarche consiste à extraire des descripteurs qui bougent avec
% l'usure, à les résumer en un indicateur de santé, puis à extrapoler.
%
% Voir aussi FAULTFEATURES, HEALTHINDICATOR, RULDEGRADATION, RULSIMILARITY.

fprintf('=== Maintenance predictive ===\n');

%% 1. Les descripteurs vibratoires
% Chacun répond à un défaut différent. Le kurtosis, en particulier, monte
% dès que des chocs apparaissent — c'est la signature d'un écaillage de
% roulement — alors que la valeur efficace peut à peine bouger.
rng(101);
fs = 10000;
n = 10000;
t = (0:n-1).' / fs;

% Une machine saine : du bruit et une raie de rotation.
saine = 0.5 * sin(2 * pi * 50 * t) + 0.05 * randn(n, 1);
dSaine = faultFeatures(saine, fs);
fprintf('\nMachine saine :\n');
fprintf('  efficace %.4f, crete %.4f, facteur de crete %.3f\n', ...
        dSaine.rms, dSaine.crete, dSaine.facteurCrete);
fprintf('  kurtosis %.3f, centroide %.1f Hz\n', dSaine.kurtosis, dSaine.centroide);
% Un signal proche du sinus a un kurtosis de 1.5 ; un bruit gaussien, de 3.
assert(dSaine.kurtosis > 1.4 && dSaine.kurtosis < 3.2, ...
       'sans choc, le kurtosis reste bas');
assert(abs(dSaine.rms - sqrt(0.5^2/2 + 0.05^2)) < 0.01, ...
       'la valeur efficace suit la puissance du signal');

% La même machine avec un roulement écaillé : des chocs périodiques
% brefs, de faible énergie, mais très pointus.
chocs = zeros(n, 1);
chocs(1:500:end) = 8;
impulsion = exp(-(0:299).' / 30) .* sin(2 * pi * 2500 * (0:299).' / fs);
malade = saine + conv(chocs, impulsion, 'same') * 0.4;
dMalade = faultFeatures(malade, fs);
fprintf('Machine avec chocs periodiques :\n');
fprintf('  efficace %.4f (+%.0f %%), kurtosis %.3f (x%.1f)\n', ...
        dMalade.rms, 100 * (dMalade.rms / dSaine.rms - 1), ...
        dMalade.kurtosis, dMalade.kurtosis / dSaine.kurtosis);
fprintf('  facteur de crete %.3f (contre %.3f), centroide %.1f Hz (contre %.1f)\n', ...
        dMalade.facteurCrete, dSaine.facteurCrete, ...
        dMalade.centroide, dSaine.centroide);
assert(dMalade.kurtosis > 4 * dSaine.kurtosis, ...
       'le kurtosis est le descripteur des chocs');
assert(dMalade.facteurCrete > dSaine.facteurCrete, ...
       'le facteur de crete monte lui aussi');
assert(dMalade.centroide > dSaine.centroide, ...
       'et le centroide monte : les chocs excitent les hautes frequences');
% Les deux descripteurs ne réagissent pas du tout à la même échelle : la
% valeur efficace gagne quelques dizaines de pour cent quand le kurtosis
% est multiplié par huit. C'est pourquoi surveiller la seule énergie
% laisse passer les défauts naissants, dont l'énergie est faible mais la
% forme très pointue.
fprintf('  efficace +%.0f %% seulement, quand le kurtosis fait +%.0f %%\n', ...
        100 * (dMalade.rms / dSaine.rms - 1), ...
        100 * (dMalade.kurtosis / dSaine.kurtosis - 1));
assert(dMalade.kurtosis / dSaine.kurtosis > 5 * (dMalade.rms / dSaine.rms), ...
       'le kurtosis reagit bien plus vivement que l''energie');

% Le centroïde spectral pointe où l'énergie se concentre. Sur un sinus
% pur, c'est la fréquence du sinus.
pur = sin(2 * pi * 1000 * t);
fprintf('  verification : sinus pur a 1000 Hz -> centroide %.1f Hz\n', ...
        faultFeatures(pur, fs).centroide);
assert(abs(faultFeatures(pur, fs).centroide - 1000) < 20, ...
       'le centroide d''un sinus pur est sa frequence');
% Et sur du bruit blanc, il tombe au milieu de la bande.
blanc = randn(n, 1);
assert(abs(faultFeatures(blanc, fs).centroide - fs/4) < fs/40, ...
       'le centroide d''un bruit blanc est au milieu de la bande');
% Le kurtosis d'un bruit gaussien vaut trois : c'est sa définition même.
fprintf('  bruit blanc gaussien : kurtosis %.3f (theorie : 3)\n', ...
        faultFeatures(blanc, fs).kurtosis);
assert(abs(faultFeatures(blanc, fs).kurtosis - 3) < 0.2, ...
       'le kurtosis d''une gaussienne vaut trois');

%% 2. L'indicateur de santé
% Plusieurs descripteurs, une seule courbe. L'analyse en composantes
% principales trouve la direction où ils varient le plus ensemble, et
% c'est celle qui suit la dégradation.
nCycles = 100;
cycles = (1:nCycles).';
usure = (cycles / nCycles) .^ 2;                  % degradation acceleree
rng(7);
descripteurs = [1 + 0.5 * usure + 0.02 * randn(nCycles, 1), ...
                3 + 4.0 * usure + 0.10 * randn(nCycles, 1), ...
                800 + 600 * usure + 20 * randn(nCycles, 1)];
sante = healthIndicator(descripteurs);
fprintf('\nIndicateur de sante sur %d cycles :\n', nCycles);
fprintf('  de %.4f au premier cycle a %.4f au dernier\n', sante(1), sante(end));
assert(abs(min(sante)) < 1e-12 && abs(max(sante) - 1) < 1e-12, ...
       'l''indicateur est normalise entre zero et un');
assert(sante(1) < 0.15 && sante(end) > 0.85, ...
       'il part pres de zero et finit pres de un');
assert(sante(end) > sante(1), 'et croit avec la degradation');
% Il croît par blocs, non pas à chaque cycle : le bruit de mesure domine
% les tout petits écarts d'un cycle au suivant, et c'est la tendance qui
% porte l'information, non le pas à pas.
blocs = mean(reshape(sante, 20, []), 1);
fprintf('  moyennes par blocs de 20 cycles :');
fprintf(' %.3f', blocs);
fprintf('\n');
assert(all(diff(blocs) > 0), 'l''indicateur croit bloc apres bloc');
fprintf('  croissant sur %.0f %% des pas isoles seulement : c''est la tendance qui compte\n', ...
        100 * mean(diff(sante) > 0));
% Sa corrélation avec l'usure vraie, qu'on ne connaît jamais en pratique.
correlation = corr(sante, usure);
fprintf('  correlation avec l''usure vraie : %.4f\n', correlation);
assert(correlation > 0.99, 'l''indicateur suit fidelement l''usure');
% L'orientation est fixée : même si les descripteurs décroissaient,
% l'indicateur croîtrait — sans quoi le seuil n'aurait pas de sens.
inverse = healthIndicator(-descripteurs);
assert(inverse(end) > inverse(1), ...
       'l''indicateur croit toujours, quel que soit le signe des descripteurs');
fprintf('  avec des descripteurs decroissants : croit toujours\n');

%% 3. Prédire par extrapolation de la tendance
% La méthode la plus directe : ajuster une droite sur l'indicateur, et
% chercher quand elle atteindra le seuil. Elle demande peu, et ne vaut
% que si la dégradation est bien linéaire.
seuil = 1.0;
lineaire = 0.01 * (1:80).';                       % atteint 1.0 au cycle 100
fprintf('\nExtrapolation lineaire, seuil a %g :\n', seuil);
for observes = [30 50 70]
    rul = rulDegradation(lineaire(1:observes), seuil);
    fprintf('  apres %d cycles observes : RUL = %.1f (vrai %d)\n', ...
            observes, rul, 100 - observes);
    assert(abs(rul - (100 - observes)) < 1e-9, ...
           'sur une tendance lineaire, la prediction est exacte');
end
% Un indicateur qui ne monte pas : rien ne permet de prédire une panne,
% et la fonction le dit plutôt que d'inventer un chiffre.
fprintf('  indicateur stable : RUL = %s\n', num2str(rulDegradation(ones(50,1), seuil)));
assert(isinf(rulDegradation(ones(50, 1), seuil)), ...
       'sans degradation, aucune panne prevue');
assert(isinf(rulDegradation((1:50).' * -0.01, seuil)), ...
       'un indicateur qui baisse non plus');
% Seuil déjà franchi : la durée restante est nulle, non négative.
assert(rulDegradation(0.02 * (1:80).', 1.0) == 0, ...
       'seuil deja depasse : plus rien a attendre');
fprintf('  seuil deja franchi : RUL = 0, non un nombre negatif\n');
% La limite de la méthode : sur une dégradation accélérée, l'extrapolation
% linéaire est trop optimiste tant qu'on est loin de la fin.
accelere = (1:60).' .^ 2 / 10000;
rulTot = rulDegradation(accelere, 1.0);
fprintf('  degradation quadratique, apres 60 cycles : RUL lineaire = %.1f\n', rulTot);
assert(rulTot > 40, 'la droite predit trop tard pour une degradation acceleree');
assert(60 + rulTot > 100, 'la vraie panne arrive au cycle 100');

%% 4. Prédire par similarité
% L'autre approche : comparer la trajectoire en cours à celles de machines
% dont on connaît la fin. Chacune vote pour ce qu'il lui restait au même
% stade, au prorata de sa ressemblance. Elle n'exige aucune forme de
% dégradation particulière — seulement des exemples.
rng(13);
historiques = cell(1, 5);
durees = [100 120 90 110 105];
for k = 1:5
    m = durees(k);
    historiques{k} = ((1:m).' / m) .^ 2 + 0.01 * randn(m, 1);
end
% Une machine en cours, bâtie comme celles qui ont duré cent cycles.
enCours = ((1:60).' / 100) .^ 2 + 0.01 * randn(60, 1);
rul = rulSimilarity(enCours, historiques, durees);
fprintf('\nPrediction par similarite, %d historiques :\n', numel(historiques));
fprintf('  machine observee sur 60 cycles : RUL = %.1f (attendu ~40)\n', rul);
assert(abs(rul - 40) < 15, 'la similarite retrouve l''ordre de grandeur');

% Plus on observe, moins il reste : la prédiction doit décroître.
fprintf('  la prediction decroit a mesure qu''on observe :\n');
precedente = inf;
for observes = [20 40 60 80]
    trajectoire = ((1:observes).' / 100) .^ 2 + 0.01 * randn(observes, 1);
    r = rulSimilarity(trajectoire, historiques, durees);
    fprintf('    apres %2d cycles : RUL = %.1f (fin predite au cycle %.0f)\n', ...
            observes, r, observes + r);
    assert(r < precedente, 'plus on observe, moins il reste');
    precedente = r;
end

% Une machine identique à un historique connu doit hériter de sa durée.
% C'est le cas limite qui valide la méthode.
copie = historiques{3}(1:50);
r = rulSimilarity(copie, historiques, durees);
fprintf('  copie exacte de l''historique 3 (duree %d) apres 50 cycles : RUL = %.2f\n', ...
        durees(3), r);
assert(abs(r - (durees(3) - 50)) < 1, ...
       'une trajectoire identique herite de la duree de vie de son jumeau');

% Et la méthode s'accommode d'une dégradation quadratique, là où
% l'extrapolation linéaire se trompait.
fprintf('  sur la meme degradation quadratique : similarite %.1f contre lineaire %.1f\n', ...
        rulSimilarity(((1:60).'/100).^2, historiques, durees), ...
        rulDegradation(((1:60).'/100).^2, 1.0));
assert(abs(rulSimilarity(((1:60).'/100).^2, historiques, durees) - 40) < ...
       abs(rulDegradation(((1:60).'/100).^2, 1.0) - 40), ...
       'la similarite fait mieux que la droite sur une degradation acceleree');

fprintf('\nToutes les verifications passent.\n');
