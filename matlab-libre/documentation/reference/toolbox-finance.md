# Toolbox `finance`

```
% Financial Toolbox — finance quantitative.
%
% Dates de marché
%   yearfrac            - Fraction d'année, selon quatorze conventions
%   daysact, daysdif    - Jours réels, jours selon une convention
%   days360, days360e   - Conventions 30/360 américaine et européenne
%   days360psa, days360isda - Les deux autres variantes
%   days365             - Année de 365 jours, sans les 29 février
%   datemnth, datewrkdy - Date située un nombre de mois, de jours ouvrés
%   wrkdydif            - Nombre de jours ouvrés entre deux dates
%   holidays            - Jours fériés des marchés américains
%   isbusday, busdate   - Jour ouvré ? Jour ouvré suivant
%   lbusdate, fbusdate  - Dernier et premier jour ouvré d'un mois
%   nweekdate, lweekdate - N-ième et dernier jour de semaine d'un mois
%   thirdwednesday      - Échéances trimestrielles des contrats à terme
%   m2xdate, x2mdate    - Conversion des numéros de série d'Excel
%
% Valeur temporelle de l'argent
%   pv, fv, npv, irr, mirr - Valeurs actuelle et future, VAN, TRI
%   pvfix, fvfix        - Versements constants
%   pvvar, fvvar        - Flux quelconques, à dates quelconques
%   payper, payadv, payodd, payuni - Versement périodique et ses variantes
%   annurate, annuterm  - Taux et durée d'une annuité
%   amortize            - Tableau d'amortissement d'un emprunt
%   effrr, nomrr        - Taux effectif et nominal
%
% Amortissements comptables
%   depstln, depsoyd    - Linéaire, somme des numéros d'années
%   depfixdb, depgendb  - Dégressifs, à taux fixe et à taux général
%   deprdv              - Valeur restant à amortir
%
% Titres à escompte et bons du Trésor
%   prdisc, ylddisc, discrate, fvdisc - Prix, rendement, escompte, valeur
%   acrudisc, acrubond  - Intérêts courus
%   prmat, yldmat       - Titres payant l'intérêt à l'échéance
%   prtbill, yldtbill, beytbill - Bons du Trésor
%
% Obligations
%   cfdates, cfamounts  - Dates et montants des flux
%   bndprice, bndyield  - Prix et rendement à l'échéance
%   bnddurp, bnddury    - Sensibilité, depuis le prix ou le rendement
%   bndconvp, bndconvy  - Convexité, de même
%   bndspread           - Écart de crédit sur une courbe
%   cfprice, cfyield, cfdur, cfconv - Les mêmes, sur des flux quelconques
%
% Courbes de taux
%   zero2disc, disc2zero - Taux zéro-coupon et facteurs d'actualisation
%   zero2fwd, fwd2zero   - Taux à terme
%   zero2pyld, pyld2zero - Taux au pair
%   zbtprice, zbtyield   - Amorçage d'une courbe depuis des obligations
%   prbyzero             - Prix d'obligations sur une courbe
%   ratetimes            - Changement d'intervalles
%
% Options
%   blsprice, blsimpv   - Prix et volatilité implicite
%   blsdelta, blsgamma, blsvega, blstheta, blsrho, blslambda - Grecques
%   opprofit            - Gain à l'échéance
%
% Portefeuilles
%   portstats, portvar, portalloc - Rendement, variance, allocation
%   portopt, frontcon   - Frontière efficiente
%   portcons, pcpval, pcalims, pcglims - Jeux de contraintes
%   portrand, portsim   - Portefeuilles au hasard, rendements simulés
%   ewstats             - Moyenne et covariance pondérées
%   corr2cov, cov2corr  - Covariance, corrélations et écarts types
%   holdings2weights, weights2holdings - Quantités et poids
%
% Mesures de performance et de risque
%   sharpe, inforatio   - Ratios de Sharpe et d'information
%   portalpha           - Excès de rendement corrigé du risque
%   maxdrawdown, emaxdrawdown - Recul maximal, observé et attendu
%   lpm, elpm           - Moments partiels inférieurs
%   portvrisk           - Valeur en risque gaussienne
%   totalreturnprice    - Série réinvestissant les dividendes
%   tick2ret, ret2tick, price2ret, ret2price - Cours et rendements
%
% Analyse technique
%   movavg, bolling, bollinger - Moyennes mobiles et bandes
%   medprice, typprice, wclose - Prix dérivés d'une séance
%   hhigh, llow         - Extrêmes d'une fenêtre glissante
%   rsindex, willpctr   - Force relative, indicateur de Williams
%   macd                - Convergence et divergence des moyennes
%   stochosc, fpctkd, spctkd - Stochastiques rapides et lentes
%   adline, adosc, williamsad - Accumulation et distribution
%   chaikosc, chaikvolat - Oscillateur et volatilité de Chaikin
%   onbalvol, negvolidx, posvolidx, pvtrend - Indicateurs de volume
%   prcroc, volroc, tsmom, tsaccel - Variations, élan, accélération
%   highlow, pointfig   - Barres de cotation, points et figures
%
% Écriture des montants
%   cur2str, cur2frac, frac2cur - Sommes d'argent et fractions
%   dec2thirtytwo, thirtytwo2dec - Trente-deuxièmes des cours obligataires
```

## `acrubond`

```
ACRUBOND Intérêts courus d'une obligation à coupons.
  I = ACRUBOND(EMISSION,REGLEMENT,PREMIERCOUPON,FACE,TAUX) rend les
  intérêts courus depuis le dernier coupon jusqu'à la date de
  règlement.

  Une obligation vendue entre deux coupons se paie au prix coté plus
  les intérêts courus : le vendeur a droit à la part du coupon qui
  correspond au temps où il détenait le titre, et c'est l'acheteur qui
  touchera le coupon entier.

  Exemple :
     acrubond('01-Jan-2024', '15-Mar-2024', '01-Jul-2024', 100, 0.05, 2, 0)

  Voir aussi ACRUDISC, BNDPRICE, CFAMOUNTS.
```

## `acrudisc`

```
ACRUDISC Intérêts courus d'un titre vendu à escompte.
  I = ACRUDISC(REGLEMENT,ECHEANCE,FACE,ESCOMPTE) rend l'écart entre la
  valeur de remboursement et le prix : c'est ce que le titre a couru
  d'intérêt à la date de règlement.

  Exemple :
     acrudisc('01-Feb-2024', '01-Aug-2024', 100, 0.05, 2, 2)

  Voir aussi ACRUBOND, PRDISC, DISCRATE.
```

## `adline`

```
ADLINE Ligne d'accumulation et de distribution.
  A = ADLINE(HAUT,BAS,CLOTURE,VOLUME) cumule, séance après séance, le
  volume affecté d'un signe : positif si la clôture est près du plus
  haut, négatif si elle est près du plus bas.

  L'idée est que la place de la clôture dans l'amplitude du jour dit
  qui, des acheteurs ou des vendeurs, a eu le dernier mot ; le volume
  dit avec quelle force.

  Exemple :
     adline(hauts, bas, clotures, volumes)

  Voir aussi ADOSC, CHAIKOSC, ONBALVOL, WILLIAMSAD.
```

## `adosc`

```
ADOSC Oscillateur d'accumulation et de distribution.
  O = ADOSC(OUVERTURE,HAUT,BAS,CLOTURE) rend, pour chaque séance, la
  part de l'amplitude gagnée par les acheteurs : la hausse depuis
  l'ouverture plus la hausse depuis le plus bas, rapportées au double
  de l'amplitude.

  L'indicateur vaut un quand la séance ouvre au plus bas et clôture au
  plus haut, zéro dans le cas contraire.

  Exemple :
     adosc(ouvertures, hauts, bas, clotures)

  Voir aussi ADLINE, CHAIKOSC, WILLIAMSAD.
```

## `amortize`

```
AMORTIZE Tableau d'amortissement d'un emprunt.
  [C,I,S,V] = AMORTIZE(TAUX,N,PV) rend, période par période, la part de
  capital remboursée, la part d'intérêt payée et le solde restant dû,
  ainsi que le versement constant.

  La somme des deux parts est le versement, à chaque période. La part
  d'intérêt est le taux appliqué au solde de la période précédente :
  elle décroît à mesure que le capital est remboursé, et la part de
  capital croît d'autant.

  Exemple :
     [c, i, s, v] = amortize(0.06 / 12, 12, 10000);
     sum(c)                       % 10000 : tout le capital

  Voir aussi PAYPER, ANNURATE, ANNUTERM, PAYODD.
```

## `annurate`

```
ANNURATE Taux d'intérêt d'une annuité.
  R = ANNURATE(N,VERSEMENT,PV) rend le taux par période tel que N
  versements remboursent exactement PV. ANNURATE(...,FV,TERME) laisse
  un solde et choisit le moment du versement.

  L'équation n'a pas de solution fermée : le taux est trouvé par
  recherche de zéro sur la valeur actuelle, qui décroît quand le taux
  monte, ce qui garantit l'unicité.

  Exemple :
     annurate(12, 100, 1000)      % 0.0292 par periode

  Voir aussi ANNUTERM, PAYPER, IRR, PVFIX.
```

## `annuterm`

```
ANNUTERM Nombre de périodes d'une annuité.
  N = ANNUTERM(TAUX,VERSEMENT,PV) rend le nombre de versements qui
  remboursent PV au taux TAUX. Le résultat n'est pas entier en
  général : la dernière échéance est partielle.

  Exemple :
     annuterm(0.06 / 12, 500, 20000)     % 44.7 mois

  Voir aussi ANNURATE, PAYPER, PVFIX.
```

## `beytbill`

```
BEYTBILL Rendement d'un bon du Trésor, équivalent obligataire.
  R = BEYTBILL(REGLEMENT,ECHEANCE,ESCOMPTE) convertit un taux
  d'escompte de bon du Trésor en rendement comparable à celui d'une
  obligation : la base passe de trois cent soixante jours à trois cent
  soixante-cinq, et le taux se rapporte au prix payé, non à la valeur
  de remboursement.

  Sans cette conversion, un bon et une obligation de même rendement
  réel afficheraient des taux différents.

  Exemple :
     beytbill('01-Feb-2024', '01-Aug-2024', 0.05)

  Voir aussi PRTBILL, YLDTBILL, YLDDISC.
```

## `blsdelta`

```
BLSDELTA Sensibilité du prix au cours du sous-jacent.
```

## `blsgamma`

```
BLSGAMMA Courbure du prix d'une option par rapport au cours.
  G = BLSGAMMA(S,K,R,T,SIGMA) rend la dérivée seconde du prix par
  rapport au cours du sous-jacent — autrement dit, la vitesse à
  laquelle le delta change.

  Le gamma est le même pour l'achat et pour la vente : la parité
  achat-vente ne fait intervenir que des termes linéaires en S.

  Exemple :
     blsgamma(100, 100, 0.05, 1, 0.2)

  Voir aussi BLSPRICE, BLSDELTA, BLSVEGA, BLSTHETA, BLSRHO.
```

## `blsimpv`

```
BLSIMPV Volatilité implicite d'une option.
  SIGMA = BLSIMPV(S,K,R,T,PRIX) rend la volatilité qui, mise dans la
  formule de Black et Scholes, redonne le prix observé.

  BLSIMPV(...,LIMITE) borne la recherche (10 par défaut),
  BLSIMPV(...,DIVIDENDE) donne le taux de dividende continu,
  BLSIMPV(...,TOLERANCE) la précision voulue, BLSIMPV(...,TYPE) vaut
  true ou 'call' pour un achat — le défaut — et false ou 'put' pour une
  vente.

  Le prix croît strictement avec la volatilité, ce qui rend la solution
  unique : elle se trouve par dichotomie. Le marché ne cote pas la
  volatilité, il cote des prix ; c'est en les inversant qu'on lit ce
  qu'il anticipe.

  Exemple :
     c = blsprice(100, 100, 0.05, 1, 0.2);
     blsimpv(100, 100, 0.05, 1, c)         % 0.2

  Voir aussi BLSPRICE, BLSVEGA, BLSDELTA.
```

