% test_instruments.m — environnement de taux, jeux d'instruments,
% valorisation sur courbe, modèle de Black, formes fermées de Black et
% Scholes, arbres binomiaux et protection contre le défaut.
%
% Les vérifications sont des identités que la finance impose : une
% parité achat-vente, une parité entrante-sortante, un amorçage qui
% inverse une valorisation, un arbre fin qui rejoint une formule fermée.
disp('--- instruments financiers ---');

% Environnement de taux : une courbe plate.
dates = {'01-Jan-2025','01-Jan-2026','01-Jan-2027','01-Jan-2029','01-Jan-2034'};
courbe = intenvset('Rates', [0.03; 0.032; 0.034; 0.036; 0.040], ...
                   'StartDates', '01-Jan-2024', 'EndDates', dates, ...
                   'Compounding', 2, 'Basis', 0);
fprintf('facteurs : %s\n', sprintf('%9.6f', courbe.Disc));
assert(all(diff(courbe.Disc) < 0));
% Les facteurs redonnent les taux.
c2 = intenvset('Disc', courbe.Disc, 'StartDates', '01-Jan-2024', 'EndDates', dates);
assert(max(abs(c2.Rates - courbe.Rates)) < 1e-12);
assert(max(abs(intenvget(courbe, 'Rates') - courbe.Rates)) < 1e-12);
% date2time et time2date sont inverses.
assert(abs(date2time('01-Jan-2024', '01-Jan-2026', 2, 0) - 4) < 1e-9);
assert(time2date('01-Jan-2024', 4, 2, 0) == datenum(2026, 1, 1));
assert(abs(date2time('01-Jan-2024', time2date('01-Jan-2024', 3.5, 2, 0), 2, 0) - 3.5) < 0.01);
% zeroprice et zeroyield sont inverses.
p = zeroprice(0.05, '01-Jan-2024', '01-Jan-2029');
fprintf('zero-coupon a 5 ans : %.6f\n', p);
assert(abs(zeroyield(p, '01-Jan-2024', '01-Jan-2029') - 0.05) < 1e-12);
assert(abs(p - 100 * (1 + 0.05/2) ^ (-2 * yearfrac('01-Jan-2024','01-Jan-2029', 0))) < 1e-9);
% Sur une courbe plate, valoriser sur la courbe revient a valoriser au
% rendement.
% En base 30/360, chaque semestre vaut exactement une demi-annee : les
% deux facons de compter le temps coincident, et les deux prix aussi.
plate = intenvset('Rates', 0.04 * ones(6, 1), 'StartDates', '01-Jan-2024', ...
                  'EndDates', datenum(2025:2030, 1, 1)', 'Compounding', 2, 'Basis', 1);
pCourbe = bondbyzero(plate, 0.05, '01-Jan-2024', '01-Jan-2029', 2, 1);
pRendement = bndprice(0.04, 0.05, '01-Jan-2024', '01-Jan-2029', 2, 1);
fprintf('sur courbe %.8f, au rendement %.8f\n', pCourbe, pRendement);
assert(abs(pCourbe - pRendement) < 1e-8);
% cfbyzero actualise bien chaque flux.
flux = [5 5 105];
datesFlux = {'01-Jan-2025','01-Jan-2026','01-Jan-2027'};
pf = cfbyzero(plate, flux, datesFlux, '01-Jan-2024');
attendu = 0;
for k = 1:3
    attendu = attendu + flux(k) * (1 + 0.04/2) ^ (-2 * yearfrac('01-Jan-2024', datesFlux{k}, 1));
end
fprintf('cfbyzero %.6f, attendu %.6f\n', pf, attendu);
assert(abs(pf - attendu) < 1e-9);
% La branche variable sans ecart vaut la difference des facteurs.
pv = floatbyzero(courbe, 0, '01-Jan-2024', '01-Jan-2029', 4, 0, 100);
facteurFin = matlibre_courbe_escompte(courbe, datenum(2029, 1, 1));
fprintf('branche variable %.6f, attendu %.6f\n', pv, 100 * (1 - facteurFin));
assert(abs(pv - 100 * (1 - facteurFin)) < 1e-6);
% Au taux d'echange, la valeur de l'echange est nulle.
[p0, taux] = swapbyzero(courbe, [0.04 0], '01-Jan-2024', '01-Jan-2029', [2 4]);
fprintf('valeur a 4 %% : %.6f, taux d''echange : %.6f\n', p0, taux);
[pNul, ~] = swapbyzero(courbe, [taux 0], '01-Jan-2024', '01-Jan-2029', [2 4]);
fprintf('valeur au taux d''echange : %.3e\n', pNul);
assert(abs(pNul) < 1e-8);
% Le modele de Black : parite achat-vente sur contrat a terme.
[c, v] = blkprice(100, 95, 0.05, 1, 0.25);
fprintf('black : achat %.6f, vente %.6f\n', c, v);
assert(abs(c - v - exp(-0.05) * (100 - 95)) < 1e-10);
assert(abs(blkimpv(100, 95, 0.05, 1, c) - 0.25) < 1e-6);
% Un contrat a terme egal au comptant capitalise donne le meme prix que
% Black et Scholes.
S = 100; r = 0.05; T = 1; K = 95; sigma = 0.25;
[cBls] = blsprice(S, K, r, T, sigma);
[cBlk] = blkprice(S * exp(r * T), K, r, T, sigma);
fprintf('bls %.8f, black %.8f\n', cBls, cBlk);
assert(abs(cBls - cBlk) < 1e-10);

%% ------------------------------------------------ options sur action
c = intenvset('Rates', 0.05, 'StartDates', '01-Jan-2024', ...
              'EndDates', '01-Jan-2025', 'Compounding', -1, 'Basis', 0);
s = stockspec(0.25, 100);
% Le prix rendu est celui de blsprice.
p = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 95);
T = yearfrac('01-Jan-2024', '01-Jan-2025', 0);
attendu = blsprice(100, 95, 0.05, T, 0.25);
fprintf('optstockbybls %.8f, blsprice %.8f\n', p, attendu);
assert(abs(p - attendu) < 1e-9);
% Avec dividende continu.
sd = stockspec(0.25, 100, 'continuous', 0.03);
pd = optstockbybls(c, sd, '01-Jan-2024', '01-Jan-2025', 'put', 105);
[~, attenduPut] = blsprice(100, 105, 0.05, T, 0.25, 0.03);
assert(abs(pd - attenduPut) < 1e-9);
% Les sensibilites reprennent les grecques.
[pr, de, ga, ve] = optstocksensbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 95, ...
                                     {'Price','Delta','Gamma','Vega'});
