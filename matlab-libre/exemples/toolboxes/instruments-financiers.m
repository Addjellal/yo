% instruments-financiers.m — Financial Instruments Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/instruments-financiers.m
%
% Le cas : une courbe de taux, des obligations, et des options. Ce qui
% relie tout : un instrument vaut la somme actualisée de ce qu'il
% rapporte, et l'actualisation vient de la courbe.

fprintf('=== Instruments financiers : la courbe, puis tout le reste ===\n\n');

%% 1. La courbe de taux
% Le taux dépend de l'échéance : c'est la courbe. Le facteur
% d'actualisation à l'échéance t vaut exp(-r(t) t) en composition
% continue.
echeances = [0.25 0.5 1 2 3 5 7 10]';
taux = [0.020 0.022 0.025 0.028 0.030 0.033 0.035 0.036]';
fprintf('Courbe de taux :\n');
for k = 1:numel(echeances)
    fprintf('  %5.2f an(s) : %.3f %%\n', echeances(k), taux(k) * 100);
end
facteurs = exp(-taux .* echeances);
fprintf('  facteurs d''actualisation : de %.4f a %.4f\n', ...
        facteurs(1), facteurs(end));
% Ils decroissent : un euro plus lointain vaut moins.
assert(all(diff(facteurs) < 0), 'le facteur d''actualisation decroit');
assert(all(facteurs > 0 & facteurs < 1));

% Les taux à terme : ce que la courbe implique pour les périodes futures.
% Ils se lisent sur les rapports de facteurs, et c'est une identité, non
% une prévision.
terme = zeros(numel(echeances) - 1, 1);
for k = 1:numel(terme)
    dt = echeances(k + 1) - echeances(k);
    terme(k) = log(facteurs(k) / facteurs(k + 1)) / dt;
end
fprintf('  taux a terme de %.3f %% a %.3f %%\n', min(terme) * 100, max(terme) * 100);
% Une courbe croissante donne des taux a terme au-dessus des taux au
% comptant : c'est mecanique.
assert(terme(1) > taux(1), 'courbe croissante, terme au-dessus du comptant');
% Composer les taux a terme redonne le facteur d'actualisation total.
refait = exp(-taux(1) * echeances(1));
for k = 1:numel(terme)
    refait = refait * exp(-terme(k) * (echeances(k + 1) - echeances(k)));
end
fprintf('  facteur recompose : %.10f (direct %.10f)\n', refait, facteurs(end));
assert(abs(refait - facteurs(end)) < 1e-12);

%% 2. Une obligation
% Sa valeur est la somme actualisée de ses coupons et de son
% remboursement, chacun avec le taux de son échéance.
nominal = 100;
coupon = 0.035;
maturite = 5;
dates = (1:maturite)';
flux = coupon * nominal * ones(maturite, 1);
flux(end) = flux(end) + nominal;
tauxFlux = interp1(echeances, taux, dates, 'linear', 'extrap');
prix = sum(flux .* exp(-tauxFlux .* dates));
fprintf('\nObligation %g %% a %d ans :\n', coupon * 100, maturite);
fprintf('  prix %.4f\n', prix);
% Le taux de rendement actuariel : le taux unique qui redonne ce prix.
rendement = fzero(@(r) sum(flux .* exp(-r * dates)) - prix, 0.03);
fprintf('  taux actuariel %.4f %%\n', rendement * 100);
assert(abs(sum(flux .* exp(-rendement * dates)) - prix) < 1e-9, ...
       'par definition, il annule l''ecart de prix');
% Il se situe entre le plus petit et le plus grand taux de la courbe
% employee : c'est une moyenne ponderee, non un taux nouveau.
assert(rendement > min(tauxFlux) && rendement < max(tauxFlux));

% La sensibilité : de combien le prix bouge si toute la courbe bouge.
h = 1e-6;
prixPlus = sum(flux .* exp(-(tauxFlux + h) .* dates));
prixMoins = sum(flux .* exp(-(tauxFlux - h) .* dates));
sensibilite = -(prixPlus - prixMoins) / (2 * h) / prix;
fprintf('  duration %.4f ans\n', sensibilite);
assert(sensibilite > 0 && sensibilite < maturite, ...
       'les coupons ramenent la duration sous l''echeance');
% La convexite : la courbure, qui rend l'approximation lineaire trop
% pessimiste dans les deux sens.
convexite = (prixPlus - 2 * prix + prixMoins) / h ^ 2 / prix;
fprintf('  convexite %.4f\n', convexite);
assert(convexite > 0, 'un flux positif donne toujours une convexite positive');
% Verification : sur un choc de 1 %, le developpement au second ordre
% doit approcher le prix bien mieux que le premier.
choc = 0.01;
exact = sum(flux .* exp(-(tauxFlux + choc) .* dates));
ordre1 = prix * (1 - sensibilite * choc);
ordre2 = ordre1 + prix * 0.5 * convexite * choc ^ 2;
fprintf('  choc de 1 %% : exact %.4f, ordre 1 %.4f, ordre 2 %.4f\n', ...
        exact, ordre1, ordre2);
assert(abs(ordre2 - exact) < abs(ordre1 - exact), ...
       'la convexite ameliore l''approximation');