## `blslambda`

```
BLSLAMBDA Élasticité du prix d'une option au cours du sous-jacent.
  [LC,LP] = BLSLAMBDA(S,K,R,T,SIGMA) rend la variation relative du prix
  pour une variation relative du cours : le delta multiplié par le
  cours et divisé par le prix.

  C'est la mesure de l'effet de levier. Une option très en dehors de la
  monnaie a un delta faible mais une élasticité énorme : elle coûte peu
  et double de valeur pour quelques pour cent de hausse.

  Exemple :
     blslambda(100, 100, 0.05, 1, 0.2)

  Voir aussi BLSDELTA, BLSPRICE, BLSGAMMA.
```

## `blsprice`

```
BLSPRICE Prix d'options européennes par la formule de Black-Scholes.
  [C,P] = BLSPRICE(S,K,R,T,SIGMA) rend les prix de l'achat et de la
  vente. Q est le taux de dividende continu (zéro par défaut).
```

## `blsrho`

```
BLSRHO Sensibilité du prix d'une option au taux d'intérêt.
  [RC,RP] = BLSRHO(S,K,R,T,SIGMA) rend la dérivée du prix par rapport
  au taux sans risque. Elle est positive pour un achat, négative pour
  une vente : un taux plus élevé abaisse la valeur actuelle du prix
  d'exercice.

  Exemple :
     blsrho(100, 100, 0.05, 1, 0.2)

  Voir aussi BLSPRICE, BLSDELTA, BLSGAMMA, BLSVEGA, BLSTHETA.
```

## `blstheta`

```
BLSTHETA Perte de valeur d'une option avec le temps.
  [TC,TP] = BLSTHETA(S,K,R,T,SIGMA) rend la dérivée du prix par rapport
  au temps qui passe : elle est presque toujours négative, une option
  perdant de la valeur à mesure que l'échéance approche.

  Exemple :
     blstheta(100, 100, 0.05, 1, 0.2)

  Voir aussi BLSPRICE, BLSDELTA, BLSGAMMA, BLSVEGA, BLSRHO.
```

## `blsvega`

```
BLSVEGA Sensibilité du prix d'une option à la volatilité.
  V = BLSVEGA(S,K,R,T,SIGMA) rend la dérivée du prix par rapport à la
  volatilité. Elle est la même pour l'achat et pour la vente, et elle
  est maximale quand l'option est à la monnaie.

  Exemple :
     blsvega(100, 100, 0.05, 1, 0.2)

  Voir aussi BLSPRICE, BLSGAMMA, BLSIMPV, BLSTHETA.
```

## `bndconvp`

```
BNDCONVP Convexité d'une obligation, à partir de son prix.
  Même chose que BNDCONVY, le rendement étant d'abord déduit du prix.

  Voir aussi BNDCONVY, BNDDURP, BNDYIELD.
```

## `bndconvy`

```
BNDCONVY Convexité d'une obligation, à partir de son rendement.
  [CA,CP] = BNDCONVY(RENDEMENT,TAUX,REGLEMENT,ECHEANCE) rend la
  convexité en années au carré et en périodes au carré.

  La sensibilité seule décrit une droite : elle sous-estime le prix
  quand le rendement baisse et le surestime quand il monte. La
  convexité est la courbure qui corrige cet écart — la dérivée seconde
  du prix par rapport au rendement, rapportée au prix.

  Exemple :
     bndconvy(0.06, 0.05, '01-Feb-2024', '01-Feb-2034')

  Voir aussi BNDCONVP, BNDDURY, CFCONV.
```

## `bnddurp`

```
BNDDURP Sensibilité d'une obligation, à partir de son prix.
  Même chose que BNDDURY, le rendement étant d'abord déduit du prix.

  Exemple :
     bnddurp(92.5, 0.05, '01-Feb-2024', '01-Feb-2034')

  Voir aussi BNDDURY, BNDCONVP, BNDYIELD.
```

## `bnddury`

```
BNDDURY Sensibilité d'une obligation, à partir de son rendement.
  [DM,DA,DP] = BNDDURY(RENDEMENT,TAUX,REGLEMENT,ECHEANCE) rend la
  sensibilité modifiée, la duration de Macaulay en années et la même en
  périodes.

  La duration de Macaulay est la date moyenne des flux, pondérée par
  leur valeur actuelle : c'est la durée au bout de laquelle un
  détenteur récupère en moyenne son argent. La sensibilité modifiée en
  est la duration divisée par un plus le rendement par période : elle
  dit de combien de pour cent le prix baisse quand le rendement monte
  d'un point.

  Exemple :
     bnddury(0.06, 0.05, '01-Feb-2024', '01-Feb-2034')

  Voir aussi BNDDURP, BNDCONVY, BNDPRICE, CFDUR.
```

## `bndprice`

```
BNDPRICE Prix d'une obligation à coupons, à partir de son rendement.
  [P,I] = BNDPRICE(RENDEMENT,TAUX,REGLEMENT,ECHEANCE) rend le prix
  coté, pour cent de nominal, et les intérêts courus. Le prix payé est
  la somme des deux.

  PERIODE vaut 2 par défaut, BASE 0. Le rendement est composé PERIODE
  fois par an, comme le veut la convention obligataire.

  Le prix est la valeur actuelle des flux à venir. Quand le rendement
  égale le taux de coupon, elle vaut exactement le nominal : c'est la
  définition du pair. Au-dessus, le titre cote en dessous du pair,
  puisqu'il faut un gain en capital pour compenser un coupon trop
  faible.

  Exemple :
     bndprice(0.06, 0.05, '01-Feb-2024', '01-Feb-2034')

  Voir aussi BNDYIELD, BNDDURP, BNDDURY, BNDCONVP, CFAMOUNTS.
```

## `bndspread`

```
BNDSPREAD Écart de taux d'une obligation par rapport à une courbe.
  E = BNDSPREAD(PRIX,TAUX,REGLEMENT,ECHEANCE,TAUXZERO,DATESZERO) rend,
  en points de base, l'écart constant qu'il faut ajouter à toute la
  courbe zéro-coupon pour que le prix calculé soit le prix observé.

  C'est la mesure du risque de crédit d'un émetteur : l'écart dit ce
  que le marché exige au-delà du taux sans risque, à chaque échéance.

  Exemple :
     bndspread(97, 0.05, '01-Feb-2024', '01-Feb-2029', ...
               [0.03; 0.035], [datenum('01-Feb-2026'); datenum('01-Feb-2029')])

  Voir aussi PRBYZERO, ZBTPRICE, BNDYIELD, BNDPRICE.
```

## `bndyield`

```
BNDYIELD Rendement à l'échéance d'une obligation.
  R = BNDYIELD(PRIX,TAUX,REGLEMENT,ECHEANCE) rend le taux qui, appliqué
  à tous les flux, redonne le prix observé. C'est l'inverse de
  BNDPRICE.

  Le prix décroît strictement avec le rendement : la solution est donc
  unique, et se trouve par recherche de zéro.

  Exemple :
     p = bndprice(0.06, 0.05, '01-Feb-2024', '01-Feb-2034');
     bndyield(p, 0.05, '01-Feb-2024', '01-Feb-2034')     % 0.06

  Voir aussi BNDPRICE, BNDDURP, CFYIELD, IRR.
```

## `bolling`

```
BOLLING Bandes de Bollinger.
  [M,H,B] = BOLLING(COURS,N,ALPHA,LARGEUR) rend une moyenne mobile sur
  N séances et deux bandes situées à LARGEUR écarts types de part et
  d'autre. ALPHA pondère la moyenne : zéro pour une moyenne
  arithmétique — le défaut —, un pour une moyenne linéaire, deux pour
  une moyenne quadratique. LARGEUR vaut deux.

  L'écart type est celui des N dernières séances : les bandes se
  resserrent quand le marché est calme et s'écartent quand il s'agite.
  Un cours qui sort de la bande n'annonce rien par lui-même ; c'est
  l'écartement soudain qui se remarque.

  Exemple :
     [m, h, b] = bolling(clotures, 20, 0, 2);

  Voir aussi BOLLINGER, MOVAVG, CHAIKVOLAT.
```

## `bollinger`

```
BOLLINGER Bandes de Bollinger, dans l'ordre d'arguments moderne.
  [M,H,B] = BOLLINGER(COURS,FENETRE,LARGEUR,ALPHA) fait ce que fait
  BOLLING, les deux derniers arguments étant échangés.

  Exemple :
     [m, h, b] = bollinger(clotures, 20, 2);

  Voir aussi BOLLING, MOVAVG.
```

## `busdate`

```
BUSDATE Jour ouvré suivant ou précédent.
  D = BUSDATE(DATE) rend le jour ouvré qui suit DATE. BUSDATE(DATE,-1)
  rend celui qui précède ; BUSDATE(DATE,N) avance de N jours ouvrés, en
  arrière si N est négatif.

  BUSDATE(...,FERIES,WEEKEND) précise les jours chômés et la forme de
  la semaine, comme ISBUSDAY.

  Exemple :
     datestr(busdate('03-Jul-2024'))    % 05-Jul-2024 : le 4 est ferie

  Voir aussi ISBUSDAY, HOLIDAYS, LBUSDATE, FBUSDATE, DATEWRKDY.
```

## `cfamounts`

```
CFAMOUNTS Échéancier complet d'une obligation.
  [M,D,T,F] = CFAMOUNTS(TAUX,REGLEMENT,ECHEANCE) rend les montants, les
  dates, les facteurs de temps en nombre de périodes depuis le
  règlement, et un drapeau par flux.

  Le premier élément est l'intérêt couru, compté négativement : c'est
  ce que l'acheteur verse au vendeur en plus du prix coté. Les suivants
  sont les coupons, et le dernier ajoute le remboursement du nominal.

  Les drapeaux valent 0 pour l'intérêt couru, 1 pour un coupon
  ordinaire, 3 pour le dernier flux.

  Exemple :
     [m, d] = cfamounts(0.05, '01-Feb-2024', '01-Feb-2027');
     [m.' datestr(d.')]

  Voir aussi CFDATES, BNDPRICE, BNDYIELD, ACRUBOND, CFPRICE.
```

## `cfconv`

```
CFCONV Convexité d'une série de flux quelconques.
  C = CFCONV(FLUX,DATES,RENDEMENT) rend la dérivée seconde du prix par
  rapport au rendement, rapportée au prix. CFCONV(FLUX,RENDEMENT) prend
  des flux annuels.

  Exemple :
     cfconv([0 5 5 105], 0.06)

  Voir aussi CFDUR, CFPRICE, BNDCONVY.
```

## `cfdates`

```
CFDATES Dates de coupon d'une obligation.
  D = CFDATES(REGLEMENT,ECHEANCE) rend les dates auxquelles
  l'obligation verse un coupon, entre le règlement et l'échéance
  comprise. PERIODE vaut 2 par défaut : deux coupons par an.

  Le calendrier se construit en reculant depuis l'échéance : c'est elle
  qui commande, non la date de règlement. Une obligation échéant le 31
  août verse ses coupons les 28 ou 29 février, non les 28 août.

  Exemple :
     datestr(cfdates('01-Feb-2024', '15-Aug-2026'))

  Voir aussi CFAMOUNTS, BNDPRICE, ACRUBOND, DATEMNTH.
```

## `cfdur`

```
CFDUR Duration d'une série de flux quelconques.
  [D,DM] = CFDUR(FLUX,DATES,RENDEMENT) rend la duration de Macaulay,
  en années, et la sensibilité modifiée. Le rendement est annuel, à
  capitalisation annuelle.

  CFDUR(FLUX,RENDEMENT) prend les flux à des dates entières, une par
  an, le premier à la date zéro.

  Exemple :
     cfdur([0 5 5 105], 0.06)

  Voir aussi CFCONV, CFPRICE, CFYIELD, BNDDURY.
```

