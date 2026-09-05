% finance.m — Financial Toolbox sur des cas d'école.
%
%   matlibre exemples/toolboxes/finance.m
%
% Trois problèmes classiques : ce que vaut une somme future, comment
% répartir un portefeuille, et ce que vaut une option.

fprintf('=== Finance : actualiser, repartir, evaluer ===\n\n');

%% 1. La valeur du temps
% Un euro aujourd'hui vaut plus qu'un euro demain : c'est l'unique idée
% derrière l'actualisation, et tout le reste en découle.
taux = 0.05;
duree = 10;
fprintf('Valeur du temps a %g %% sur %d ans :\n', taux * 100, duree);
fprintf('  100 places aujourd''hui deviennent %.2f\n', 100 * (1 + taux) ^ duree);
fprintf('  100 dus dans %d ans valent %.2f aujourd''hui\n', duree, pvfix(taux, duree, 0, 100));
% Actualiser puis capitaliser rend la somme de depart.
valeurActuelle = pvfix(taux, duree, 0, 100);
assert(abs(valeurActuelle * (1 + taux) ^ duree - 100) < 1e-9);

% Une annuité : la même somme chaque année.
mensualite = payper(taux / 12, 240, 200000);
fprintf('  emprunt de 200000 sur 20 ans : %.2f par mois\n', mensualite);
% Le total rembourse depasse le capital : la difference est l'interet.
fprintf('  total rembourse %.2f, dont %.2f d''interets\n', ...
        mensualite * 240, mensualite * 240 - 200000);
assert(mensualite * 240 > 200000);
% La valeur actuelle des mensualites vaut bien le capital emprunte.
assert(abs(pvvar([-200000; repmat(mensualite, 240, 1)], taux / 12)) < 1e-4);

