% gestion-risques.m — Risk Management Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/gestion-risques.m
%
% Le cas : mesurer le risque d'un portefeuille, et savoir si la mesure
% tient. C'est le second point qui compte — une valeur en risque qu'on ne
% contrôle pas a posteriori ne vaut rien.

fprintf('=== Gestion des risques : mesurer, puis verifier la mesure ===\n\n');

%% 1. La valeur en risque
% Le quantile des pertes : « dans 95 % des cas, je ne perds pas plus que
% cela ». C'est une mesure du seuil, non de ce qu'il y a derrière.
rng(1);
rendements = 0.0004 + 0.012 * randn(2000, 1);
niveau = 0.95;
var95 = valueAtRisk(rendements, niveau);
es95 = expectedShortfall(rendements, niveau);
fprintf('Sur %d rendements journaliers :\n', numel(rendements));
fprintf('  valeur en risque a %g %% : %.4f\n', niveau * 100, var95);
fprintf('  perte moyenne au-dela   : %.4f\n', es95);
% La perte moyenne au-dela du seuil est toujours pire que le seuil :
% c'est ce qui la rend preferable quand la queue compte.
assert(es95 > var95, 'la perte extreme moyenne depasse le quantile');
% La proportion de depassements vaut bien un moins le niveau.
depassements = mean(-rendements > var95);
fprintf('  proportion de depassements : %.4f (attendu %.2f)\n', ...
        depassements, 1 - niveau);
assert(abs(depassements - (1 - niveau)) < 0.01);
% Un niveau plus exigeant donne un seuil plus haut.
assert(valueAtRisk(rendements, 0.99) > var95);

%% 2. Contrôler la mesure a posteriori
% Le seul juge d'un modèle de risque est le décompte des dépassements
% réels. Trop peu, le modèle est trop prudent ; trop, il est faux.
previsions = repmat(var95, numel(rendements), 1);
controle = varbacktest(rendements, previsions, 'VaRLevel', niveau);
resultats = summary(controle);
fprintf('\nControle a posteriori :\n');
fprintf('  %d observations, %d depassements, %.2f attendus\n', ...
        resultats.ObservedLevel * 0 + numel(rendements), ...
        resultats.Failures, resultats.Expected);
assert(abs(resultats.Failures - resultats.Expected) < 3 * sqrt(resultats.Expected), ...
       'le nombre de depassements doit rester proche de l''attendu');