## `cfprice`

```
CFPRICE Prix d'une série de flux, à partir d'un rendement.
  P = CFPRICE(FLUX,DATES,REGLEMENT,RENDEMENT) actualise chaque flux
  depuis sa date jusqu'à la date de règlement. La composition vaut 2
  par défaut, la base 0.

  Exemple :
     cfprice([5 5 105], {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, ...
             '01-Feb-2024', 0.06)

  Voir aussi CFYIELD, CFDUR, CFCONV, BNDPRICE.
```

## `cfyield`

```
CFYIELD Rendement d'une série de flux, à partir de son prix.
  R = CFYIELD(FLUX,DATES,PRIX,REGLEMENT) rend le taux qui redonne le
  prix observé : c'est l'inverse de CFPRICE.

  Exemple :
     d = {'01-Feb-2025','01-Feb-2026','01-Feb-2027'};
     p = cfprice([5 5 105], d, '01-Feb-2024', 0.06);
     cfyield([5 5 105], d, p, '01-Feb-2024')      % 0.06

  Voir aussi CFPRICE, BNDYIELD, IRR.
```

## `chaikosc`

```
CHAIKOSC Oscillateur de Chaikin.
  O = CHAIKOSC(HAUT,BAS,CLOTURE,VOLUME) rend l'écart entre la moyenne
  exponentielle à trois jours et celle à dix jours de la ligne
  d'accumulation et de distribution.

  Une ligne d'accumulation qui monte dit que les acheteurs
  l'emportent ; l'écart de ses deux moyennes dit s'ils l'emportent de
  plus en plus.

  Exemple :
     chaikosc(hauts, bas, clotures, volumes)

  Voir aussi ADLINE, ADOSC, CHAIKVOLAT, MACD.
```

## `chaikvolat`

```
CHAIKVOLAT Volatilité de Chaikin.
  V = CHAIKVOLAT(HAUT,BAS,N,M) mesure la variation, sur M séances, de
  la moyenne exponentielle à N jours de l'amplitude quotidienne. N vaut
  10 par défaut, M aussi.

  Une amplitude qui s'élargit vite annonce souvent un retournement ;
  une amplitude qui se resserre, une phase calme.

  Exemple :
     chaikvolat(hauts, bas, 10, 10)

  Voir aussi CHAIKOSC, ADLINE, PRCROC.
```

## `corr2cov`

```
CORR2COV Covariance construite à partir d'écarts types et de corrélations.
  C = CORR2COV(S,R) rend C(i,j) = S(i)*R(i,j)*S(j). Sans R, les
  variables sont supposées non corrélées.

  Exemple :
     corr2cov([2 3], [1 1/6; 1/6 1])    % [4 1; 1 9]

  Voir aussi COV2CORR, COV, CORRCOEF.
```

## `cov2corr`

```
COV2CORR Corrélations et écarts types tirés d'une covariance.
  [R,S] = COV2CORR(C) sépare la matrice de covariance en une matrice de
  corrélations et un vecteur d'écarts types : C(i,j) = S(i)*R(i,j)*S(j).

  Exemple :
     [r, s] = cov2corr([4 1; 1 9])      % s = [2 3], r(1,2) = 1/6

  Voir aussi CORR2COV, COV, CORRCOEF, EWSTATS.
```

## `cur2frac`

```
CUR2FRAC Montant décimal écrit en fraction.
  T = CUR2FRAC(VALEUR,D) écrit la partie fractionnaire comme un nombre
  de D-ièmes, à la manière des cours obligataires américains : 101.5
  avec un dénominateur de 32 s'écrit 101.16, ces 16 étant des
  trente-deuxièmes.

  Exemple :
     cur2frac(12.125, 8)      % 12.1
     cur2frac(101.5, 32)      % 101.16

  Voir aussi FRAC2CUR, DEC2THIRTYTWO, CUR2STR.
```

## `cur2str`

```
CUR2STR Montant écrit comme une somme d'argent.
  T = CUR2STR(VALEUR,N) écrit la valeur avec N décimales, précédée du
  signe monétaire, les montants négatifs étant mis entre parenthèses
  comme le veut l'usage comptable. N vaut 2 par défaut.

  Exemple :
     cur2str(1234.5)        % $1234.50
     cur2str(-1234.5)       % ($1234.50)

  Voir aussi CUR2FRAC, FRAC2CUR, NUM2STR.
```

## `datemnth`

```
DATEMNTH Date située un nombre de mois plus loin.
  D = DATEMNTH(DEPART,N) rend la date qui tombe N mois après DEPART. Si
  le mois d'arrivée est trop court — le 31 mars plus un mois —, la date
  est ramenée au dernier jour du mois.

  DATEMNTH(...,DRAPEAU) choisit le jour du mois d'arrivée : 0 garde
  celui du départ (défaut), 1 prend le premier du mois, 2 le dernier,
  3 le dernier si le départ était lui-même un dernier jour de mois.
  DATEMNTH(...,BASE,REGLE) : la règle de fin de mois vaut un par
  défaut, ce qui ramène au dernier jour ; zéro l'annule.

  Exemple :
     datestr(datemnth('31-Jan-2024', 1))    % 29-Feb-2024
     datestr(datemnth('15-Jan-2024', 3))    % 15-Apr-2024

  Voir aussi DATEWRKDY, EOMDAY, ADDTODATE, CFDATES.
```

## `datewrkdy`

```
DATEWRKDY Date située un nombre de jours ouvrés plus loin.
  D = DATEWRKDY(DEPART,N) avance de N jours ouvrés, en sautant les
  samedis et les dimanches. DATEWRKDY(DEPART,N,F) traite en plus F
  jours fériés : ils sont ajoutés au décompte, comme le fait MATLAB,
  sans qu'on ait à dire lesquels.

  Exemple :
     datestr(datewrkdy('01-Mar-2024', 5))    % 08-Mar-2024

  Voir aussi WRKDYDIF, BUSDATE, ISBUSDAY, HOLIDAYS.
```

## `days360`

```
DAYS360 Nombre de jours, convention 30/360 américaine.
  N = DAYS360(D1,D2) compte les jours en supposant douze mois de trente
  jours. C'est la convention des obligations d'entreprise américaines :
  elle rend tous les coupons semestriels égaux, ce que le calendrier
  réel ne fait pas.

  Le trente et unième jour d'un mois compte pour le trentième ; si la
  date d'arrivée tombe un trente et un et que celle de départ est déjà
  ramenée au trente, elle l'est aussi.

  Exemple :
     days360('01-Jan-2000', '01-Jan-2001')     % 360
     days360('31-Jan-2000', '29-Feb-2000')     % 29

  Voir aussi DAYS360E, DAYS360ISDA, DAYS360PSA, DAYS365, DAYSACT, YEARFRAC.
```

## `days360e`

```
DAYS360E Nombre de jours, convention 30/360 européenne.
  La différence avec DAYS360 tient au trente et unième jour de la date
  d'arrivée : ici il est toujours ramené au trente, quelle que soit la
  date de départ.

  Exemple :
     days360('01-Jan-2000', '31-Dec-2000')     % 360
     days360e('01-Jan-2000', '31-Dec-2000')    % 359

  Voir aussi DAYS360, DAYS360ISDA, DAYS360PSA, YEARFRAC.
```

## `days360isda`

```
DAYS360ISDA Nombre de jours, convention 30/360 de l'ISDA.
  Le trente et unième jour est ramené au trente des deux côtés, comme
  dans la convention européenne, et la fin de février n'est pas
  allongée.

  Voir aussi DAYS360, DAYS360E, DAYS360PSA, YEARFRAC.
```

## `days360psa`

```
DAYS360PSA Nombre de jours, convention 30/360 de la PSA.
  Elle suit la convention américaine, avec une règle de plus : si la
  date de départ est le dernier jour de février, elle compte pour un
  trente. Sans quoi un coupon partant du 28 février serait plus court
  que les autres.

  Voir aussi DAYS360, DAYS360E, DAYS360ISDA, YEARFRAC.
```

## `days365`

```
DAYS365 Nombre de jours, année de 365 jours.
  N = DAYS365(D1,D2) compte les jours en ignorant les 29 février :
  chaque année compte trois cent soixante-cinq jours, et le rang du
  jour dans l'année se lit sur un calendrier non bissextile.

  Exemple :
     days365('01-Jan-2000', '01-Jan-2001')     % 365
     daysact('01-Jan-2000', '01-Jan-2001')     % 366

  Voir aussi DAYS360, DAYSACT, DAYSDIF, YEARFRAC.
```

## `daysact`

```
DAYSACT Nombre de jours réels entre deux dates.
  N = DAYSACT(D1,D2) rend D2 moins D1, en jours de calendrier. Avec un
  seul argument, DAYSACT(D) compte depuis le 31 décembre de l'an zéro,
  ce qui est le numéro de série lui-même.

  Exemple :
     daysact('01-Jan-2000', '01-Jan-2001')     % 366, annee bissextile

  Voir aussi DAYSDIF, DAYS360, DAYS365, YEARFRAC.
```

## `daysdif`

```
DAYSDIF Nombre de jours entre deux dates, selon une convention de calcul.
  N = DAYSDIF(D1,D2,BASE) compte les jours comme le fait la convention
  BASE — le numérateur de YEARFRAC, avant division par la longueur de
  l'année. Les bases sont celles de YEARFRAC.

  Exemple :
     daysdif('01-Jan-2000', '01-Jan-2001', 0)   % 366
     daysdif('01-Jan-2000', '01-Jan-2001', 1)   % 360

  Voir aussi YEARFRAC, DAYS360, DAYS365, DAYSACT.
```

## `dec2thirtytwo`

```
DEC2THIRTYTWO Cours décimal converti en trente-deuxièmes.
  [E,T] = DEC2THIRTYTWO(VALEUR) sépare la partie entière et le nombre
  de trente-deuxièmes. PRECISION arrondit ces derniers à la fraction
  voulue : 1 pour l'unité, 2 pour le demi, 4 pour le quart.

  Les obligations d'État américaines se cotent ainsi : 101 et 16
  trente-deuxièmes, soit 101,5.

  Exemple :
     [e, t] = dec2thirtytwo(101.5)     % 101 et 16

  Voir aussi THIRTYTWO2DEC, CUR2FRAC, FRAC2CUR.
```

## `depfixdb`

```
DEPFIXDB Amortissement dégressif à taux fixe.
  A = DEPFIXDB(COUT,RESIDUELLE,DUREE,N) applique chaque période le taux
  1 - (RESIDUELLE/COUT)^(1/DUREE) à la valeur nette restante. Ce taux
  est choisi pour que la valeur nette atteigne exactement la valeur
  résiduelle au bout de la durée, sans bascule.

  DEPFIXDB(...,MOIS) traite une première année partielle de MOIS mois ;
  il y a alors une période de plus.

  Exemple :
     depfixdb(10000, 1000, 5, 5)

  Voir aussi DEPGENDB, DEPSTLN, DEPSOYD, DEPRDV.
```

## `depgendb`

```
DEPGENDB Amortissement dégressif à taux constant, avec bascule linéaire.
  A = DEPGENDB(COUT,RESIDUELLE,DUREE,FACTEUR) applique chaque année le
  taux FACTEUR/DUREE à la valeur nette restante, et bascule sur
  l'amortissement linéaire du solde dès que celui-ci donne une annuité
  plus grande. FACTEUR vaut 2 pour le double taux dégressif.

  Sans la bascule, l'amortissement dégressif n'atteint jamais la valeur
  résiduelle : il ne fait que s'en approcher.

  Exemple :
     depgendb(10000, 1000, 5, 2)

  Voir aussi DEPFIXDB, DEPSTLN, DEPSOYD, DEPRDV.
```

## `deprdv`