assert(abs(pr - attendu) < 1e-9);
assert(abs(de - blsdelta(100, 95, 0.05, T, 0.25)) < 1e-12);
assert(abs(ga - blsgamma(100, 95, 0.05, T, 0.25)) < 1e-12);
assert(abs(ve - blsvega(100, 95, 0.05, T, 0.25)) < 1e-12);
% Barrieres : entrante plus sortante egale l'option ordinaire.
for genre = {'call', 'put'}
  for K = [90 100 110]
    for H = [85 95]
      pIn = barrierbybls(c, s, genre{1}, K, '01-Jan-2024', '01-Jan-2025', 'DI', H, 0);
      pOut = barrierbybls(c, s, genre{1}, K, '01-Jan-2024', '01-Jan-2025', 'DO', H, 0);
      vanille = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', genre{1}, K);
      assert(abs(pIn + pOut - vanille) < 1e-9, sprintf('%s K=%d H=%d bas', genre{1}, K, H));
    end
    for H = [105 120]
      pIn = barrierbybls(c, s, genre{1}, K, '01-Jan-2024', '01-Jan-2025', 'UI', H, 0);
      pOut = barrierbybls(c, s, genre{1}, K, '01-Jan-2024', '01-Jan-2025', 'UO', H, 0);
      vanille = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', genre{1}, K);
      assert(abs(pIn + pOut - vanille) < 1e-9, sprintf('%s K=%d H=%d haut', genre{1}, K, H));
    end
  end