%% 3. Le risque d'un portefeuille
% Le risque total n'est pas la somme des risques : la diversification en
% ôte une partie. Reste à savoir combien chaque position y contribue.
poids = [0.4; 0.35; 0.25];
volatilites = [0.20; 0.30; 0.12];
correlations = [1 0.4 0.1; 0.4 1 0.2; 0.1 0.2 1];
covariance = diag(volatilites) * correlations * diag(volatilites);
risqueTotal = sqrt(poids' * covariance * poids);
sommeRisques = poids' * volatilites;
fprintf('\nPortefeuille de trois positions :\n');
fprintf('  risque du portefeuille %.4f\n', risqueTotal);
fprintf('  somme ponderee des risques %.4f\n', sommeRisques);
assert(risqueTotal < sommeRisques, 'la diversification reduit le risque');
% Les contributions au risque : la derivee du risque total par rapport a
% chaque poids, multipliee par le poids. Elles somment exactement au
% risque total — c'est la propriete d'Euler, et c'est ce qui rend la
% decomposition legitime.
marginales = (covariance * poids) / risqueTotal;
contributions = poids .* marginales;
fprintf('  contributions : %s\n', mat2str(round(contributions', 5)));
fprintf('  leur somme : %.6f (risque total %.6f)\n', sum(contributions), risqueTotal);
assert(abs(sum(contributions) - risqueTotal) < 1e-12, ...
       'les contributions somment au risque total');
% La position la plus risquee n'est pas forcement celle qui pese le plus.
[~, plusLourde] = max(poids);
[~, plusRisquee] = max(contributions);
fprintf('  position la plus lourde : %d, la plus risquee : %d\n', ...
        plusLourde, plusRisquee);

%% 4. La concentration
% Un portefeuille concentré est fragile, même si chaque position est
% saine. Les indices de concentration le mesurent.
indices = concentrationIndices(poids);
fprintf('\nConcentration :\n');
fprintf('  Herfindahl normalise %.4f, Gini %.4f, entropie %.4f\n', ...
        indices.HH, indices.Gini, indices.TE);
% Les indices sont normalises par defaut, comme dans MATLAB : zero quand
% tout est reparti egalement, un quand une seule position porte tout.
% C'est ce qui permet de comparer des portefeuilles de tailles
% differentes, ce que l'indice brut ne permettrait pas.
egal = concentrationIndices(ones(4, 1) / 4);
concentre = concentrationIndices([1; 0; 0; 0]);
fprintf('  quatre positions egales : %.4f\n', egal.HH);
fprintf('  une seule position      : %.4f\n', concentre.HH);
assert(abs(egal.HH) < 1e-12, 'reparti egalement : concentration nulle');
assert(abs(concentre.HH - 1) < 1e-12, 'tout sur un : concentration maximale');
assert(indices.HH > 0 && indices.HH < 1, ...
       'un portefeuille inegal se situe entre les deux extremes');
% L'indice brut, lui, est la somme des carres des parts : 1/n pour n
% positions egales, un pour une seule.
brut = concentrationIndices(ones(4, 1) / 4, 'ScaleIndices', false);
fprintf('  indice brut de quatre positions egales : %.4f (attendu 0.25)\n', brut.HH);
assert(abs(brut.HH - 0.25) < 1e-12);
brutPoids = concentrationIndices(poids, 'ScaleIndices', false);
assert(abs(brutPoids.HH - sum(poids .^ 2)) < 1e-12, ...
       'c''est bien la somme des carres des parts');

%% 5. Le risque de défaut
% Le modèle de Merton : une entreprise fait défaut quand la valeur de son
% actif passe sous celle de sa dette. C'est une option de vente, et
% Black-Scholes s'applique.
valeurAction = 50;
volatiliteAction = 0.4;
dette = 40;
echeance = 1;
tauxSansRisque = 0.03;
% L'ordre des sorties est celui de MATLAB : probabilite, distance, puis
% la valeur de l'actif et sa volatilite, qui sont les inconnues du
% systeme resolu par iteration.
[probabilite, distance, actif, volatiliteActif] = ...
    mertonmodel(valeurAction, volatiliteAction, dette, tauxSansRisque, echeance);
fprintf('\nModele de Merton :\n');
fprintf('  valeur de l''actif %.4f, volatilite %.4f\n', actif, volatiliteActif);
fprintf('  distance au defaut %.4f, probabilite %.6f\n', distance, probabilite);
% L'actif vaut plus que l'action seule : il porte aussi la dette.
assert(actif > valeurAction);
% La volatilite de l'actif est moindre que celle de l'action : le levier
% amplifie les mouvements sur les fonds propres.
assert(volatiliteActif < volatiliteAction, ...
       'le levier amplifie la volatilite des fonds propres');
assert(probabilite > 0 && probabilite < 1);
% Plus de dette, plus de risque.
probabiliteLourde = mertonmodel(valeurAction, volatiliteAction, ...
                                60, tauxSansRisque, echeance);
fprintf('  avec une dette de 60 : probabilite %.6f\n', probabiliteLourde);
assert(probabiliteLourde > probabilite);

%% 6. Les matrices de transition
% Comment les notations migrent d'une année sur l'autre. Chaque ligne est
% une loi de probabilité : elle somme à un.
notations = {'AAA', 'BBB', 'D'};
transitions = [0.90 0.09 0.01;
               0.05 0.90 0.05;
               0.00 0.00 1.00];
fprintf('\nMatrice de transition :\n');
for k = 1:3
    fprintf('  %-4s -> %s\n', notations{k}, mat2str(transitions(k, :)));
end
assert(max(abs(sum(transitions, 2) - 1)) < 1e-12, ...
       'chaque ligne est une loi de probabilite');
% Le defaut est absorbant : on n'en sort pas.
assert(transitions(3, 3) == 1);
% Sur deux ans, les transitions se composent par produit matriciel.
deuxAns = transitions ^ 2;
fprintf('  probabilite de defaut a 2 ans depuis AAA : %.4f\n', deuxAns(1, 3));
assert(deuxAns(1, 3) > transitions(1, 3), ...
       'le risque cumule croit avec l''horizon');
assert(max(abs(sum(deuxAns, 2) - 1)) < 1e-12);
% A l'infini, tout finit par faire defaut : c'est le propre d'un etat
% absorbant atteignable depuis partout.
lointain = transitions ^ 200;
fprintf('  a 200 ans : %.6f\n', lointain(1, 3));
assert(lointain(1, 3) > 0.99);

fprintf('\nToutes les verifications passent.\n');