```
DEPRDV Valeur restant à amortir.
  R = DEPRDV(COUT,RESIDUELLE,AMORTISSEMENTS) rend ce qu'il reste à
  amortir une fois retranchés les amortissements déjà pratiqués.

  Exemple :
     deprdv(10000, 1000, depsoyd(10000, 1000, 5)(1:2))    % 4600

  Voir aussi DEPSTLN, DEPSOYD, DEPFIXDB, DEPGENDB.
```

## `depsoyd`

```
DEPSOYD Amortissement par la somme des numéros d'années.
  A = DEPSOYD(COUT,RESIDUELLE,DUREE) répartit la valeur à amortir
  proportionnellement au nombre d'années restantes : la première annuité
  vaut DUREE parts, la dernière une seule, sur un total de
  DUREE*(DUREE+1)/2 parts.

  C'est un amortissement dégressif qui atteint exactement la valeur
  résiduelle à la fin, ce que l'amortissement à taux constant ne fait
  pas.

  Exemple :
     depsoyd(10000, 1000, 5)      % 3000 2400 1800 1200 600

  Voir aussi DEPSTLN, DEPFIXDB, DEPGENDB, DEPRDV.
```

## `depstln`

```
DEPSTLN Amortissement linéaire.
  A = DEPSTLN(COUT,RESIDUELLE,DUREE) rend l'annuité constante : la
  valeur à amortir, divisée par le nombre d'années.

  Exemple :
     depstln(10000, 1000, 5)      % 1800 par an

  Voir aussi DEPSOYD, DEPFIXDB, DEPGENDB, DEPRDV.
```

## `disc2zero`

```
DISC2ZERO Taux zéro-coupon déduits des facteurs d'actualisation.
  [Z,D] = DISC2ZERO(FACTEURS,DATES,REGLEMENT) convertit chaque facteur
  d'actualisation en le taux annuel qui le produirait. COMPOSITION vaut
  2 par défaut ; -1 demande la composition continue.

  Un facteur d'actualisation dit ce que vaut aujourd'hui un euro reçu
  plus tard ; le taux zéro-coupon dit la même chose sous forme de taux.
  Passer de l'un à l'autre ne fait que changer d'unité.

  Exemple :
     [z, d] = disc2zero([0.99 0.97 0.94], ...
         {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')

  Voir aussi ZERO2DISC, ZERO2FWD, ZERO2PYLD, ZBTPRICE.
```

## `discrate`

```
DISCRATE Taux d'escompte d'un titre.
  E = DISCRATE(REGLEMENT,ECHEANCE,FACE,PRIX) rend le gain rapporté à la
  valeur de remboursement, ramené à l'année. C'est la convention des
  bons du Trésor.

  Exemple :
     discrate('01-Feb-2024', '01-Aug-2024', 100, 97.5, 2)

  Voir aussi PRDISC, YLDDISC, FVDISC, PRTBILL.
```

## `effrr`

```
EFFRR Taux effectif annuel à partir du taux nominal.
```

## `elpm`

```
ELPM Moment partiel inférieur attendu, sous hypothèse gaussienne.
  M = ELPM(MOYENNE,ECART,SEUIL,ORDRE) rend la valeur théorique du
  moment partiel inférieur pour des rendements gaussiens. Comparée au
  moment observé, elle dit si la série perd plus souvent, ou plus
  fort, que la loi normale ne le prévoit.

  Les ordres 0, 1 et 2 ont une forme fermée ; au-delà, l'intégrale est
  calculée numériquement.

  Exemple :
     elpm(0.01, 0.05, 0, 2)

  Voir aussi LPM, PORTVRISK, NORMCDF.
```

## `emaxdrawdown`

```
EMAXDRAWDOWN Recul maximal attendu d'un mouvement brownien.
  E = EMAXDRAWDOWN(DERIVE,DIFFUSION,DUREE) rend l'espérance du plus
  grand recul depuis un sommet, pour un mouvement brownien de dérive
  et de diffusion données, observé pendant la durée voulue.

  Là où MAXDRAWDOWN mesure ce qui s'est produit, celle-ci dit ce qu'il
  fallait attendre. Comparer les deux est la seule façon de savoir si
  un recul observé sort de l'ordinaire : un recul de vingt pour cent
  sur dix ans n'a rien de remarquable, le même sur un mois si.

  Si la dérive et la diffusion décrivent le logarithme du cours, le
  résultat est un recul logarithmique ; le recul relatif s'en déduit
  par 1 - exp(-E).

  Le problème se ramène à une seule fonction d'une variable : par
  changement d'échelle, l'espérance vaut DIFFUSION fois la racine de
  la durée, fois une fonction de DERIVE*racine(DUREE)/DIFFUSION. Cette
  fonction n'a pas de forme fermée commode ; elle est tabulée ici, sur
  quarante mille trajectoires de quatre mille pas par point, avec la
  correction de continuité qui compense ce qu'une grille manque entre
  deux instants. À dérive nulle elle vaut exactement racine de pi sur
  deux, ce que la table reprend.

  Exemple :
     emaxdrawdown(0, 0.2, 1)        % 0.2507 : environ 25 % de la
                                   % volatilite annuelle
     emaxdrawdown(0.1, 0.2, 1)      % moins : la derive protege

  Voir aussi MAXDRAWDOWN, DRAWDOWNSERIES, PORTVRISK.
```

## `ewstats`

```
EWSTATS Moyenne et covariance pondérées exponentiellement.
  [M,C] = EWSTATS(R,FACTEUR) donne plus de poids aux observations
  récentes : le poids décroît d'un facteur constant à chaque pas vers
  le passé. FACTEUR vaut 1 par défaut, ce qui redonne les estimations
  ordinaires.

  EWSTATS(R,FACTEUR,FENETRE) ne retient que les FENETRE dernières
  observations.

  Une covariance estimée sur dix ans traite pareillement la crise
  d'il y a neuf ans et le mois dernier. La pondération exponentielle
  corrige cela sans qu'il faille choisir une date de coupure.

  Exemple :
     [m, c] = ewstats(randn(200, 3), 0.98)

  Voir aussi COV2CORR, CORR2COV, PORTSTATS, COV.
```

## `fbusdate`

```
FBUSDATE Premier jour ouvré d'un mois.
  D = FBUSDATE(ANNEE,MOIS) rend le premier jour du mois qui ne soit ni
  un jour de fin de semaine ni un jour férié.

  Exemple :
     datestr(fbusdate(2024, 1))     % 02-Jan-2024 : le 1er est ferie

  Voir aussi LBUSDATE, BUSDATE, ISBUSDAY.
```

## `fpctkd`

```
FPCTKD Stochastiques rapides.
  [K,D] = FPCTKD(HAUT,BAS,CLOTURE,N,M) rend la place de la clôture dans
  l'amplitude des N dernières séances, en pourcentage, et sa moyenne
  mobile sur M séances. N vaut 10 par défaut, M vaut 3.

  Exemple :
     [k, d] = fpctkd(hauts, bas, clotures);

  Voir aussi SPCTKD, STOCHOSC, WILLPCTR.
```

## `frac2cur`

```
FRAC2CUR Montant fractionnaire converti en décimal.
  V = FRAC2CUR(TEXTE,D) lit la partie après le point comme un nombre de
  D-ièmes. C'est l'inverse de CUR2FRAC.

  Exemple :
     frac2cur('12.1', 8)        % 12.125
     frac2cur('101.16', 32)     % 101.5

  Voir aussi CUR2FRAC, THIRTYTWO2DEC.
```

## `frontcon`

```
FRONTCON Frontière efficiente avec bornes par actif et par groupe.
  [R,M,W] = FRONTCON(MU,SIGMA,N) rend N portefeuilles efficients, les
  poids étant positifs et sommant à un.

  FRONTCON(...,BORNES) donne une matrice à deux lignes, minimums puis
  maximums, une colonne par actif. FRONTCON(...,GROUPES,BORNESGROUPES)
  ajoute des bornes par groupe.

  C'est l'interface ancienne ; PORTOPT accepte des contraintes
  quelconques.

  Exemple :
     mu = [0.10 0.15 0.12];
     s = [0.04 0.01 0.00; 0.01 0.09 0.02; 0.00 0.02 0.06];
     [r, m, w] = frontcon(mu, s, 5, [], [0 0 0; 0.5 0.5 0.5])

  Voir aussi PORTOPT, PORTCONS, PORTSTATS.
```

## `fv`

```
FV Valeur future d'un placement à versements constants.
```

## `fvdisc`

```
FVDISC Valeur future d'un titre vendu à escompte.
  V = FVDISC(REGLEMENT,ECHEANCE,PRIX,ESCOMPTE) rend la valeur de
  remboursement d'un titre acheté à PRIX au taux d'escompte donné.

  Exemple :
     fvdisc('01-Feb-2024', '01-Aug-2024', 97.5, 0.05, 2)

  Voir aussi PRDISC, DISCRATE, YLDDISC.
```

## `fvfix`

```
FVFIX Valeur future d'une série de versements constants.
  V = FVFIX(TAUX,N,VERSEMENT) capitalise N versements au taux TAUX par
  période. FVFIX(...,PV) ajoute un capital de départ ; FVFIX(...,TERME)
  vaut 1 quand les versements tombent en début de période.

  Exemple :
     fvfix(0.05, 10, 1000)      % 12578 : dix versements a 5 %

  Voir aussi PVFIX, FVVAR, PAYPER, FV.
```

## `fvvar`

```
FVVAR Valeur future d'une série de flux quelconques.
  V = FVVAR(FLUX,TAUX) capitalise chaque flux jusqu'à la date du
  dernier. Le premier flux est à la date zéro, et les suivants tombent
  une période plus tard chacun.

  FVVAR(FLUX,TAUX,DATES) donne les dates réelles : le taux est alors
  annuel et les fractions d'année comptées sur 365 jours.

  Exemple :
     fvvar([-10000 2000 3000 4000 5000], 0.08)

  Voir aussi PVVAR, FVFIX, IRR, NPV.
```

## `fwd2zero`

```
FWD2ZERO Courbe zéro-coupon reconstruite à partir des taux à terme.
  C'est l'inverse de ZERO2FWD : les facteurs d'actualisation de chaque
  intervalle se multiplient, et le taux zéro-coupon se lit sur leur
  produit.

  Exemple :
     [z, d] = fwd2zero([0.02 0.03 0.04], ...
         {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')

  Voir aussi ZERO2FWD, ZERO2DISC, RATETIMES.
```

## `hhigh`

```
HHIGH Plus haut d'une fenêtre glissante.
  H = HHIGH(HAUT,N) rend, pour chaque séance, le plus haut des N
  dernières, celle du jour comprise. N vaut 14 par défaut.

  Exemple :
     hhigh([1 3 2 5 4], 3)          % [1 3 3 5 5]

  Voir aussi LLOW, STOCHOSC, WILLPCTR.
```

## `highlow`

```
HIGHLOW Barres de cotation, sous forme de segments.
  [H,B] = HIGHLOW(HAUT,BAS,CLOTURE,OUVERTURE) rend, pour chaque
  séance, les deux extrémités du segment vertical de la barre. Là où
  MATLAB trace, MatLibre rend les valeurs : le tracé se fait ensuite
  avec PLOT.

  Exemple :
     [h, b] = highlow(hauts, bas, clotures, ouvertures);
     plot([1:numel(h); 1:numel(h)], [h.'; b.']);

  Voir aussi CANDLE, POINTFIG, MEDPRICE.
```

## `holdings2weights`

```
HOLDINGS2WEIGHTS Poids d'un portefeuille à partir des quantités détenues.
  P = HOLDINGS2WEIGHTS(QUANTITES,PRIX) rend la part de chaque ligne
  dans la valeur totale. Chaque ligne de QUANTITES est un portefeuille.

  HOLDINGS2WEIGHTS(...,VALEUR) rapporte à une valeur donnée plutôt qu'à
  la somme des lignes.

  Exemple :
     holdings2weights([100 200], [10 5])    % [0.5 0.5]

  Voir aussi WEIGHTS2HOLDINGS, PORTSTATS.
```

## `holidays`