% Le taux de rendement interne : celui qui annule la valeur actuelle.
flux = [-1000; 300; 400; 500];
rendement = irr(flux);
fprintf('  taux de rendement interne de %s : %.4f %%\n', ...
        mat2str(flux'), rendement * 100);
assert(abs(pvvar(flux, rendement)) < 1e-6, ...
       'le TRI annule la valeur actuelle, par definition');

%% 2. Obligations
% Le prix d'une obligation est la valeur actuelle de ses coupons et de
% son remboursement. La sensibilité au taux — la duration — dit de
% combien le prix bouge quand le taux bouge.
nominal = 100;
coupon = 0.04;
tauxMarche = 0.05;
echeance = 8;
prix = sum(coupon * nominal ./ (1 + tauxMarche) .^ (1:echeance)) + ...
       nominal / (1 + tauxMarche) ^ echeance;
fprintf('\nObligation %g %% a %d ans, marche a %g %% :\n', ...
        coupon * 100, echeance, tauxMarche * 100);
fprintf('  prix %.4f\n', prix);
% Coupon sous le taux du marche : l'obligation cote sous le pair.
assert(prix < nominal, 'un coupon sous le marche se paie sous le pair');
% La duration de Macaulay : la moyenne des dates, ponderee par la valeur
% actuelle des flux.
dates = (1:echeance)';
fluxObligation = coupon * nominal * ones(echeance, 1);
fluxObligation(end) = fluxObligation(end) + nominal;
actualises = fluxObligation ./ (1 + tauxMarche) .^ dates;
duration = sum(dates .* actualises) / sum(actualises);
fprintf('  duration %.4f ans (echeance %d)\n', duration, echeance);
assert(duration < echeance, 'les coupons ramenent la duration sous l''echeance');
% Verification par la definition : la derivee du prix par rapport au taux.
h = 1e-6;
prixPlus = sum(fluxObligation ./ (1 + tauxMarche + h) .^ dates);
prixMoins = sum(fluxObligation ./ (1 + tauxMarche - h) .^ dates);
sensibilite = -(prixPlus - prixMoins) / (2 * h) / prix * (1 + tauxMarche);
fprintf('  duration par la derivee : %.4f\n', sensibilite);
assert(abs(sensibilite - duration) < 1e-4);

%% 3. Portefeuille
% Répartir entre plusieurs actifs. Le point qui compte : le risque d'un
% portefeuille n'est pas la moyenne des risques — la diversification en
% ôte une partie, et c'est le seul repas gratuit de la finance.
rendements = [0.08; 0.12; 0.05];
volatilites = [0.15; 0.25; 0.08];
correlations = [1 0.3 0.1; 0.3 1 0.2; 0.1 0.2 1];
covariance = diag(volatilites) * correlations * diag(volatilites);
poids = [0.4; 0.3; 0.3];
rendementPortefeuille = poids' * rendements;
risquePortefeuille = sqrt(poids' * covariance * poids);
moyenneRisques = poids' * volatilites;
fprintf('\nPortefeuille de trois actifs :\n');
fprintf('  rendement %.4f\n', rendementPortefeuille);
fprintf('  risque %.4f, moyenne des risques %.4f\n', risquePortefeuille, moyenneRisques);
assert(risquePortefeuille < moyenneRisques, ...
       'la diversification reduit le risque sous la moyenne');
% Le portefeuille de variance minimale, resolu par ses conditions.
un = ones(3, 1);
poidsMin = (covariance \ un) / (un' * (covariance \ un));
risqueMin = sqrt(poidsMin' * covariance * poidsMin);
fprintf('  variance minimale : poids %s, risque %.4f\n', ...
        mat2str(round(poidsMin', 4)), risqueMin);
assert(abs(sum(poidsMin) - 1) < 1e-12);
assert(risqueMin <= risquePortefeuille + 1e-12, ...
       'aucun portefeuille ne peut faire mieux, par construction');

%% 4. Options
% La formule de Black et Scholes. Ce qu'elle dit : le prix d'une option
% ne dépend pas du rendement attendu de l'action, seulement de sa
% volatilité — parce qu'on peut la couvrir.
S = 100;         % cours actuel
K = 100;         % prix d'exercice
r = 0.05;        % taux sans risque
sigma = 0.2;     % volatilite
T = 1;           % echeance en annees
[appel, vente] = blsprice(S, K, r, T, sigma);
fprintf('\nOption a la monnaie, %g an, volatilite %g %% :\n', T, sigma * 100);
fprintf('  achat %.4f, vente %.4f\n', appel, vente);
% La parite achat-vente : C - P = S - K exp(-rT). Elle ne suppose aucun
% modele, seulement l'absence d'arbitrage.
parite = appel - vente - (S - K * exp(-r * T));
fprintf('  parite achat-vente : ecart %.3e\n', parite);
assert(abs(parite) < 1e-9);
% Le delta : de combien le prix bouge quand le cours bouge.
delta = blsdelta(S, K, r, T, sigma);
h = 1e-5;
deltaNumerique = (blsprice(S + h, K, r, T, sigma) - blsprice(S - h, K, r, T, sigma)) / (2 * h);
fprintf('  delta %.4f, par difference finie %.4f\n', delta, deltaNumerique);
assert(abs(delta - deltaNumerique) < 1e-5);
assert(delta > 0 && delta < 1, 'le delta d''un achat est entre zero et un');
% La volatilite implicite : celle qui redonne le prix observe.
implicite = blsimpv(S, K, r, T, appel);
fprintf('  volatilite implicite retrouvee : %.6f (vraie %g)\n', implicite, sigma);
assert(abs(implicite - sigma) < 1e-4);
% Une option plus longue vaut plus cher : le temps est de la valeur.
assert(blsprice(S, K, r, 2, sigma) > appel);
% Une option plus volatile aussi : l'incertitude profite au detenteur,
% qui ne perd que sa prime.
assert(blsprice(S, K, r, T, 0.4) > appel);

%% 5. Séries de cours
% Ce qu'on calcule tous les jours sur une série de prix.
rng(5);
cours = 100 * cumprod(1 + 0.01 * randn(250, 1));
variations = diff(cours) ./ cours(1:end-1);
fprintf('\nSerie de %d cours :\n', numel(cours));
fprintf('  rendement total %.2f %%\n', (cours(end) / cours(1) - 1) * 100);
fprintf('  volatilite annualisee %.2f %%\n', std(variations) * sqrt(252) * 100);
% Le maximum de perte depuis un sommet.
sommets = cummax(cours);
pertes = (cours - sommets) ./ sommets;
fprintf('  perte maximale depuis un sommet : %.2f %%\n', min(pertes) * 100);
assert(min(pertes) <= 0);
assert(all(sommets >= cours - 1e-12));
% Une moyenne mobile suit la tendance en retard : c'est ce qu'on lui
% demande, et sa limite.
moyenne = movmean(cours, 20);
assert(numel(moyenne) == numel(cours));
assert(std(moyenne) < std(cours), 'une moyenne mobile lisse');

fprintf('\nToutes les verifications passent.\n');
