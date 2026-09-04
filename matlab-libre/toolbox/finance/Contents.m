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