```
HOLIDAYS Jours fériés des marchés américains.
  H = HOLIDAYS(D1,D2) rend les jours où le marché de New York est
  fermé, entre les deux dates. Sans argument, l'intervalle va de 1950 à
  2100.

  Les dates sont calculées à partir des règles, non lues dans une
  table : jour de l'an, anniversaire de Martin Luther King le troisième
  lundi de janvier, anniversaire de Washington le troisième lundi de
  février, vendredi saint, jour du Souvenir le dernier lundi de mai,
  Juneteenth depuis 2022, fête nationale le 4 juillet, fête du travail
  le premier lundi de septembre, Thanksgiving le quatrième jeudi de
  novembre et Noël. Un jour férié tombant un samedi est chômé la veille,
  un dimanche le lendemain.

  Exemple :
     datestr(holidays('01-Jan-2024', '31-Dec-2024'))

  Voir aussi ISBUSDAY, BUSDATE, LBUSDATE, FBUSDATE.
```

## `inforatio`

```
INFORATIO Ratio d'information d'un portefeuille.
  [R,E] = INFORATIO(ACTIF,REFERENCE) rend le rendement moyen en excès
  de la référence, divisé par son écart type, ainsi que cet écart type
  — l'erreur de suivi.

  Le ratio de Sharpe mesure le rendement par unité de risque total ; le
  ratio d'information mesure le rendement par unité de risque pris
  contre la référence. C'est la bonne mesure pour un gérant dont le
  mandat est de battre un indice.

  Exemple :
     inforatio(actif, indice)

  Voir aussi SHARPE, PORTALPHA, MAXDRAWDOWN.
```

## `irr`

```
IRR Taux de rendement interne : le taux qui annule la valeur nette.
```

## `isbusday`

```
ISBUSDAY Le jour est-il ouvré ?
  O = ISBUSDAY(D) vaut un quand D n'est ni un samedi, ni un dimanche,
  ni un jour férié des marchés américains.

  ISBUSDAY(D,FERIES) donne la liste des jours chômés à retenir ; une
  liste vide veut dire « aucun ». ISBUSDAY(D,FERIES,WEEKEND) décrit la
  semaine par sept indicateurs, du dimanche au samedi, un signifiant
  chômé : [1 0 0 0 0 0 1] est le défaut.

  Exemple :
     isbusday('04-Jul-2024')       % 0 : fete nationale
     isbusday('05-Jul-2024')       % 1

  Voir aussi BUSDATE, HOLIDAYS, LBUSDATE, FBUSDATE, WRKDYDIF.
```

## `lbusdate`

```
LBUSDATE Dernier jour ouvré d'un mois.
  D = LBUSDATE(ANNEE,MOIS) rend le dernier jour du mois qui ne soit ni
  un jour de fin de semaine ni un jour férié.

  Exemple :
     datestr(lbusdate(2024, 3))     % 29-Mar-2024 : le 30 est un samedi

  Voir aussi FBUSDATE, BUSDATE, ISBUSDAY, EOMDAY.
```

## `llow`

```
LLOW Plus bas d'une fenêtre glissante.
  B = LLOW(BAS,N) rend, pour chaque séance, le plus bas des N
  dernières. N vaut 14 par défaut.

  Exemple :
     llow([5 3 4 1 2], 3)           % [5 3 3 1 1]

  Voir aussi HHIGH, STOCHOSC, WILLPCTR.
```

## `lpm`

```
LPM Moment partiel inférieur d'une série de rendements.
  M = LPM(DONNEES,SEUIL,ORDRE) rend la moyenne des écarts au seuil,
  élevés à la puissance ORDRE, en ne comptant que les observations
  situées sous le seuil.

  L'écart type punit également les hausses et les baisses ; le moment
  partiel inférieur ne regarde que ce qui déçoit. L'ordre 0 donne la
  fréquence des pertes, l'ordre 1 leur ampleur moyenne, l'ordre 2 une
  semi-variance.

  Exemple :
     lpm(rendements, 0, 2)      % semi-variance sous zero

  Voir aussi ELPM, MAXDRAWDOWN, SHARPE, INFORATIO.
```

## `lweekdate`

```
LWEEKDATE Date du dernier jour de la semaine d'un mois.
  D = LWEEKDATE(J,ANNEE,MOIS) rend la date du dernier jour J du mois. J
  vaut 1 pour dimanche, jusqu'à 7 pour samedi.

  LWEEKDATE(J,ANNEE,MOIS,K) demande de plus que le jour tombe dans la
  même semaine que le K-ième jour de semaine du mois.

  Exemple :
     datestr(lweekdate(2, 2024, 5))    % 27-May-2024, jour du Souvenir

  Voir aussi NWEEKDATE, THIRDWEDNESDAY, HOLIDAYS, WEEKDAY.
```

## `m2xdate`

```
M2XDATE Numéro de série MATLAB converti en numéro Excel.
  E = M2XDATE(D) convertit vers le système de 1900, celui d'Excel sous
  Windows. M2XDATE(D,1) convertit vers celui de 1904.

  Le système de 1900 tient le 29 février 1900 pour un jour existant, ce
  qui est faux : 1900 n'était pas bissextile. L'écart constant de
  693960 jours reproduit cette erreur, sans quoi les dates postérieures
  à février 1900 seraient décalées d'un jour.

  Exemple :
     m2xdate(datenum(2000, 1, 1))     % 36526

  Voir aussi X2MDATE, DATENUM, DATESTR.
```

## `macd`

```
MACD Convergence et divergence des moyennes mobiles.
  [L,S] = MACD(CLOTURE) rend l'écart entre la moyenne exponentielle à
  douze jours et celle à vingt-six, ainsi que la moyenne exponentielle
  à neuf jours de cet écart. Les trois périodes se règlent.

  L'écart de deux moyennes est positif quand la courte est au-dessus de
  la longue, c'est-à-dire quand la tendance récente est plus forte que
  l'ancienne. Le croisement de la ligne et de son signal est ce que
  guettent ses utilisateurs.

  Exemple :
     [l, s] = macd(clotures);

  Voir aussi MOVAVG, RSINDEX, TSMOM, CHAIKOSC.
```

## `matlibre_bls_d`

```
MATLIBRE_BLS_D Les deux arguments de la formule de Black et Scholes.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_case`

```
MATLIBRE_CASE Case K d'un tableau, ou son unique valeur s'il est scalaire.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_colonnes_marche`

```
MATLIBRE_COLONNES_MARCHE Lit une matrice de cotations ou des vecteurs séparés.
  ATTENDUS donne l'ordre des colonnes qu'attend l'appelant, parmi
  'ouverture', 'haut', 'bas', 'cloture', 'volume'. Une matrice à
  plusieurs colonnes est lue dans l'ordre ouverture, haut, bas,
  clôture, volume — celui des tableaux de cotations ; des vecteurs
  séparés sont pris dans l'ordre demandé.

  SERIES est un tableau de cellules, une par nom attendu.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_dates`

```
MATLIBRE_DATES Numéros de série d'une date écrite de n'importe quelle façon.
  Accepte les numéros, le texte, les tableaux de cellules et les
  tableaux de chaînes. Les fonctions financières s'en servent pour
  accepter les mêmes formes que MATLAB sans les répéter.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_densite_normale`

```
MATLIBRE_DENSITE_NORMALE Densité de la loi normale centrée réduite.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_deux_dates`

```
MATLIBRE_DEUX_DATES Composants de deux séries de dates, diffusées.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_diffuser_dates`

```
MATLIBRE_DIFFUSER_DATES Met deux séries de dates à la même taille.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_echeancier`

```
MATLIBRE_ECHEANCIER Dates de coupon postérieures au règlement.
  Les dates sont construites en reculant depuis l'échéance, de douze
  divisé par la fréquence en mois : c'est l'échéance qui fixe le
  calendrier, non la date d'émission. PRECEDENT est la date de coupon
  qui précède le règlement, réelle ou théorique.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_escompte`

```
MATLIBRE_ESCOMPTE Facteur d'actualisation pour une composition donnée.
  COMPOSITION vaut le nombre de capitalisations par an, ou -1 pour la
  composition continue.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_escompte_vers_taux`

```
MATLIBRE_ESCOMPTE_VERS_TAUX Taux zéro-coupon d'une suite de facteurs.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_feries_annee`

```
MATLIBRE_FERIES_ANNEE Jours fériés du marché de New York pour une année.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_flux_obligation`

```
MATLIBRE_FLUX_OBLIGATION Flux d'une obligation décrite par une ligne.
  LIGNE vaut [echeance tauxCoupon face periode base regleFinMois] ;
  seules les deux premières colonnes sont obligatoires.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_indice_volume`

```
MATLIBRE_INDICE_VOLUME Indice qui ne suit le cours que certains jours.
  SENS vaut 1 pour les séances où le volume monte, -1 pour celles où il
  baisse.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_interpoler_courbe`

```
MATLIBRE_INTERPOLER_COURBE Facteurs d'actualisation à des dates quelconques.
  Les taux zéro-coupon sont interpolés linéairement en fonction du
  temps, et prolongés à plat au-delà des bornes de la courbe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jours_composants`

```
MATLIBRE_JOURS_COMPOSANTS Année, mois et jour d'une série de dates.
  Les dates peuvent être des numéros de série, du texte ou un tableau
  de cellules ; la forme du résultat suit celle de l'entrée numérique.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jours_ouvres`

```
MATLIBRE_JOURS_OUVRES Jours ouvrés d'un intervalle, borne de gauche exclue.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_moyenne_exp`

```
MATLIBRE_MOYENNE_EXP Moyenne mobile exponentielle.
  Le poids décroît d'un facteur constant vers le passé ; le facteur est
  celui qu'emploient les analystes, deux divisé par la période plus un,
  choisi pour que la durée moyenne de la pondération soit la période.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_moyenne_simple`

```
MATLIBRE_MOYENNE_SIMPLE Moyenne mobile arithmétique.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_paques`

```
MATLIBRE_PAQUES Dimanche de Pâques grégorien.
  Pâques est le premier dimanche après la première pleine lune
  ecclésiastique qui suit l'équinoxe de printemps. L'algorithme est
  celui, sans conditions, publié anonymement dans Nature en 1876 :
  il traduit directement les règles du comput.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rang_jour`

```
MATLIBRE_RANG_JOUR Rang du jour dans une année non bissextile.
  Le 29 février n'existe pas dans ce calendrier : il est ramené au 28.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_reculer`

```
MATLIBRE_RECULER Date de coupon située NOMBRE périodes avant l'échéance.
  Le calcul part toujours de l'échéance : reculer d'un mois puis d'un
  autre ne donne pas le même résultat que reculer de deux d'un coup,
  dès qu'un mois est plus court que l'autre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_reel_sur_reel`

```
MATLIBRE_REEL_SUR_REEL Fraction d'année, convention réel sur réel.
  La période est découpée par années civiles ; chaque morceau est
  divisé par la longueur de l'année qui le contient. C'est ce qui fait
  qu'une année pleine vaut exactement un, qu'elle soit bissextile ou
  non.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_taux_variation`

```
MATLIBRE_TAUX_VARIATION Variation relative sur un nombre de pas donné.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_taux_vers_escompte`

```
MATLIBRE_TAUX_VERS_ESCOMPTE Facteurs d'actualisation d'une courbe de taux.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `maxdrawdown`

```
MAXDRAWDOWN Perte maximale depuis un sommet.
```

## `medprice`

```
MEDPRICE Prix médian d'une séance.
  P = MEDPRICE(HAUT,BAS) rend la moyenne du plus haut et du plus bas.
  MEDPRICE(COTATIONS) lit une matrice dont les colonnes sont
  l'ouverture, le plus haut, le plus bas et la clôture.

  Exemple :
     medprice([12 10; 14 11])       % [11; 12.5]

  Voir aussi TYPPRICE, WCLOSE, HHIGH, LLOW.