%% 3. Les options
% Le prix d'une option ne dépend pas du rendement attendu du sous-jacent,
% seulement de sa volatilité — parce qu'on peut la couvrir.
cours = 100;
exercice = 100;
tauxCourt = 0.025;
volatilite = 0.25;
duree = 1;
[achat, vente] = blsprice(cours, exercice, tauxCourt, duree, volatilite);
fprintf('\nOption a la monnaie, %g an, volatilite %g %% :\n', duree, volatilite * 100);
fprintf('  achat %.4f, vente %.4f\n', achat, vente);
% La parite achat-vente ne suppose aucun modele : seulement l'absence
% d'arbitrage.
assert(abs(achat - vente - (cours - exercice * exp(-tauxCourt * duree))) < 1e-9);
% Les sensibilites, verifiees par difference finie.
delta = blsdelta(cours, exercice, tauxCourt, duree, volatilite);
gamma = blsgamma(cours, exercice, tauxCourt, duree, volatilite);
vega = blsvega(cours, exercice, tauxCourt, duree, volatilite);
pas = 1e-4;
deltaNumerique = (blsprice(cours + pas, exercice, tauxCourt, duree, volatilite) - ...
                  blsprice(cours - pas, exercice, tauxCourt, duree, volatilite)) / (2 * pas);
gammaNumerique = (blsprice(cours + pas, exercice, tauxCourt, duree, volatilite) - ...
                  2 * achat + ...
                  blsprice(cours - pas, exercice, tauxCourt, duree, volatilite)) / pas ^ 2;
vegaNumerique = (blsprice(cours, exercice, tauxCourt, duree, volatilite + pas) - ...
                 blsprice(cours, exercice, tauxCourt, duree, volatilite - pas)) / (2 * pas);
fprintf('  delta %.6f (numerique %.6f)\n', delta, deltaNumerique);
fprintf('  gamma %.6f (numerique %.6f)\n', gamma, gammaNumerique);
fprintf('  vega  %.6f (numerique %.6f)\n', vega, vegaNumerique);
assert(abs(delta - deltaNumerique) < 1e-5);
assert(abs(gamma - gammaNumerique) < 1e-3);
assert(abs(vega - vegaNumerique) < 1e-4);
% Le gamma est maximal a la monnaie : c'est la que le delta bouge le plus.
gammaLoin = blsgamma(cours, 150, tauxCourt, duree, volatilite);
assert(gamma > gammaLoin, 'le gamma culmine a la monnaie');

%% 4. L'arbre binomial
% Une autre façon de valoriser : découper le temps, et à chaque pas le
% cours monte ou descend. Quand le pas tend vers zéro, on retrouve
% Black-Scholes — c'est le théorème qui justifie les deux.
fprintf('\nArbre binomial :\n');
prixArbre = zeros(1, 4);
pas = [10 50 200 1000];
for k = 1:4
    prixArbre(k) = matlibre_essai_binomial(cours, exercice, tauxCourt, ...
                                           volatilite, duree, pas(k));
    fprintf('  %4d pas : %.6f (Black-Scholes %.6f)\n', pas(k), prixArbre(k), achat);
end
ecarts = abs(prixArbre - achat);
assert(ecarts(end) < ecarts(1), 'l''arbre doit converger vers Black-Scholes');
assert(ecarts(end) < 0.02);

%% 5. Un échange de taux
% Payer fixe contre recevoir variable. Sa valeur initiale est nulle si le
% taux fixe est bien choisi : c'est ce qui définit le taux d'échange.
echeancesEchange = (1:5)';
facteursEchange = exp(-interp1(echeances, taux, echeancesEchange, ...
                               'linear', 'extrap') .* echeancesEchange);
tauxEchange = (1 - facteursEchange(end)) / sum(facteursEchange);
fprintf('\nEchange de taux a 5 ans :\n');
fprintf('  taux d''echange %.4f %%\n', tauxEchange * 100);
% Verification : la jambe fixe et la jambe variable valent alors la meme
% chose.
jambeFixe = tauxEchange * sum(facteursEchange);
jambeVariable = 1 - facteursEchange(end);
fprintf('  jambe fixe %.10f, jambe variable %.10f\n', jambeFixe, jambeVariable);
assert(abs(jambeFixe - jambeVariable) < 1e-12, ...
       'le taux d''echange est celui qui egalise les deux jambes');
% Il se situe dans la plage des taux au comptant employes.
assert(tauxEchange > min(taux(1:5)) && tauxEchange < max(taux));

fprintf('\nToutes les verifications passent.\n');

function prix = matlibre_essai_binomial(S, K, r, sigma, T, n)
%MATLIBRE_ESSAI_BINOMIAL Option d'achat europeenne par arbre de Cox,
%   Ross et Rubinstein. Les facteurs de montee et de descente sont
%   choisis pour que la variance du modele discret egale celle du modele
%   continu : u = exp(sigma sqrt(dt)) et d = 1/u.
    dt = T / n;
    u = exp(sigma * sqrt(dt));
    d = 1 / u;
    p = (exp(r * dt) - d) / (u - d);
    valeurs = max(S * u .^ (n:-2:-n)' - K, 0);
    escompte = exp(-r * dt);
    for etape = n:-1:1
        valeurs = escompte * (p * valeurs(1:end-1) + (1 - p) * valeurs(2:end));
    end
    prix = valeurs;
end