end
fprintf('parite entrante-sortante : ok pour douze combinaisons\n');
% Une barriere tres eloignee : la sortante vaut l'ordinaire.
loin = barrierbybls(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025', 'DO', 1, 0);
ordinaire = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100);
fprintf('barriere lointaine %.8f, ordinaire %.8f\n', loin, ordinaire);
assert(abs(loin - ordinaire) < 1e-8);
% Une barriere collee au cours : la sortante ne vaut presque rien.
proche = barrierbybls(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025', 'DO', 99.99, 0);
fprintf('barriere collee : %.6f\n', proche);
assert(proche < 0.2);
% Les prix restent positifs.
for genre = {'call','put'}
  for forme = {'DI','DO','UI','UO'}
    for H = [80 90 110 130]
      v = barrierbybls(c, s, genre{1}, 100, '01-Jan-2024', '01-Jan-2025', forme{1}, H, 0);
      assert(v >= -1e-10, sprintf('%s %s H=%d : %g', genre{1}, forme{1}, H, v));
    end
  end
end

%% ------------------------------------------------------- exotiques
c = intenvset('Rates', 0.05, 'StartDates', '01-Jan-2024', ...
              'EndDates', '01-Jan-2025', 'Compounding', -1, 'Basis', 0);
s = stockspec(0.25, 100);
T = yearfrac('01-Jan-2024', '01-Jan-2025', 0);
% Binaires : l'achat ordinaire est l'actif moins le prix d'exercice fois
% l'espece.
for K = [80 100 120]
    a = assetbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', K);
    e = cashbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', K, 1);
    v = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', K);
    assert(abs(a - K * e - v) < 1e-10, sprintf('K=%d', K));
    av = assetbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', K);
    ev = cashbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', K, 1);
    vv = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', K);
    assert(abs(K * ev - av - vv) < 1e-10);
end
fprintf('binaires : ok\n');
% Les deux binaires somment a la valeur actuelle du versement.
assert(abs(cashbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100, 1) + ...
           cashbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', 100, 1) - exp(-0.05 * T)) < 1e-10);
% Option a saut : seuil egal au versement, c'est l'option ordinaire.
g = gapbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100, 100);
assert(abs(g - optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100)) < 1e-10);
gv = gapbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', 100, 100);
assert(abs(gv - optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', 100)) < 1e-10);
% Superaction : elle vaut la difference de deux binaires en actif,
% divisee par la borne basse.
sup = supersharebybls(c, s, '01-Jan-2024', '01-Jan-2025', 90, 110);
haut = assetbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 90);
bas = assetbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 110);
fprintf('superaction : %.8f, attendu %.8f\n', sup, (haut - bas) / 90);
assert(abs(sup - (haut - bas) / 90) < 1e-10);
% Deux superactions contigues font celle qui les couvre.
a1 = supersharebybls(c, s, '01-Jan-2024', '01-Jan-2025', 90, 100);
a2 = supersharebybls(c, s, '01-Jan-2024', '01-Jan-2025', 100, 110);
a3 = supersharebybls(c, s, '01-Jan-2024', '01-Jan-2025', 90, 110);
assert(abs(a1 + 100 / 90 * a2 - a3) < 1e-9);
% Option au choix : quand le choix se fait a l'echeance, elle vaut le
% couple achat-vente.
ch = chooserbybls(c, s, '01-Jan-2024', '01-Jan-2025', 100, '31-Dec-2024');
achat = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100);
vente = optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'put', 100);
fprintf('au choix a l''echeance %.6f, couple %.6f\n', ch, achat + vente);
assert(abs(ch - (achat + vente)) < 0.02);
% Un choix plus precoce coute moins cher, mais plus que le plus cher des
% deux.
chTot = chooserbybls(c, s, '01-Jan-2024', '01-Jan-2025', 100, '01-Apr-2024');
fprintf('choix precoce %.6f\n', chTot);
assert(chTot < ch && chTot > max(achat, vente));
% Asiatiques : la geometrique coute moins que l'arithmetique, et les deux
% moins que l'ordinaire.
ag = asianbykv(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025');
aa = asianbylevy(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025');
fprintf('asiatique geometrique %.6f, arithmetique %.6f, ordinaire %.6f\n', ag, aa, achat);
assert(ag < aa && aa < achat);
% La parite achat-vente vaut pour l'asiatique geometrique.
agv = asianbykv(c, s, 'put', 100, '01-Jan-2024', '01-Jan-2025');
portage = (0.05 - 0.25 ^ 2 / 6) / 2;
assert(abs(ag - agv - (100 * exp((portage - 0.05) * T) - 100 * exp(-0.05 * T))) < 1e-9);
% Retrospectives : elles valent plus que l'option ordinaire a la monnaie.
lc = lookbackbybls(c, s, 'call', NaN, '01-Jan-2024', '01-Jan-2025');
lp = lookbackbybls(c, s, 'put', NaN, '01-Jan-2024', '01-Jan-2025');
fprintf('retrospective flottante : achat %.6f, vente %.6f\n', lc, lp);
assert(lc > achat && lp > vente);
% A prix fixe egal au cours, elle vaut aussi plus que l'ordinaire.
lf = lookbackbybls(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025');
fprintf('retrospective a prix fixe : %.6f\n', lf);
assert(lf > achat);

%% ---------------------------------------------- jeux d'instruments
jeu = instadd('Bond', [0.05; 0.04], '01-Jan-2024', ...
              [datenum('01-Jan-2029'); datenum('01-Jan-2027')]);
jeu = instadd(jeu, 'OptStock', {'call'; 'put'}, [100; 110], '01-Jan-2024', ...
              datenum('01-Jan-2025'), 0);
fprintf('longueur : %d\n', instlength(jeu));
assert(instlength(jeu) == 4);
assert(isequal(insttypes(jeu), {'Bond'; 'OptStock'}));
instdisp(jeu);
% Les champs se relisent.
[taux, echeance] = instget(jeu, 'FieldList', {'CouponRate', 'Maturity'});
fprintf('taux : %s\n', mat2str(taux'));
assert(isequaln(taux, [0.05; 0.04; NaN; NaN]));
assert(echeance(1) == datenum('01-Jan-2029'));
% Un champ de texte.
genre = instget(jeu, 'FieldList', 'OptSpec');
assert(isequal(genre, {''; ''; 'call'; 'put'}));
% Selection par type.
[obligations, rangs] = instselect(jeu, 'Type', 'Bond');
assert(instlength(obligations) == 2 && isequal(rangs, [1; 2]));
% Selection par valeur de champ.
[choisi, rangsChoisis] = instselect(jeu, 'FieldName', 'CouponRate', 'Data', 0.05);
assert(instlength(choisi) == 1 && rangsChoisis == 1);
% Modification d'un champ.
jeu2 = instsetfield(jeu, 'Index', 1, 'FieldName', 'CouponRate', 'Data', 0.06);
assert(abs(instget(jeu2, 'FieldList', 'CouponRate')(1) - 0.06) < 1e-12);
% Suppression.
jeu3 = instdelete(jeu, 'Index', 2);
assert(instlength(jeu3) == 3);
assert(isequaln(instget(jeu3, 'FieldList', 'CouponRate'), [0.05; NaN; NaN]));
% Un type maison.
maison = instaddfield('FieldName', {'Nominal', 'Nom'}, ...
                      'Data', {[100; 200], {'A'; 'B'}}, 'Type', 'Maison');
assert(instlength(maison) == 2);
assert(isequal(instget(maison, 'FieldList', 'Nom'), {'A'; 'B'}));
assert(isequal(instfields(maison), {'Nominal'; 'Nom'}));
% Les champs se listent par type.
assert(numel(instfields(jeu, 'Type', 'OptStock')) == 5);

%% ------------------------------------------- valorisation de jeux
courbe = intenvset('Rates', [0.03; 0.032; 0.034; 0.036; 0.040], ...
                   'StartDates', '01-Jan-2024', ...
                   'EndDates', datenum([2025 2026 2027 2029 2034], 1, 1)', ...
                   'Compounding', 2, 'Basis', 1);
jeu = instadd('Bond', [0.05; 0.04], '01-Jan-2024', ...
              [datenum('01-Jan-2029'); datenum('01-Jan-2027')], 2, 1);
jeu = instadd(jeu, 'Fixed', 0.04, '01-Jan-2024', '01-Jan-2029', 2, 1, 100);
jeu = instadd(jeu, 'Float', 0, '01-Jan-2024', '01-Jan-2029', 4, 1, 100);
jeu = instadd(jeu, 'Swap', [0.04 0], '01-Jan-2024', '01-Jan-2029', [2 4], 1, 100);
jeu = instadd(jeu, 'CashFlow', [5 5 105], ...
              datenum([2025 2026 2027], 1, 1), '01-Jan-2024', 1);
p = intenvprice(courbe, jeu);
fprintf('prix : %s\n', sprintf('%10.5f', p));
assert(numel(p) == 6 && all(isfinite(p)));
% Chaque prix retrouve celui de la fonction dediee.
assert(abs(p(1) - bondbyzero(courbe, 0.05, '01-Jan-2024', '01-Jan-2029', 2, 1)) < 1e-9);
assert(abs(p(3) - fixedbyzero(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 2, 1, 100)) < 1e-9);
assert(abs(p(4) - floatbyzero(courbe, 0, '01-Jan-2024', '01-Jan-2029', 4, 1, 100)) < 1e-9);
assert(abs(p(5) - (p(3) - p(4))) < 1e-9);
assert(abs(p(6) - cfbyzero(courbe, [5 5 105], datenum([2025 2026 2027], 1, 1), '01-Jan-2024', 1)) < 1e-9);
% Les sensibilites sont les derivees du prix.
[d, g, p2] = intenvsens(courbe, jeu);
assert(max(abs(p - p2)) < 1e-12);
fprintf('delta : %s\n', sprintf('%10.4f', d));
% Une obligation perd de la valeur quand les taux montent.
assert(all(d(1:3) < 0));
% La branche variable en gagne, comme la sensibilite d'un echange payeur
% de fixe.
assert(d(4) > 0);
% La sensibilite d'une obligation vaut moins sa duration modifiee fois
% son prix.
[dm] = bnddurp(p(1), 0.05, '01-Jan-2024', '01-Jan-2029', 2, 1);
fprintf('delta obligation %.4f, -duration*prix %.4f\n', d(1), -dm * p(1));
assert(abs(d(1) + dm * p(1)) / abs(d(1)) < 0.03);

%% ---------------------------------------------- arbres binomiaux
% Un arbre fin retrouve Black et Scholes pour une option europeenne, et
% pour un achat americain sans dividende, qui ne s'exerce jamais avant.
S = 100; K = 95; r = 0.05; T = 1; sigma = 0.25;
[sArbre, vArbre] = binprice(S, K, r, T, T / 400, sigma, 1);
attendu = blsprice(S, K, r, T, sigma);
fprintf('binprice achat americain %.6f, Black-Scholes %.6f\n', vArbre(1, 1), attendu);
assert(abs(vArbre(1, 1) - attendu) < 0.02);
% L'arbre des cours est bien recombinant : le nœud haut-bas rejoint le
% cours initial.
assert(abs(sArbre(2, 3) - S) < 1e-9);
% Une vente americaine vaut plus que l'europeenne.
[~, vAmericaine] = binprice(S, K, r, T, T / 400, sigma, 0);
[~, europeenne] = blsprice(S, K, r, T, sigma);
fprintf('vente americaine %.6f, europeenne %.6f\n', vAmericaine(1, 1), europeenne);
assert(vAmericaine(1, 1) > europeenne);
% Et jamais moins que son gain immediat.
assert(vAmericaine(1, 1) >= max(K - S, 0));
% Un dividende en especes abaisse l'achat et releve la vente.
[~, sansDividende] = binprice(S, K, r, T, T / 200, sigma, 1);
[~, avecDividende] = binprice(S, K, r, T, T / 200, sigma, 1, 0, 5, 0.5);
fprintf('achat sans dividende %.6f, avec %.6f\n', sansDividende(1,1), avecDividende(1,1));
assert(avecDividende(1, 1) < sansDividende(1, 1));
% Arbre par objets : meme resultat que binprice.
c = intenvset('Rates', r, 'StartDates', '01-Jan-2024', 'EndDates', '31-Dec-2024', ...
              'Compounding', -1, 'Basis', 0);
s = stockspec(sigma, S);
temps = crrtimespec('01-Jan-2024', '31-Dec-2024', 300);
arbre = crrtree(s, c, temps);
jeu = instadd('OptStock', {'call'; 'put'}, [K; K], '01-Jan-2024', ...
              datenum('31-Dec-2024'), [1; 1]);
p = crrprice(arbre, jeu);
Teff = yearfrac('01-Jan-2024', '31-Dec-2024', 0);
fprintf('crrprice : %s\n', sprintf('%10.5f', p));
assert(abs(p(1) - blsprice(S, K, r, Teff, sigma)) < 0.02);
assert(p(2) > 0);
% Les sensibilites de l'arbre approchent les grecques.
[d, g, v, p2] = crrsens(arbre, jeu);
fprintf('delta arbre %.5f, formule %.5f\n', d(1), blsdelta(S, K, r, Teff, sigma));
assert(abs(d(1) - blsdelta(S, K, r, Teff, sigma)) < 0.01);
fprintf('gamma arbre %.6f, formule %.6f\n', g(1), blsgamma(S, K, r, Teff, sigma));
assert(abs(g(1) - blsgamma(S, K, r, Teff, sigma)) < 0.002);
fprintf('vega arbre %.4f, formule %.4f\n', v(1), blsvega(S, K, r, Teff, sigma));
assert(abs(v(1) - blsvega(S, K, r, Teff, sigma)) < 0.5);
assert(max(abs(p - p2)) < 1e-12);
% Un pas trop grand est refuse plutot que de donner une probabilite hors
% de [0, 1].
refuse = false;
try
    binprice(100, 95, 0.5, 1, 1, 0.05, 1);
catch e
    refuse = strcmp(e.identifier, 'finstr:binprice:Probabilite');
end
assert(refuse);

%% ----------------------------- plafonds et options sur echange
courbe = intenvset('Rates', [0.030; 0.032; 0.034; 0.036; 0.038; 0.040], ...
                   'StartDates', '01-Jan-2024', ...
                   'EndDates', datenum([2025 2026 2027 2029 2031 2034], 1, 1)', ...
                   'Compounding', 2, 'Basis', 1);
% Parite plafond-plancher : cap - floor vaut l'echange payeur de fixe.
K = 0.04;
cap = capbyblk(courbe, K, '01-Jan-2024', '01-Jan-2029', 0.2, 2, 1, 100);
plancher = floorbyblk(courbe, K, '01-Jan-2024', '01-Jan-2029', 0.2, 2, 1, 100);
[echange, tauxEchange] = swapbyzero(courbe, [K 0], '01-Jan-2024', '01-Jan-2029', [2 2], 1, 100);
fprintf('cap %.6f, floor %.6f, cap-floor %.6f, echange payeur %.6f\n', ...
        cap, plancher, cap - plancher, -echange);
assert(abs((cap - plancher) - (-echange)) < 1e-8);
% Un plafond tres haut ne vaut presque rien, un plafond a zero vaut
% l'echange.
assert(capbyblk(courbe, 5, '01-Jan-2024', '01-Jan-2029', 0.2, 2, 1, 100) < 1e-6);
capZero = capbyblk(courbe, 1e-8, '01-Jan-2024', '01-Jan-2029', 0.2, 2, 1, 100);
echangeZero = swapbyzero(courbe, [0 0], '01-Jan-2024', '01-Jan-2029', [2 2], 1, 100);
fprintf('cap a zero %.6f, echange %.6f\n', capZero, -echangeZero);
assert(abs(capZero - (-echangeZero)) < 1e-4);
% Le prix croit avec la volatilite.
assert(capbyblk(courbe, K, '01-Jan-2024', '01-Jan-2029', 0.3, 2) > ...
       capbyblk(courbe, K, '01-Jan-2024', '01-Jan-2029', 0.2, 2));
% Options sur echange : payeur moins receveur vaut l'echange a terme.
payeur = swaptionbyblk(courbe, 'call', K, '01-Jan-2024', '01-Jan-2026', '01-Jan-2031', 0.2, 2, 1, 100);
receveur = swaptionbyblk(courbe, 'put', K, '01-Jan-2024', '01-Jan-2026', '01-Jan-2031', 0.2, 2, 1, 100);
fprintf('payeur %.6f, receveur %.6f, ecart %.6f\n', payeur, receveur, payeur - receveur);
% L'ecart doit valoir l'annuite fois (taux a terme - exercice).
dates = matlibre_dates_reset(datenum('01-Jan-2026'), datenum('01-Jan-2031'), 2);
facteurs = matlibre_courbe_escompte(courbe, dates);
durees = zeros(numel(dates), 1);
precedentes = [datenum('01-Jan-2026'); dates(1:end-1)'];
for k = 1:numel(dates)
    durees(k) = yearfrac(precedentes(k), dates(k), 1);
end
annuite = sum(durees .* facteurs(:));
debut = matlibre_courbe_escompte(courbe, datenum('01-Jan-2026'));
terme = (debut(1) - facteurs(end)) / annuite;
fprintf('taux a terme %.6f, ecart attendu %.6f\n', terme, 100 * annuite * (terme - K));
assert(abs((payeur - receveur) - 100 * annuite * (terme - K)) < 1e-8);
% Le payeur vaut plus que sa valeur intrinseque.
assert(payeur >= max(100 * annuite * (terme - K), 0) - 1e-9);

%% ------------------------------- protection contre le defaut
reglement = '01-Jan-2024';
taux = [datenum([2025 2026 2027 2029 2031], 1, 1)', [0.03; 0.032; 0.034; 0.036; 0.038]];
marche = [datenum([2025 2026 2027 2029], 1, 1)', [80; 100; 120; 150]];
[prob, hasard] = cdsbootstrap(taux, marche, reglement);
fprintf('probabilites de defaut : %s\n', sprintf('%9.5f', prob(:, 2)));
fprintf('taux de hasard         : %s\n', sprintf('%9.5f', hasard(:, 2)));
% Les probabilites cumulees croissent, et restent dans [0, 1].
assert(all(diff(prob(:, 2)) > 0) && all(prob(:, 2) > 0) && all(prob(:, 2) < 1));
% Le taux de hasard moyen jusqu'a chaque echeance approche l'ecart divise
% par un moins la recuperation : c'est le « triangle du credit ». Les
% taux rendus par l'amorcage sont des taux a terme, plus eleves que leur
% moyenne quand la courbe d'ecarts monte.
duree = (marche(:, 1) - datenum(reglement)) / 365;
moyen = -log(1 - prob(:, 2)) ./ duree;
approximation = marche(:, 2) / 10000 / (1 - 0.4);
fprintf('hasard moyen           : %s\n', sprintf('%9.5f', moyen));
fprintf('triangle du credit     : %s\n', sprintf('%9.5f', approximation));
assert(max(abs(moyen - approximation) ./ approximation) < 0.06);
assert(all(hasard(:, 2) >= moyen - 1e-9));
% L'amorcage retrouve les ecarts cotes.
retrouves = cdsspread(taux, prob, reglement, marche(:, 1));
fprintf('ecarts retrouves : %s\n', sprintf('%9.4f', retrouves));
fprintf('ecarts cotes     : %s\n', sprintf('%9.4f', marche(:, 2)));
assert(max(abs(retrouves - marche(:, 2))) < 1e-6);
% Au taux du marche, le contrat vaut zero.
p = cdsprice(taux, prob, reglement, datenum('01-Jan-2029'), retrouves(4), 0.4, 4, 2, 1e7);
fprintf('prix a l''ecart du marche : %.6e\n', p);
assert(abs(p) < 1e-4);
% Un contrat conclu moins cher que le marche vaut quelque chose.
pBon = cdsprice(taux, prob, reglement, datenum('01-Jan-2029'), 100, 0.4, 4, 2, 1e7);
fprintf('prix a 100 pb (marche %.1f) : %.2f\n', retrouves(4), pBon);
assert(pBon > 0);
pCher = cdsprice(taux, prob, reglement, datenum('01-Jan-2029'), 200, 0.4, 4, 2, 1e7);
assert(pCher < 0);
% Le prix est lineaire en l'ecart du contrat.
pMilieu = cdsprice(taux, prob, reglement, datenum('01-Jan-2029'), 150, 0.4, 4, 2, 1e7);
assert(abs(pMilieu - (pBon + pCher) / 2) < 1e-6);
% Un taux de recuperation plus eleve reduit la protection, donc l'ecart.
ecartFaible = cdsspread(taux, prob, reglement, datenum('01-Jan-2029'), 0.7);
fprintf('ecart a 70 %% de recuperation : %.4f (contre %.4f)\n', ecartFaible, retrouves(4));
assert(ecartFaible < retrouves(4));

disp('instruments financiers : toutes les verifications passent');