```

## `mirr`

```
MIRR Taux de rendement interne modifié.
  R = MIRR(FLUX,TF,TR) suppose que les décaissements sont financés au
  taux TF et que les encaissements sont replacés au taux TR, jusqu'à la
  fin de la période.

  Le taux de rendement interne ordinaire suppose que chaque
  encaissement est replacé au taux qu'il cherche lui-même, ce qui n'a
  pas de sens quand ce taux est très élevé. Il peut aussi être multiple
  si les flux changent de signe plusieurs fois. Le taux modifié écarte
  les deux difficultés en fixant explicitement les taux de financement
  et de replacement.

  Exemple :
     mirr([-100 30 40 50 20], 0.10, 0.06)

  Voir aussi IRR, PVVAR, FVVAR, NPV.
```

## `movavg`

```
MOVAVG Moyennes mobiles courte et longue.
```

## `negvolidx`

```
NEGVOLIDX Indice des jours de volume en baisse.
  I = NEGVOLIDX(CLOTURE,VOLUME,DEPART) ne suit le cours que les séances
  où le volume a baissé par rapport à la veille ; les autres, l'indice
  ne bouge pas. DEPART vaut 100 par défaut.

  L'idée est que les jours calmes révèlent l'argent avisé, qui
  n'agit pas dans la foule.

  Exemple :
     negvolidx(clotures, volumes)

  Voir aussi POSVOLIDX, ONBALVOL, PVTREND.
```

## `nomrr`

```
NOMRR Taux nominal à partir du taux effectif.
```

## `npv`

```
NPV Valeur actuelle nette : le premier flux est à la date zéro.
```

## `nweekdate`

```
NWEEKDATE Date du n-ième jour de la semaine d'un mois.
  D = NWEEKDATE(N,J,ANNEE,MOIS) rend la date du N-ième jour J du mois.
  J vaut 1 pour dimanche, 2 pour lundi, jusqu'à 7 pour samedi. N va de
  un à cinq ; si le mois ne compte pas N occurrences, le résultat est
  NaN.

  NWEEKDATE(N,J,ANNEE,MOIS,K) demande de plus que le jour tombe dans la
  même semaine que le K-ième jour de semaine du mois — c'est ainsi que
  se définissent certaines échéances de contrats.

  Exemple :
     datestr(nweekdate(3, 2, 2024, 1))   % 15-Jan-2024, Martin Luther King

  Voir aussi LWEEKDATE, THIRDWEDNESDAY, HOLIDAYS, WEEKDAY.
```

## `onbalvol`

```
ONBALVOL Volume à la hausse et à la baisse, cumulé.
  V = ONBALVOL(CLOTURE,VOLUME) ajoute le volume de la séance quand la
  clôture monte, le retranche quand elle baisse, et l'ignore quand elle
  ne bouge pas.

  L'indicateur suppose que le volume précède le cours : une divergence
  entre les deux annoncerait un retournement.

  Exemple :
     onbalvol(clotures, volumes)

  Voir aussi ADLINE, NEGVOLIDX, POSVOLIDX, PVTREND.
```

## `opprofit`

```
OPPROFIT Gain d'une option à l'échéance.
  G = OPPROFIT(COURS,EXERCICE,COUT,POSITION,TYPE) rend le gain net.
  POSITION vaut 0 pour un acheteur, 1 pour un vendeur ; TYPE vaut 0
  pour un achat (call), 1 pour une vente (put).

  À l'échéance, une option ne vaut plus que sa valeur intrinsèque : le
  gain de l'exercice s'il est favorable, zéro sinon. Le gain net
  retranche la prime payée — ou l'ajoute, pour le vendeur.

  Exemple :
     opprofit(110, 100, 5, 0, 0)     % 5 : achat d'un call gagnant
     opprofit(90, 100, 5, 0, 0)      % -5 : la prime est perdue

  Voir aussi BLSPRICE, BINPRICE, BLSDELTA.
```

## `payadv`

```
PAYADV Versement périodique avec des versements payés d'avance.
  V = PAYADV(TAUX,N,PV,FV,A) rend le versement quand A versements sont
  réglés à la signature. Ces versements ne portent pas d'intérêt sur
  les périodes où ils sont réglés, ce qui abaisse le versement dû.

  Exemple :
     payadv(0.09 / 12, 36, 20000, 0, 3)

  Voir aussi PAYPER, PAYODD, PAYUNI, AMORTIZE.
```

## `payodd`

```
PAYODD Versement quand la première période est de longueur inhabituelle.
  V = PAYODD(TAUX,N,PV,FV,JOURS) traite un prêt dont la première
  période compte JOURS jours au lieu des trente d'un mois plein. Les
  jours en trop portent un intérêt simple au prorata, ajouté au capital
  avant que le versement régulier ne soit déterminé ; avec trente
  jours, le résultat est celui de PAYPER.

  Exemple :
     payodd(0.09 / 12, 36, 20000, 0, 45)

  Voir aussi PAYPER, PAYADV, PAYUNI, AMORTIZE.
```

## `payper`

```
PAYPER Versement périodique d'une annuité.
  V = PAYPER(TAUX,N,PV) rend le versement qui rembourse un capital PV
  en N périodes au taux TAUX par période. PAYPER(...,FV) laisse un
  solde FV à la fin ; PAYPER(...,TERME) vaut 1 quand les versements
  tombent en début de période, 0 en fin (défaut).

  Un emprunt se rembourse par un versement constant qui couvre à la
  fois l'intérêt de la période et une part du capital. La part
  d'intérêt décroît à mesure que le capital baisse ; c'est ce que
  montre AMORTIZE.

  Exemple :
     payper(0.06 / 12, 360, 200000)     % mensualite d'un pret sur 30 ans

  Voir aussi AMORTIZE, ANNURATE, ANNUTERM, PAYADV, PAYODD, PV, FV.
```

## `payuni`

```
PAYUNI Versement constant équivalant à une série de flux.
  V = PAYUNI(TAUX,N,FLUX) rend le versement constant, sur N périodes,
  dont la valeur actuelle est celle de FLUX. C'est la façon de comparer
  deux investissements aux échéanciers différents : on les ramène tous
  deux à une suite de versements égaux.

  Exemple :
     payuni(0.08, 5, [-5000 1000 2000 3000 4000])

  Voir aussi PVVAR, PAYPER, PAYADV, PAYODD.
```

## `pcalims`

```
PCALIMS Contraintes de bornes sur chaque actif.
  C = PCALIMS(MIN,MAX) borne chaque poids. MIN et MAX sont des
  vecteurs, ou des scalaires appliqués à tous les actifs — il faut
  alors donner le nombre d'actifs.

  Exemple :
     pcalims([0 0 0], [0.5 0.5 0.5])

  Voir aussi PCPVAL, PCGLIMS, PORTCONS, PORTOPT.
```

## `pcglims`

```
PCGLIMS Contraintes de bornes sur des groupes d'actifs.
  C = PCGLIMS(GROUPES,MIN,MAX) borne la part de chaque groupe. GROUPES
  est une matrice de zéros et de uns : une ligne par groupe, une
  colonne par actif.

  C'est ainsi qu'on limite l'exposition à un secteur ou à un pays sans
  contraindre chaque titre séparément.

  Exemple :
     pcglims([1 1 0; 0 0 1], [0.2; 0.1], [0.7; 0.5])

  Voir aussi PCALIMS, PCPVAL, PORTCONS, PORTOPT.
```

## `pcpval`

```
PCPVAL Contraintes de budget d'un portefeuille.
  C = PCPVAL(VALEUR,N) rend le jeu de contraintes qui impose que la
  somme des poids vaille VALEUR et qu'aucun poids ne soit négatif.

  Un jeu de contraintes s'écrit [A b] et se lit A*w <= b. Une égalité y
  tient en deux lignes de sens contraires.

  Exemple :
     pcpval(1, 3)

  Voir aussi PCALIMS, PCGLIMS, PORTCONS, PORTOPT.
```

## `pointfig`

```
POINTFIG Graphique en points et figures.
  [C,S] = POINTFIG(COURS,BOITE) découpe la série en colonnes de hausse
  et de baisse. Chaque colonne est un intervalle de cours, exprimé en
  nombre de boîtes ; SYMBOLES vaut 'X' pour une colonne de hausse et
  'O' pour une colonne de baisse.

  Le graphique en points et figures ignore le temps : il ne retient
  qu'une chose, le sens dans lequel le cours a franchi une boîte. Une
  longue période sans mouvement n'y laisse aucune trace.

  Le renversement se fait à trois boîtes, comme le veut l'usage.

  Exemple :
     [c, s] = pointfig(clotures, 1);

  Voir aussi HIGHLOW, CANDLE, MOVAVG.
```

## `portalloc`

```
PORTALLOC Portefeuille de variance minimale pour un rendement cible.
  Résolution analytique par multiplicateurs de Lagrange.
```

## `portalpha`

```
PORTALPHA Rendement en excès, corrigé du risque.
  [A,R] = PORTALPHA(ACTIF,REFERENCE,LIQUIDITES,CHOIX) rend l'excès de
  rendement une fois le risque pris en compte, et le rendement ajusté
  qui lui correspond. CHOIX vaut :
     'xs'   excès brut sur la référence (défaut)
     'sml'  alpha de Jensen, par la droite de marché
     'capm' le même
     'ml'   mesure de Modigliani : l'actif est ramené au risque de la
            référence
     'gh1'  mesure de Graham et Harvey : la référence est portée au
            risque de l'actif
     'gh2'  la variante où c'est l'actif qui est ramené

  Un portefeuille peut battre son indice simplement en prenant plus de
  risque. Corriger, c'est comparer à ce qu'aurait rapporté le même
  risque pris passivement.

  Exemple :
     portalpha(actif, indice, 0.0002, 'sml')

  Voir aussi SHARPE, INFORATIO, PORTSTATS.
```

## `portcons`

```
PORTCONS Assemble un jeu de contraintes de portefeuille.
  C = PORTCONS('Default',N) rend les contraintes usuelles : poids
  positifs et somme égale à un.

  Les types se suivent et s'ajoutent :
     'Default',N                 budget un, poids positifs
     'PortValue',VALEUR,N        budget donné, poids positifs
     'AssetLims',MIN,MAX,N       bornes par actif
     'GroupLims',GROUPES,MIN,MAX bornes par groupe
     'Custom',A,B                contraintes quelconques A*w <= B

  Exemple :
     portcons('Default', 3, 'AssetLims', [0 0 0], [0.5 0.5 0.5])

  Voir aussi PCPVAL, PCALIMS, PCGLIMS, PORTOPT, FRONTCON.
```

## `portopt`

```
PORTOPT Frontière efficiente sous contraintes linéaires.
  [R,M,W] = PORTOPT(MU,SIGMA,N) rend N portefeuilles de la frontière :
  leur écart type, leur rendement et leurs poids. CONTRAINTES est un
  jeu [A b] tel que le rendent PORTCONS et ses voisines ; sans lui, les
  poids sont positifs et somment à un.

  PORTOPT(MU,SIGMA,[],CIBLES,CONTRAINTES) calcule un portefeuille pour
  chaque rendement visé.

  La frontière efficiente est l'ensemble des portefeuilles de variance
  minimale pour chaque niveau de rendement. Elle s'obtient en résolvant
  un programme quadratique par point : le critère est la variance, la
  contrainte est le rendement visé.

  Exemple :
     mu = [0.10 0.15 0.12];
     s = [0.04 0.01 0.00; 0.01 0.09 0.02; 0.00 0.02 0.06];
     [r, m, w] = portopt(mu, s, 5)

  Voir aussi FRONTCON, PORTCONS, PORTSTATS, PORTALLOC, PORTVAR.
```

## `portrand`

```
PORTRAND Portefeuilles tirés au hasard.
  [R,M,W] = PORTRAND(ACTIFS,MU,N) tire N jeux de poids positifs de somme
  un et rend le risque, le rendement et les poids de chacun. ACTIFS est
  une matrice de rendements observés, une colonne par actif ; MU, s'il
  est donné, remplace la moyenne empirique.

  Le nuage obtenu montre ce que la frontière efficiente a de
  remarquable : aucun point ne se trouve à sa gauche.

  Exemple :
     [r, m] = portrand(randn(200, 3) / 20 + 0.01, [], 500);

  Voir aussi PORTOPT, FRONTCON, PORTSTATS, PORTSIM.
```

## `portsim`

```
PORTSIM Simulation de rendements corrélés.
  S = PORTSIM(MU,SIGMA,N) rend N observations de rendements gaussiens
  de moyenne MU et de covariance SIGMA. PORTSIM(...,K) en rend K jeux,
  empilés dans la troisième dimension.

  La corrélation s'obtient par la factorisation de Cholesky : si L*L'
  vaut la covariance et que Z est un bruit blanc réduit, alors L*Z a
  exactement la covariance voulue.

  Exemple :
     s = portsim([0.01 0.02], [0.04 0.01; 0.01 0.09], 1000);
     cov(s)

  Voir aussi PORTRAND, PORTSTATS, EWSTATS, MVNRND.
```

## `portstats`

```
PORTSTATS Rendement et écart type d'un portefeuille.
```

## `portvar`

```
PORTVAR Variance d'un portefeuille.
  V = PORTVAR(RENDEMENTS,POIDS) rend la variance du portefeuille dont
  les poids sont donnés, la covariance étant estimée sur les
  rendements.

  La variance d'un portefeuille n'est pas la moyenne des variances :
  elle est plus petite dès que les actifs ne sont pas parfaitement
  corrélés. C'est toute la diversification.

  Exemple :
     portvar(randn(200, 3), [0.5 0.3 0.2])

  Voir aussi PORTSTATS, PORTOPT, PORTALLOC, COV.
```

## `portvrisk`

```
PORTVRISK Valeur en risque d'un portefeuille, sous hypothèse gaussienne.
  R = PORTVRISK(MOYENNE,ECART,PROBABILITE,VALEUR) rend la perte que le
  portefeuille ne dépassera qu'avec la probabilité donnée.

  PROBABILITE vaut 0,05 par défaut, VALEUR vaut 1 : le résultat est
  alors une perte relative.

  Le calcul suppose les rendements gaussiens, ce que les marchés
  démentent régulièrement : les grandes pertes y sont plus fréquentes
  que la loi normale ne le prévoit.

  Exemple :
     portvrisk(0.01, 0.05, 0.05, 100000)

  Voir aussi VALUEATRISK, EXPECTEDSHORTFALL, PORTSTATS.
```

## `posvolidx`

```
POSVOLIDX Indice des jours de volume en hausse.
  I = POSVOLIDX(CLOTURE,VOLUME,DEPART) ne suit le cours que les séances
  où le volume a monté par rapport à la veille. DEPART vaut 100 par
  défaut.

  Exemple :
     posvolidx(clotures, volumes)

  Voir aussi NEGVOLIDX, ONBALVOL, PVTREND.
```

## `prbyzero`

```
PRBYZERO Prix d'obligations calculés sur une courbe zéro-coupon.
  P = PRBYZERO(OBLIGATIONS,REGLEMENT,TAUXZERO,DATESZERO) actualise
  chaque flux au taux zéro-coupon de sa propre date, interpolé sur la
  courbe. C'est l'inverse de ZBTPRICE.

  Actualiser tous les flux au même taux — le rendement à l'échéance —
  n'est qu'une commodité de cotation ; c'est la courbe qui dit ce que
  vaut chaque flux.

  Exemple :
     obligations = [datenum('01-Feb-2026') 0.05];
     prbyzero(obligations, '01-Feb-2024', [0.03; 0.035], ...
              [datenum('01-Feb-2025'); datenum('01-Feb-2026')])

  Voir aussi ZBTPRICE, ZBTYIELD, BNDPRICE, BNDSPREAD.
```

## `prcroc`

```
PRCROC Taux de variation du cours.
  T = PRCROC(CLOTURE,N) rend, en pourcentage, la variation du cours sur
  N séances. N vaut 12 par défaut.

  Exemple :
     prcroc([100 102 105 103], 1)   % [0 2 2.94 -1.90]

  Voir aussi VOLROC, TSMOM, TSACCEL, MACD.
```

## `prdisc`

```
PRDISC Prix d'un titre vendu à escompte.
  P = PRDISC(REGLEMENT,ECHEANCE,ESCOMPTE,FACE) rend le prix d'un titre
  qui ne verse pas d'intérêt et se rembourse à FACE : il s'achète en
  dessous du pair, et l'écart est l'intérêt.

  Le taux d'escompte se compte sur la valeur de remboursement, non sur
  le prix payé : c'est ce qui le distingue d'un rendement, et le rend
  toujours plus petit que lui.

  Exemple :
     prdisc('01-Feb-2024', '01-Aug-2024', 0.05, 100, 2)

  Voir aussi YLDDISC, DISCRATE, FVDISC, ACRUDISC, PRTBILL.
```

## `prmat`

```
PRMAT Prix d'un titre dont l'intérêt est versé à l'échéance.
  [P,I] = PRMAT(REGLEMENT,ECHEANCE,EMISSION,TAUX,RENDEMENT) rend le
  prix pour cent de nominal et les intérêts courus. Le titre ne verse
  rien avant l'échéance : capital et intérêt arrivent ensemble.

  Exemple :
     [p, i] = prmat('01-Feb-2024', '01-Aug-2024', '01-Jan-2024', 0.05, 0.06)

  Voir aussi YLDMAT, PRDISC, BNDPRICE, ACRUBOND.
```

## `prtbill`

```
PRTBILL Prix d'un bon du Trésor.
  P = PRTBILL(REGLEMENT,ECHEANCE,ESCOMPTE,FACE) applique la convention
  des bons du Trésor américains : le taux d'escompte se rapporte à la
  valeur de remboursement et l'année compte trois cent soixante jours.

  Exemple :
     prtbill('01-Feb-2024', '01-Aug-2024', 0.05, 100)

  Voir aussi YLDTBILL, BEYTBILL, PRDISC, TBILLVAL01.
```

## `pv`

```
PV Valeur actuelle d'une suite de flux, le premier à la période 1.
```

## `pvfix`

```
PVFIX Valeur actuelle d'une série de versements constants.
  V = PVFIX(TAUX,N,VERSEMENT) actualise N versements au taux TAUX par
  période. PVFIX(...,FV) ajoute une somme reçue à la fin ;
  PVFIX(...,TERME) vaut 1 quand les versements tombent en début de
  période.

  Exemple :
     pvfix(0.05, 10, 1000)      % 7721 : ce que valent dix versements

  Voir aussi FVFIX, PVVAR, PAYPER, PV.
```

## `pvtrend`

```
PVTREND Tendance du couple cours-volume.
  T = PVTREND(CLOTURE,VOLUME) cumule le volume multiplié par la
  variation relative du cours. C'est le volume sur solde, pondéré par
  l'ampleur du mouvement plutôt que par son seul signe.

  Exemple :
     pvtrend(clotures, volumes)

  Voir aussi ONBALVOL, NEGVOLIDX, POSVOLIDX, ADLINE.
```

## `pvvar`

```
PVVAR Valeur actuelle d'une série de flux quelconques.
  V = PVVAR(FLUX,TAUX) actualise chaque flux à la date du premier. Le
  premier flux est à la date zéro.

  PVVAR(FLUX,TAUX,DATES) donne les dates réelles : le taux est alors
  annuel et les fractions d'année comptées sur 365 jours.

  La valeur actuelle est nulle quand le taux vaut le taux de rendement
  interne : c'est la définition de celui-ci.

  Exemple :
     pvvar([-10000 2000 3000 4000 5000], 0.08)

  Voir aussi FVVAR, PVFIX, IRR, NPV, MIRR.
```

## `pyld2zero`

```
PYLD2ZERO Courbe zéro-coupon reconstruite à partir des taux au pair.
  C'est l'inverse de ZERO2PYLD, obtenu de proche en proche : le facteur
  d'actualisation d'une échéance se déduit de ceux des échéances plus
  courtes, déjà connus, et du taux au pair de l'échéance.

  Exemple :
     [z, d] = pyld2zero([0.02 0.025 0.03], ...
         {'01-Aug-2024','01-Feb-2025','01-Aug-2025'}, '01-Feb-2024')

  Voir aussi ZERO2PYLD, ZBTYIELD, DISC2ZERO.
```

## `ratetimes`

```
RATETIMES Change les intervalles auxquels s'appliquent des taux.
  [R,F] = RATETIMES(C,TAUXREF,FINREF,DEBUTREF,FIN,DEBUT) rend les taux
  qui s'appliquent aux nouveaux intervalles, déduits de la courbe de
  référence. Les temps sont comptés en périodes de composition.

  La conversion passe par les facteurs d'actualisation : ce sont eux
  qui se composent, non les taux. Entre deux dates de la courbe, le
  logarithme du facteur est interpolé linéairement, ce qui revient à
  supposer le taux à terme constant sur l'intervalle.

  Exemple :
     ratetimes(2, [0.02; 0.025], [2; 4], [0; 0], [3], [0])

  Voir aussi ZERO2FWD, FWD2ZERO, DISC2ZERO.
```

## `ret2tick`

```
RET2TICK Reconstruit une série de cours à partir des rendements.
```

## `rsindex`

```
RSINDEX Indice de force relative.
  I = RSINDEX(CLOTURE,N) rapporte la moyenne des hausses à la somme des
  moyennes des hausses et des baisses, sur N séances, et rend le
  résultat sur une échelle de zéro à cent. N vaut 14 par défaut.

  Au-dessus de soixante-dix, ses utilisateurs parlent de suracheté ; en
  dessous de trente, de survendu. L'indice est borné par construction,
  ce qui le rend comparable d'un titre à l'autre.

  Le lissage est celui de Wilder : une moyenne exponentielle de facteur
  un sur N, non deux sur N plus un.

  Exemple :
     rsindex(clotures, 14)

  Voir aussi WILLPCTR, STOCHOSC, MACD.
```

## `sharpe`

```
SHARPE Ratio de Sharpe d'une série de rendements.
```

## `spctkd`

```
SPCTKD Stochastiques lentes.
  [K,D] = SPCTKD(RAPIDEK,RAPIDED,M) lisse les stochastiques rapides :
  le K lent est l'ancien D rapide, et le D lent en est la moyenne
  mobile sur M séances. M vaut 3 par défaut.

  Le lissage supprime les croisements les plus nombreux, qui sont aussi
  les moins informatifs.

  Exemple :
     [k, d] = fpctkd(hauts, bas, clotures);
     [kl, dl] = spctkd(k, d);

  Voir aussi FPCTKD, STOCHOSC.
```

## `stochosc`

```
STOCHOSC Oscillateur stochastique.
  [K,D] = STOCHOSC(HAUT,BAS,CLOTURE,N,M) rend les stochastiques
  rapides : la place de la clôture dans l'amplitude des N dernières
  séances et sa moyenne sur M séances.

  Un cours qui clôture près de son plus haut hebdomadaire n'a pas la
  même signification qu'un cours qui clôture près de son plus bas, même
  s'il a monté d'autant : c'est ce que l'indicateur mesure.

  Exemple :
     [k, d] = stochosc(hauts, bas, clotures);

  Voir aussi FPCTKD, SPCTKD, WILLPCTR, RSINDEX.
```

## `thirdwednesday`

```
THIRDWEDNESDAY Troisième mercredi du mois, et celui de trois mois plus tard.
  [D,F] = THIRDWEDNESDAY(MOIS,ANNEE) rend le troisième mercredi du mois
  et celui du mois qui vient trois mois après. Ce sont les dates de
  début et de fin de la période couverte par un contrat à terme sur
  taux à trois mois : c'est ce jour-là que se règlent les eurodollars.

  Exemple :
     [d, f] = thirdwednesday(3, 2024);
     datestr([d f])          % 20-Mar-2024 et 19-Jun-2024

  Voir aussi NWEEKDATE, LWEEKDATE, HOLIDAYS.
```

## `thirtytwo2dec`

```
THIRTYTWO2DEC Cours en trente-deuxièmes converti en décimal.
  V = THIRTYTWO2DEC(ENTIERS,TRENTEDEUXIEMES) est l'inverse de
  DEC2THIRTYTWO.

  Exemple :
     thirtytwo2dec(101, 16)     % 101.5

  Voir aussi DEC2THIRTYTWO, FRAC2CUR, CUR2FRAC.
```

## `tick2ret`

```
TICK2RET Rendements à partir d'une série de cours.
  R = TICK2RET(P) rend les rendements simples ; 'continuous' donne les
  rendements logarithmiques.
```

## `totalreturnprice`

```
TOTALRETURNPRICE Série de prix réinvestissant les dividendes.
  S = TOTALRETURNPRICE(PRIX,DIVIDENDES,DATESDIVIDENDES,DATES) rend la
  série qu'aurait suivie un placement qui réinvestit chaque dividende
  dans le titre, le jour où il est versé.

  Comparer deux titres sur leur seul cours fausse le jugement : celui
  qui distribue beaucoup paraît stagner. La série de rendement total
  corrige cela.

  Exemple :
     s = totalreturnprice(prix, [1.2 1.3], datesVersement, dates);

  Voir aussi RET2TICK, TICK2RET, PRICE2RET.
```

## `tsaccel`

```
TSACCEL Accélération d'une série.
  A = TSACCEL(SERIE,N) rend la variation de l'élan : la dérivée seconde
  du cours, mesurée à la grosse. N vaut 12 par défaut.

  Exemple :
     tsaccel(clotures, 12)

  Voir aussi TSMOM, PRCROC, MACD.
```

## `tsmom`

```
TSMOM Élan d'une série.
  M = TSMOM(SERIE,N) rend l'écart entre la valeur du jour et celle de N
  séances plus tôt. N vaut 12 par défaut.

  L'élan est la dérivée première du cours, mesurée à la grosse : il
  change de signe avant le cours lui-même, ce qui explique qu'on
  l'emploie comme signal avancé.

  Exemple :
     tsmom([100 102 105 103], 1)    % [0 2 3 -2]

  Voir aussi TSACCEL, PRCROC, MACD.
```

## `typprice`

```
TYPPRICE Prix typique d'une séance.
  P = TYPPRICE(HAUT,BAS,CLOTURE) rend la moyenne des trois. Il sert de
  cours de référence là où la clôture seule serait trop sensible aux
  derniers échanges.

  Exemple :
     typprice([12 10 11], [14 11 13])

  Voir aussi MEDPRICE, WCLOSE, STOCHOSC.
```

## `volroc`

```
VOLROC Taux de variation du volume.
  T = VOLROC(VOLUME,N) rend, en pourcentage, la variation du volume sur
  N séances. N vaut 12 par défaut.

  Exemple :
     volroc(volumes, 12)

  Voir aussi PRCROC, CHAIKVOLAT, ONBALVOL.
```

## `wclose`

```
WCLOSE Clôture pondérée d'une séance.
  P = WCLOSE(HAUT,BAS,CLOTURE) rend la moyenne où la clôture compte
  double : (H + B + 2C) divisé par quatre.

  Exemple :
     wclose(14, 10, 13)             % 12.5

  Voir aussi MEDPRICE, TYPPRICE.
```

## `weights2holdings`

```
WEIGHTS2HOLDINGS Quantités à détenir pour atteindre des poids donnés.
  Q = WEIGHTS2HOLDINGS(POIDS,PRIX,VALEUR) rend le nombre de titres à
  acheter de chacun pour placer VALEUR selon les poids donnés.

  Exemple :
     weights2holdings([0.5 0.5], [10 5], 2000)    % [100 200]

  Voir aussi HOLDINGS2WEIGHTS, PORTSTATS.
```

## `williamsad`

```
WILLIAMSAD Accumulation et distribution de Williams.
  A = WILLIAMSAD(HAUT,BAS,CLOTURE) cumule, séance après séance, l'écart
  entre la clôture et le point extrême de la séance précédente : la
  hausse ajoute la clôture moins le plus bas des deux clôtures, la
  baisse retranche le plus haut moins la clôture.

  L'indicateur monte quand les acheteurs l'emportent séance après
  séance, même si le cours ne progresse pas : c'est une divergence de
  ce genre que ses utilisateurs guettent.

  Exemple :
     williamsad(hauts, bas, clotures)

  Voir aussi ADLINE, ADOSC, ONBALVOL.
```

## `willpctr`

```
WILLPCTR Indicateur de Williams, en pourcentage.
  W = WILLPCTR(HAUT,BAS,CLOTURE,N) situe la clôture dans l'amplitude
  des N dernières séances, sur une échelle allant de -100 — la clôture
  est au plus bas — à zéro — elle est au plus haut. N vaut 14 par
  défaut.

  Exemple :
     willpctr(hauts, bas, clotures, 14)

  Voir aussi STOCHOSC, HHIGH, LLOW, RSINDEX.
```

## `wrkdydif`

```
WRKDYDIF Nombre de jours ouvrés entre deux dates.
  N = WRKDYDIF(D1,D2) compte les jours ouvrés du premier au second,
  bornes comprises. WRKDYDIF(D1,D2,F) retranche F jours fériés.

  Exemple :
     wrkdydif('01-Mar-2024', '08-Mar-2024')    % 6

  Voir aussi DATEWRKDY, BUSDATE, ISBUSDAY, HOLIDAYS.
```

## `x2mdate`

```
X2MDATE Numéro de série Excel converti en numéro MATLAB.
  D = X2MDATE(E) lit le système de 1900, X2MDATE(E,1) celui de 1904.

  Exemple :
     datestr(x2mdate(36526))          % 01-Jan-2000

  Voir aussi M2XDATE, DATENUM, DATESTR.
```

## `yearfrac`

```
YEARFRAC Fraction d'année entre deux dates, selon une convention de calcul.
  F = YEARFRAC(D1,D2,BASE) rend la part d'année écoulée entre D1 et D2.
  BASE choisit la convention :
     0  réel/réel (défaut)          7  réel/365 japonais
     1  30/360 américaine           8  réel/réel ISMA
     2  réel/360                    9  réel/360 ISMA
     3  réel/365                   10  réel/365 ISMA
     4  30/360 PSA                 11  30/360E ISMA
     5  30/360 ISDA                12  réel/365 ISDA
     6  30E/360 européenne         13  jours ouvrés sur 252

  Une convention n'est pas une approximation de l'autre : elles
  répondent à des contrats différents. Un prêt à taux annuel sur base
  réel/360 rapporte plus qu'un prêt sur base réel/365, au même taux
  affiché, parce qu'il compte plus de fractions d'année dans l'année.

  Exemple :
     yearfrac('01-Jan-2000', '01-Jan-2001', 0)   % 1 exactement
     yearfrac('01-Jan-2000', '01-Jan-2001', 2)   % 366/360

  Voir aussi DAYS360, DAYS365, DAYSACT, DAYSDIF.
```

## `ylddisc`

```
YLDDISC Rendement d'un titre vendu à escompte.
  R = YLDDISC(REGLEMENT,ECHEANCE,FACE,PRIX) rend le gain rapporté au
  prix payé, ramené à l'année.

  Exemple :
     ylddisc('01-Feb-2024', '01-Aug-2024', 100, 97.5, 2)

  Voir aussi PRDISC, DISCRATE, FVDISC, YLDTBILL.
```

## `yldmat`

```
YLDMAT Rendement d'un titre dont l'intérêt est versé à l'échéance.
  R = YLDMAT(REGLEMENT,ECHEANCE,EMISSION,TAUX,PRIX) est l'inverse de
  PRMAT : le rendement qui rend le prix observé.

  Exemple :
     yldmat('01-Feb-2024', '01-Aug-2024', '01-Jan-2024', 0.05, 99.2)

  Voir aussi PRMAT, YLDDISC, BNDYIELD.
```

## `yldtbill`

```
YLDTBILL Rendement d'un bon du Trésor.
  R = YLDTBILL(REGLEMENT,ECHEANCE,FACE,PRIX) rend le gain rapporté au
  prix payé, sur une année de trois cent soixante jours : c'est le
  rendement du marché monétaire.

  Exemple :
     yldtbill('01-Feb-2024', '01-Aug-2024', 100, 97.5)

  Voir aussi PRTBILL, BEYTBILL, YLDDISC.
```

## `zbtprice`

```
ZBTPRICE Courbe zéro-coupon reconstruite à partir de prix d'obligations.
  [Z,D] = ZBTPRICE(OBLIGATIONS,PRIX,REGLEMENT) rend les taux
  zéro-coupon implicites. OBLIGATIONS est une matrice dont chaque ligne
  vaut [echeance taux face periode base regleFinMois] ; seules les deux
  premières colonnes sont obligatoires.

  Le marché ne cote pas de zéro-coupon à toutes les échéances : il faut
  les extraire des obligations à coupons, de proche en proche. Le prix
  de l'obligation la plus courte donne le facteur d'actualisation de
  son échéance ; celui de la suivante s'en sert pour ses coupons
  intermédiaires et ne laisse qu'une inconnue, et ainsi de suite.

  Exemple :
     obligations = [datenum('01-Feb-2025') 0.04; datenum('01-Feb-2026') 0.05];
     [z, d] = zbtprice(obligations, [99.5; 100.2], '01-Feb-2024')

  Voir aussi ZBTYIELD, PRBYZERO, DISC2ZERO, BNDPRICE.
```

## `zbtyield`

```
ZBTYIELD Courbe zéro-coupon reconstruite à partir de rendements.
  Même chose que ZBTPRICE, les obligations étant données par leur
  rendement à l'échéance plutôt que par leur prix.

  Exemple :
     obligations = [datenum('01-Feb-2025') 0.04; datenum('01-Feb-2026') 0.05];
     [z, d] = zbtyield(obligations, [0.042; 0.048], '01-Feb-2024')

  Voir aussi ZBTPRICE, PRBYZERO, BNDPRICE.
```

## `zero2disc`

```
ZERO2DISC Facteurs d'actualisation déduits des taux zéro-coupon.
  C'est l'inverse de DISC2ZERO.

  Exemple :
     [f, d] = zero2disc([0.02 0.025 0.03], ...
         {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')

  Voir aussi DISC2ZERO, ZERO2FWD, PRBYZERO.
```

## `zero2fwd`

```
ZERO2FWD Taux à terme implicites d'une courbe zéro-coupon.
  [F,D] = ZERO2FWD(Z,DATES,REGLEMENT) rend, pour chaque intervalle de
  la courbe, le taux qui s'applique de la date précédente à celle-ci.
  Le premier taux à terme est le premier taux zéro-coupon.

  Un taux à terme est ce que le marché fait payer aujourd'hui pour
  emprunter plus tard : c'est le seul taux qui rende indifférent
  d'emprunter longtemps ou d'emprunter court puis de renouveler.

  Exemple :
     [f, d] = zero2fwd([0.02 0.025 0.03], ...
         {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')

  Voir aussi FWD2ZERO, ZERO2DISC, DISC2ZERO, RATETIMES.
```

## `zero2pyld`

```
ZERO2PYLD Taux au pair déduits d'une courbe zéro-coupon.
  [P,D] = ZERO2PYLD(Z,DATES,REGLEMENT) rend, pour chaque échéance, le
  taux de coupon qui ferait coter l'obligation exactement au pair.

  Les dates de la courbe servent de dates de coupon : la courbe doit
  donc être donnée au pas de la composition.

  Exemple :
     [p, d] = zero2pyld([0.02 0.025 0.03], ...
         {'01-Aug-2024','01-Feb-2025','01-Aug-2025'}, '01-Feb-2024')

  Voir aussi PYLD2ZERO, ZERO2DISC, ZBTYIELD, BNDPRICE.
```

