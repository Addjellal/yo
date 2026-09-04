# Toolbox `instruments-financiers`

```
% Financial Instruments Toolbox — instruments de taux, de crédit et
% dérivés.
%
% Environnement de taux
%   intenvset, intenvget - Construction et lecture d'une courbe
%   intenvprice          - Prix de tous les instruments d'un jeu
%   intenvsens           - Sensibilités à un déplacement de la courbe
%   date2time, time2date - Durées comptées en périodes de composition
%
% Jeux d'instruments
%   instadd, instaddfield - Ajout d'instruments, types connus ou maison
%   instdelete, instsetfield - Suppression, modification
%   instget, instgetcell  - Lecture des champs
%   instselect            - Sous-jeu répondant à un critère
%   instdisp, instfields, insttypes, instlength - Inspection
%
% Valorisation sur courbe zéro-coupon
%   zeroprice, zeroyield - Obligation sans coupon
%   bondprice, bondyield, bonddur, bondconvexity - Au rendement
%   bondbyzero, cfbyzero - Obligation et flux quelconques
%   fixedbyzero, floatbyzero, swapbyzero - Branches et échanges de taux
%   discountfactor, forwardrate - Facteurs et taux à terme
%
% Modèle de Black
%   blkprice, blkimpv    - Options sur contrat à terme
%   capbyblk, floorbyblk - Plafonds et planchers de taux
%   swaptionbyblk        - Options sur échange de taux
%
% Formes fermées de Black et Scholes
%   stockspec            - Descripteur d'actif sous-jacent
%   optstockbybls, optstocksensbybls - Options européennes et grecques
%   barrierbybls         - Options à barrière, huit variantes
%   lookbackbybls        - Rétrospectives, prix flottant ou fixe
%   asianbykv, asianbylevy - Asiatiques géométrique et arithmétique
%   cashbybls, assetbybls - Binaires en espèces et en actif
%   gapbybls, supersharebybls, chooserbybls - À saut, superaction, au choix
%
% Arbres binomiaux
%   binprice             - Option américaine, arbre de Cox-Ross-Rubinstein
%   crrtimespec, crrtree - Découpage du temps, construction de l'arbre
%   crrprice, crrsens    - Prix et sensibilités sur l'arbre
%
% Protection contre le défaut
%   cdsbootstrap         - Probabilités de défaut déduites des écarts
%   cdsspread, cdsprice  - Écart d'équilibre et valeur d'un contrat
```

## `asianbykv`

```
ASIANBYKV Prix d'une option asiatique géométrique, formule de Kemna et Vorst.
  P = ASIANBYKV(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE) rend le
  prix d'une option dont le gain dépend de la moyenne géométrique du
  cours.

  La moyenne géométrique d'un mouvement brownien géométrique est
  elle-même lognormale : la formule de Black et Scholes s'applique
  telle quelle, la volatilité étant divisée par racine de trois et le
  coût de portage ajusté. C'est ce qui rend le cas géométrique exact là
  où le cas arithmétique demande une approximation.

  Une asiatique coûte moins cher qu'une option ordinaire : la moyenne
  est moins volatile que le cours final.

  Exemple :
     asianbykv(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025')

  Voir aussi ASIANBYLEVY, LOOKBACKBYBLS, OPTSTOCKBYBLS.
```

## `asianbylevy`

```
ASIANBYLEVY Prix d'une option asiatique arithmétique, approximation de Levy.
  P = ASIANBYLEVY(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE) rend
  le prix d'une option sur la moyenne arithmétique du cours.

  La moyenne arithmétique de lognormales n'est pas lognormale, et n'a
  pas de loi commode. Levy propose de lui substituer la lognormale de
  mêmes deux premiers moments, qui se calculent exactement ; l'erreur
  est petite tant que la volatilité reste modérée.

  Le prix est supérieur à celui de la moyenne géométrique, l'inégalité
  des moyennes valant terme à terme.

  Exemple :
     asianbylevy(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025')

  Voir aussi ASIANBYKV, LOOKBACKBYBLS, OPTSTOCKBYBLS.
```

## `assetbybls`

```
ASSETBYBLS Prix d'une option binaire en actif.
  P = ASSETBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,EXERCICE) rend le
  prix d'une option qui livre l'actif si elle finit dans la monnaie, et
  rien sinon.

  Une option d'achat ordinaire est une option en actif moins le prix
  d'exercice fois une option en espèces de versement un : c'est
  exactement la décomposition de la formule de Black et Scholes en ses
  deux termes.

  Exemple :
     assetbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100)

  Voir aussi CASHBYBLS, GAPBYBLS, SUPERSHAREBYBLS.
```

## `barrierbybls`

```
BARRIERBYBLS Prix d'une option à barrière, formule fermée.
  P = BARRIERBYBLS(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE,
  TYPEBARRIERE,BARRIERE,REMISE) rend le prix d'une option qui
  s'active ou s'annule quand le cours touche la barrière.

  TYPEBARRIERE vaut 'UI' entrante par le haut, 'UO' sortante par le
  haut, 'DI' entrante par le bas, 'DO' sortante par le bas. REMISE est
  versée si l'option ne s'active pas, ou dès qu'elle s'annule.

  La formule est celle de Merton, Reiner et Rubinstein : elle décompose
  le gain en six morceaux dont chacun a une forme fermée. La somme
  d'une entrante et d'une sortante de mêmes paramètres, à remise nulle,
  redonne l'option ordinaire — c'est ce qui la vérifie.

  Exemple :
     barrierbybls(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025', 'DO', 90, 0)

  Voir aussi OPTSTOCKBYBLS, LOOKBACKBYBLS, ASIANBYKV.
```

## `binprice`

```
BINPRICE Prix d'une option américaine par arbre binomial.
  [S,V] = BINPRICE(COURS,EXERCICE,TAUX,DUREE,PAS,VOLATILITE,DRAPEAU)
  rend l'arbre des cours et celui des valeurs de l'option. DRAPEAU vaut
  1 pour un achat, 0 pour une vente. L'exercice est américain : la
  valeur d'un nœud est le maximum entre le gain immédiat et la valeur
  d'attente.

  BINPRICE(...,TAUXDIVIDENDE) ajoute un rendement de dividende continu.
  BINPRICE(...,DIVIDENDES,DATES) traite des dividendes en espèces : la
  valeur actuelle des dividendes à venir est retirée du cours avant de
  bâtir l'arbre, puis rendue nœud par nœud.

  L'arbre est celui de Cox, Ross et Rubinstein : la hausse vaut
  l'exponentielle de la volatilité par la racine du pas, la baisse son
  inverse, ce qui fait se rejoindre les branches et laisse un nombre de
  nœuds proportionnel au carré du nombre de pas, non à sa puissance.

  Exemple :
     [s, v] = binprice(100, 95, 0.05, 1, 1/50, 0.2, 1);
     v(1, 1)                        % prix de l'option

  Voir aussi CRRTREE, CRRPRICE, BLSPRICE, OPTSTOCKBYBLS.
```

## `blkimpv`

```
BLKIMPV Volatilité implicite d'une option sur contrat à terme.
  V = BLKIMPV(TERME,EXERCICE,TAUX,DUREE,PRIX) rend la volatilité qui
  redonne le prix observé dans le modèle de Black.

  BLKIMPV(...,LIMITE,TOLERANCE,TYPE) borne la recherche, règle la
  précision et choisit l'achat — le défaut — ou la vente.

  Exemple :
     c = blkprice(100, 100, 0.05, 1, 0.2);
     blkimpv(100, 100, 0.05, 1, c)        % 0.2

  Voir aussi BLKPRICE, BLSIMPV.
```

## `blkprice`

```
BLKPRICE Prix d'options sur contrat à terme, modèle de Black.
  [C,P] = BLKPRICE(TERME,EXERCICE,TAUX,DUREE,VOLATILITE) rend les prix
  de l'achat et de la vente sur un contrat à terme de cours TERME.

  La formule est celle de Black et Scholes où le cours comptant est
  remplacé par le cours à terme actualisé : un contrat à terme ne coûte
  rien à l'entrée, si bien que le taux n'intervient plus que pour
  ramener le gain final à aujourd'hui.

  Exemple :
     blkprice(100, 100, 0.05, 1, 0.2)

  Voir aussi BLKIMPV, BLSPRICE, CAPBYBLK, FLOORBYBLK, SWAPTIONBYBLK.
```

## `bondbyzero`

```
BONDBYZERO Prix d'une obligation, sur une courbe zéro-coupon.
  P = BONDBYZERO(COURBE,TAUX,REGLEMENT,ECHEANCE) actualise chaque flux
  au taux de sa propre date, au lieu de tous les actualiser au même
  rendement à l'échéance.

  C'est la valorisation juste : un rendement unique n'est qu'une façon
  de résumer un prix par un nombre, et deux obligations de même
  échéance mais de coupons différents n'ont pas le même rendement même
  quand elles sont valorisées sur la même courbe.

  Exemple :
     bondbyzero(courbe, 0.05, '01-Jan-2024', '01-Jan-2029')

  Voir aussi CFBYZERO, FIXEDBYZERO, SWAPBYZERO, BNDPRICE, INTENVPRICE.
```

## `bondconvexity`

```
BONDCONVEXITY Convexité d'une obligation.
```

## `bonddur`

```
BONDDUR Durations de Macaulay et modifiée.
```

## `bondprice`

```
BONDPRICE Prix d'une obligation à coupons constants.
  PRIX = BONDPRICE(TAUX,COUPON,ECHEANCE,NOMINAL,FREQUENCE)
```

## `bondyield`

```
BONDYIELD Taux actuariel d'une obligation, par dichotomie.
```

## `capbyblk`

```
CAPBYBLK Prix d'un plafond de taux, modèle de Black.
  P = CAPBYBLK(COURBE,EXERCICE,REGLEMENT,ECHEANCE,VOLATILITE) rend le
  prix d'un contrat qui rembourse, à chaque période, ce que le taux
  variable dépasse le taux d'exercice.

  [P,CAPLETS] = CAPBYBLK(...) rend aussi le prix de chaque période.

  Un plafond est une somme d'options d'achat sur le taux à terme, une
  par période : chacune se valorise par la formule de Black, et le
  plafond est leur somme. La première période, dont le taux est déjà
  fixé, ne compte pas.

  Exemple :
     capbyblk(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 0.2, 4)

  Voir aussi FLOORBYBLK, SWAPTIONBYBLK, BLKPRICE.
```

## `cashbybls`

```
CASHBYBLS Prix d'une option binaire en espèces.
  P = CASHBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,EXERCICE,
  VERSEMENT) rend le prix d'une option qui verse une somme fixe si elle
  finit dans la monnaie, et rien sinon.

  Son prix est la valeur actuelle du versement multipliée par la
  probabilité risque-neutre de finir dans la monnaie : c'est la lecture
  la plus directe de ce que le second terme de Black et Scholes
  signifie.

  Exemple :
     cashbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100, 10)

  Voir aussi ASSETBYBLS, GAPBYBLS, SUPERSHAREBYBLS.
```

## `cdsbootstrap`

```
CDSBOOTSTRAP Probabilités de défaut déduites d'écarts de crédit cotés.
  [PROB,HASARD] = CDSBOOTSTRAP(TAUX,MARCHE,REGLEMENT) rend, pour chaque
  échéance cotée, la date et la probabilité de défaut cumulée, ainsi
  que le taux de hasard de l'intervalle.

  TAUX est une matrice [dates taux] décrivant la courbe sans risque ;
  MARCHE une matrice [échéance écart], l'écart étant en points de base.

  Le marché ne cote pas de probabilité de défaut : il cote le prix
  d'une protection. Comme pour une courbe de taux, on remonte de proche
  en proche : l'écart le plus court donne le taux de hasard de la
  première période, celui d'après ne laisse qu'une inconnue, et ainsi
  de suite.

  RECUPERATION vaut 0,4 par défaut, FREQUENCE 4 et BASE 2.

  Exemple :
     taux = [datenum('01-Jan-2029') 0.03];
     marche = [datenum('01-Jan-2029') 150];
     [p, h] = cdsbootstrap(taux, marche, '01-Jan-2024')

  Voir aussi CDSPRICE, CDSSPREAD, ZBTPRICE.
```

## `cdsprice`

```
CDSPRICE Prix d'un contrat de protection contre le défaut.
  [P,C] = CDSPRICE(TAUX,PROBABILITES,REGLEMENT,ECHEANCE,ECARTCONTRAT)
  rend la valeur du contrat pour l'acheteur de protection, et la prime
  courue depuis la dernière échéance. ECARTCONTRAT est en points de
  base.

  Un contrat conclu à un écart inférieur à celui du marché vaut
  quelque chose : l'acheteur paie moins que ce que la protection vaut
  aujourd'hui. Le prix est cet écart, multiplié par la valeur actuelle
  d'une prime unitaire.

  Exemple :
     cdsprice(taux, probabilites, '01-Jan-2024', '01-Jan-2029', 100)

  Voir aussi CDSSPREAD, CDSBOOTSTRAP.
```

## `cdsspread`

```
CDSSPREAD Écart d'équilibre d'un contrat de protection contre le défaut.
  E = CDSSPREAD(TAUX,PROBABILITES,REGLEMENT,ECHEANCE) rend, en points
  de base, la prime annuelle qui rend le contrat de valeur nulle.

  PROBABILITES est une matrice [dates probabilité cumulée de défaut],
  telle que la rend CDSBOOTSTRAP.

  L'écart est le rapport de deux valeurs actuelles : celle du
  versement attendu en cas de défaut, et celle d'une prime unitaire
  payée tant qu'il n'y a pas défaut.

  Exemple :
     cdsspread(taux, probabilites, '01-Jan-2024', '01-Jan-2029')

  Voir aussi CDSBOOTSTRAP, CDSPRICE.
```

## `cfbyzero`

```
CFBYZERO Prix d'une série de flux, sur une courbe zéro-coupon.
  P = CFBYZERO(COURBE,MONTANTS,DATES,REGLEMENT) actualise chaque flux
  au taux de sa propre date, lu sur la courbe. Plusieurs séries se
  donnent par lignes.

  Exemple :
     cfbyzero(courbe, [5 5 105], {'01-Jan-2025','01-Jan-2026','01-Jan-2027'}, ...
              '01-Jan-2024')

  Voir aussi BONDBYZERO, FIXEDBYZERO, FLOATBYZERO, SWAPBYZERO, INTENVPRICE.
```

## `chooserbybls`

```
CHOOSERBYBLS Prix d'une option au choix.
  P = CHOOSERBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,EXERCICE,DATECHOIX)
  rend le prix d'une option dont le détenteur choisit, à la date
  indiquée, si elle sera un achat ou une vente.

  Elle coûte moins qu'un achat plus une vente, et plus que le plus cher
  des deux : choisir plus tard vaut mieux que choisir maintenant, mais
  moins bien que garder les deux. Quand la date du choix rejoint
  l'échéance, le prix rejoint celui du couple.

  La formule est celle de Rubinstein.

  Exemple :
     chooserbybls(c, s, '01-Jan-2024', '01-Jan-2025', 100, '01-Jul-2024')

  Voir aussi OPTSTOCKBYBLS, BARRIERBYBLS.
```

## `crrprice`

```
CRRPRICE Prix d'options par un arbre binomial.
  P = CRRPRICE(ARBRE,JEU) valorise les instruments 'OptStock' du jeu
  par récurrence arrière sur l'arbre : la valeur d'un nœud est
  l'espérance actualisée de ses deux successeurs, comparée au gain
  immédiat quand l'exercice est américain.

  [P,ARBRES] = CRRPRICE(...) rend aussi l'arbre des valeurs de chaque
  instrument.

  Exemple :
     jeu = instadd('OptStock', 'call', 100, '01-Jan-2024', ...
                   '01-Jan-2025', 1);
     crrprice(arbre, jeu)

  Voir aussi CRRTREE, CRRSENS, BINPRICE, OPTSTOCKBYBLS.
```

## `crrsens`

```
CRRSENS Sensibilités d'options calculées sur un arbre binomial.
  [D,G,V,P] = CRRSENS(ARBRE,JEU) rend le delta, le gamma, le vega et le
  prix.

  Le delta et le gamma se lisent directement dans l'arbre : les deux
  premiers niveaux donnent déjà trois cours et trois valeurs, dont on
  tire les deux dérivées sans reconstruire quoi que ce soit. Le vega
  demande, lui, de rebâtir l'arbre à volatilité déplacée.

  Exemple :
     [d, g, v, p] = crrsens(arbre, jeu)

  Voir aussi CRRPRICE, CRRTREE, BLSDELTA, BLSGAMMA.
```

## `crrtimespec`

```
CRRTIMESPEC Découpage du temps d'un arbre binomial.
  T = CRRTIMESPEC(VALORISATION,ECHEANCE,N) découpe l'intervalle en N
  pas égaux et rend les dates et les durées de chaque niveau.

  Exemple :
     t = crrtimespec('01-Jan-2024', '01-Jan-2025', 50);

  Voir aussi CRRTREE, CRRPRICE, STOCKSPEC, INTENVSET.
```

## `crrtree`

```
CRRTREE Arbre binomial de Cox, Ross et Rubinstein.
  A = CRRTREE(ACTIF,COURBE,TEMPS) construit l'arbre des cours à partir
  du descripteur d'actif, de la courbe de taux et du découpage du
  temps.

  Chaque nœud a deux successeurs, dont l'un est le successeur bas de
  l'autre : l'arbre se recombine, et son nombre de nœuds ne croît que
  comme le carré du nombre de pas.

  Exemple :
     s = stockspec(0.2, 100);
     c = intenvset('Rates', 0.05, 'StartDates', '01-Jan-2024', ...
                   'EndDates', '01-Jan-2025', 'Compounding', -1);
     a = crrtree(s, c, crrtimespec('01-Jan-2024', '01-Jan-2025', 50));

  Voir aussi CRRTIMESPEC, CRRPRICE, CRRSENS, BINPRICE.
```

## `date2time`

```
DATE2TIME Durée entre deux dates, comptée en périodes.
  [T,F] = DATE2TIME(REGLEMENT,ECHEANCE,COMPOSITION,BASE) rend la durée
  en nombre de périodes de composition, et les facteurs
  d'actualisation qu'un taux unitaire y produirait.

  COMPOSITION vaut le nombre de capitalisations par an — 2 par défaut —,
  -1 pour la composition continue, 0 pour un intérêt simple. BASE est
  une convention de comptage, au sens de YEARFRAC.

  Exemple :
     date2time('01-Jan-2024', '01-Jan-2026', 2, 0)     % 4 semestres

  Voir aussi TIME2DATE, YEARFRAC, INTENVSET.
```

## `discountfactor`

```
DISCOUNTFACTOR Facteurs d'actualisation d'une courbe de taux.
```

## `fixedbyzero`

```
FIXEDBYZERO Prix de la branche fixe d'un échange de taux.
  P = FIXEDBYZERO(COURBE,TAUX,REGLEMENT,ECHEANCE,FREQUENCE) actualise
  les intérêts d'une branche fixe. Le nominal n'est pas échangé : seuls
  les intérêts comptent, ce qui distingue une branche d'échange d'une
  obligation.

  [P,FLUX,DATES] = FIXEDBYZERO(...) rend aussi les flux et leurs dates.

  Exemple :
     fixedbyzero(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 2)

  Voir aussi FLOATBYZERO, SWAPBYZERO, BONDBYZERO.
```

## `floatbyzero`

```
FLOATBYZERO Prix de la branche variable d'un échange de taux.
  P = FLOATBYZERO(COURBE,ECART,REGLEMENT,ECHEANCE,FREQUENCE) actualise
  les intérêts d'une branche indexée sur le taux à terme, majoré de
  ECART points de base.

  Sans écart, la branche variable vaut la différence des facteurs
  d'actualisation de la première et de la dernière date, multipliée par
  le nominal : les taux à terme sont précisément ceux qui rendent cette
  égalité vraie. C'est ce qui fait qu'une branche variable cote au pair
  à chaque fixation.

  Exemple :
     floatbyzero(courbe, 0, '01-Jan-2024', '01-Jan-2029', 4)

  Voir aussi FIXEDBYZERO, SWAPBYZERO.
```

## `floorbyblk`

```
FLOORBYBLK Prix d'un plancher de taux, modèle de Black.
  P = FLOORBYBLK(COURBE,EXERCICE,REGLEMENT,ECHEANCE,VOLATILITE) rend le
  prix d'un contrat qui verse, à chaque période, ce qui manque au taux
  variable pour atteindre le taux d'exercice.

  Un plafond moins un plancher de même exercice vaut un échange payeur
  de fixe : c'est la parité achat-vente, appliquée période par période.

  Exemple :
     floorbyblk(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 0.2, 4)

  Voir aussi CAPBYBLK, SWAPTIONBYBLK, BLKPRICE.
```

## `forwardrate`

```
FORWARDRATE Taux à terme implicite entre deux échéances.
```

## `gapbybls`

```
GAPBYBLS Prix d'une option à saut.
  P = GAPBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,SEUIL,VERSEMENT)
  rend le prix d'une option qui s'exerce au-delà du SEUIL mais paie
  l'écart au VERSEMENT : le gain saute au moment de l'exercice, d'où le
  nom.

  Quand le seuil et le versement coïncident, l'option redevient
  ordinaire.

  Exemple :
     gapbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100, 95)

  Voir aussi CASHBYBLS, ASSETBYBLS, SUPERSHAREBYBLS, OPTSTOCKBYBLS.
```

## `instadd`

```
INSTADD Ajoute des instruments à un jeu.
  JEU = INSTADD('Bond',TAUX,REGLEMENT,ECHEANCE,...) crée un jeu et y
  met des obligations. INSTADD(JEU,'OptStock',...) ajoute à un jeu
  existant.

  Les types reconnus sont 'Bond', 'CashFlow', 'Fixed', 'Float', 'Swap',
  'OptStock', 'Barrier', 'Lookback', 'Asian', 'Cap', 'Floor' et
  'Swaption'. Les arguments suivent l'ordre des champs du type, et les
  champs omis prennent NaN.

  Un jeu d'instruments sert à valoriser un portefeuille entier d'un
  coup : INTENVPRICE prend le jeu et la courbe, et rend un prix par
  instrument.

  Exemple :
     jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
     jeu = instadd(jeu, 'Bond', 0.04, '01-Jan-2024', '01-Jan-2027');

  Voir aussi INSTDISP, INSTGET, INSTSELECT, INSTLENGTH, INTENVPRICE.
```

## `instaddfield`

```
INSTADDFIELD Ajoute des instruments d'un type quelconque.
  JEU = INSTADDFIELD('FieldName',N,'Data',D,'Type',T) crée un type
  d'instrument défini par ses seuls champs, sans que la boîte à outils
  ait à le connaître. 'FieldClass' précise 'dble' ou 'char' par champ.

  Exemple :
     jeu = instaddfield('FieldName', {'Nominal','Echeance'}, ...
                        'Data', {100, datenum('01-Jan-2030')}, ...
                        'Type', 'Maison');

  Voir aussi INSTADD, INSTSETFIELD, INSTGET.
```

## `instdelete`

```
INSTDELETE Retire des instruments d'un jeu.
  J = INSTDELETE(JEU,'Index',I) retire les instruments de numéros
  donnés ; 'Type' retire tout un type ; 'FieldName' et 'Data' retirent
  ceux qui répondent au critère.

  Exemple :
     jeu = instdelete(jeu, 'Index', 2);

  Voir aussi INSTADD, INSTSELECT.
```

## `instdisp`

```
INSTDISP Écrit le contenu d'un jeu d'instruments.
  Une table par type, une ligne par instrument, précédée de son numéro
  dans le jeu.

  Exemple :
     instdisp(instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029'))

  Voir aussi INSTADD, INSTGET, INSTLENGTH.
```

## `instfields`

```
INSTFIELDS Noms des champs d'un jeu d'instruments.
  C = INSTFIELDS(JEU) rend tous les noms de champs rencontrés.
  INSTFIELDS(JEU,'Type',T) ne rend que ceux du type T.

  Exemple :
     instfields(jeu, 'Type', 'Bond')

  Voir aussi INSTTYPES, INSTGET, INSTDISP.
```

## `instget`

```
INSTGET Données d'un jeu d'instruments.
  [A,B,...] = INSTGET(JEU,'FieldList',{'CouponRate','Maturity'}) rend
  une sortie par champ demandé. 'Type' limite à un type d'instrument,
  'Index' à des numéros donnés.

  Un instrument dont le type ne porte pas le champ demandé rend NaN.

  Exemple :
     [taux, echeance] = instget(jeu, 'FieldList', {'CouponRate','Maturity'})

  Voir aussi INSTGETCELL, INSTSELECT, INSTFIELDS, INSTDISP.
```

## `instgetcell`

```
INSTGETCELL Données d'un jeu d'instruments, rendues en cellules.
  [D,N] = INSTGETCELL(JEU,'FieldList',F,'Type',T,'Index',I) rend, dans
  D, une cellule par champ demandé, et leurs noms dans N.

  Exemple :
     [d, n] = instgetcell(jeu, 'FieldList', {'CouponRate','Maturity'})

  Voir aussi INSTGET, INSTFIELDS, INSTSELECT.
```

## `instlength`

```
INSTLENGTH Nombre d'instruments d'un jeu.
  Exemple :
     instlength(instadd('Bond', [0.05; 0.04], '01-Jan-2024', '01-Jan-2029'))

  Voir aussi INSTADD, INSTTYPES, INSTDISP.
```

## `instselect`

```
INSTSELECT Sous-jeu d'instruments répondant à un critère.
  [J,I] = INSTSELECT(JEU,'FieldName',N,'Data',D) garde les instruments
  dont le champ N vaut D. INSTSELECT(JEU,'Type',T) garde ceux d'un
  type ; INSTSELECT(JEU,'Index',I) ceux de numéros donnés.

  Exemple :
     [court, rangs] = instselect(jeu, 'FieldName', 'CouponRate', 'Data', 0.05);

  Voir aussi INSTGET, INSTDELETE, INSTFIELDS.
```

## `instsetfield`

```
INSTSETFIELD Change la valeur d'un champ dans un jeu d'instruments.
  J = INSTSETFIELD(JEU,'Index',I,'FieldName',N,'Data',D) écrit D dans
  le champ N des instruments de numéros I. 'Type' désigne les
  instruments par leur type.

  Exemple :
     jeu = instsetfield(jeu, 'Index', 1, 'FieldName', 'CouponRate', ...
                        'Data', 0.06);

  Voir aussi INSTADDFIELD, INSTGET, INSTADD.
```

## `insttypes`

```
INSTTYPES Types d'instruments présents dans un jeu.
  Exemple :
     insttypes(instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029'))

  Voir aussi INSTADD, INSTFIELDS, INSTLENGTH.
```

## `intenvget`

```
INTENVGET Lit un champ d'un environnement de taux.
  V = INTENVGET(COURBE,'Rates') rend les taux. Sans nom de champ, la
  structure entière est rendue ; avec plusieurs noms, autant de
  sorties.

  Exemple :
     taux = intenvget(courbe, 'Rates');

  Voir aussi INTENVSET, INTENVPRICE.
```

## `intenvprice`

```
INTENVPRICE Prix de tous les instruments d'un jeu, sur une courbe.
  P = INTENVPRICE(COURBE,JEU) valorise chaque instrument selon son
  type : obligations, flux, branches fixe et variable, échanges.

  L'intérêt d'un jeu d'instruments est là : un portefeuille entier se
  valorise d'un appel, et la même courbe sert à tous.

  Exemple :
     jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
     intenvprice(courbe, jeu)

  Voir aussi INTENVSENS, INSTADD, BONDBYZERO, SWAPBYZERO.
```

## `intenvsens`

```
INTENVSENS Sensibilités d'un jeu d'instruments à un déplacement de courbe.
  [D,G,P] = INTENVSENS(COURBE,JEU) rend la dérivée première et la
  dérivée seconde du prix par rapport à un déplacement parallèle de la
  courbe, ainsi que le prix lui-même.

  Un déplacement parallèle n'est pas le seul mouvement possible, mais
  c'est celui qui explique la plus grande part des variations d'une
  courbe : la sensibilité qu'on en tire suffit à couvrir un
  portefeuille au premier ordre.

  Les dérivées sont calculées par différences finies centrées sur la
  courbe déplacée.

  Exemple :
     [d, g, p] = intenvsens(courbe, jeu)

  Voir aussi INTENVPRICE, BNDDURP, INSTADD.
```

## `intenvset`

```
INTENVSET Construit ou modifie un environnement de taux.
  COURBE = INTENVSET('Rates',R,'StartDates',D1,'EndDates',D2,...)
  range une courbe de taux dans une structure que les fonctions de
  valorisation savent lire. Les autres propriétés sont 'Compounding'
  (2 par défaut), 'Basis' (0), 'ValuationDate' et 'EndMonthRule'.

  INTENVSET(COURBE,'Rates',R) modifie une courbe existante.
  INTENVSET('Disc',F,...) part des facteurs d'actualisation plutôt que
  des taux : les taux s'en déduisent.

  Les dates de début manquantes prennent la date de valorisation, et
  celle-ci, si elle manque, la première date de début.

  Exemple :
     c = intenvset('Rates', [0.03; 0.035], 'StartDates', '01-Jan-2024', ...
                   'EndDates', {'01-Jan-2025'; '01-Jan-2026'});

  Voir aussi INTENVGET, INTENVPRICE, INTENVSENS, BONDBYZERO.
```

## `lookbackbybls`

```
LOOKBACKBYBLS Prix d'une option rétrospective, formule fermée.
  P = LOOKBACKBYBLS(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE) rend
  le prix d'une option dont le gain dépend de l'extremum atteint par le
  cours pendant la vie de l'option.

  EXERCICE valant NaN ou zéro demande une rétrospective à prix
  d'exercice flottant : l'achat paie le cours final moins le plus bas
  atteint, la vente le plus haut moins le cours final. Un prix
  d'exercice donné demande la variante à prix fixe, où l'achat paie
  l'excédent du plus haut sur ce prix.

  Une rétrospective flottante ne peut pas finir sans valeur : son gain
  est l'amplitude du parcours, toujours positive. C'est pourquoi elle
  coûte plus cher qu'une option ordinaire.

  Les formules sont celles de Goldman, Sosin et Gatto pour le prix
  flottant, de Conze et Viswanathan pour le prix fixe. L'extremum
  observé jusqu'ici est pris égal au cours du jour.

  Exemple :
     lookbackbybls(c, s, 'call', NaN, '01-Jan-2024', '01-Jan-2025')

  Voir aussi BARRIERBYBLS, ASIANBYKV, OPTSTOCKBYBLS.
```

## `matlibre_arbre_valoriser`

```
MATLIBRE_ARBRE_VALORISER Récurrence arrière sur un arbre binomial.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_bls_general`

```
MATLIBRE_BLS_GENERAL Formule de Black et Scholes à coût de portage.
  Le coût de portage vaut le taux moins le rendement de dividende pour
  une action, zéro pour un contrat à terme, la différence des taux pour
  une devise. Une seule formule couvre les trois.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_bls_parametres`

```
MATLIBRE_BLS_PARAMETRES Extrait les paramètres de Black et Scholes.
  Le taux est celui de la courbe à l'échéance, ramené en composition
  continue ; le rendement de dividende est celui du descripteur
  d'actif, converti en taux continu quand les dividendes sont en
  espèces.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cds_branches`

```
MATLIBRE_CDS_BRANCHES Valeurs actuelles des deux branches d'un contrat.
  L'annuité est la valeur d'une prime unitaire, la protection celle du
  versement en cas de défaut. Le rapport des deux est l'écart
  d'équilibre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cds_courbe`

```
MATLIBRE_CDS_COURBE Environnement de taux tiré d'une matrice [dates taux].
  Un environnement déjà construit passe tel quel.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cds_ecart`

```
MATLIBRE_CDS_ECART Écart d'équilibre d'un contrat de protection.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cds_echeancier`

```
MATLIBRE_CDS_ECHEANCIER Dates de prime d'un contrat de protection.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cds_hasard`

```
MATLIBRE_CDS_HASARD Taux de hasard tirés de probabilités de défaut cumulées.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cds_survie`

```
MATLIBRE_CDS_SURVIE Probabilité de survie sous des taux de hasard constants par morceaux.
  Le taux de hasard est la probabilité instantanée de défaut sachant
  qu'il n'a pas encore eu lieu ; la survie est l'exponentielle de son
  intégrale, changée de signe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_champ_instrument`

```
MATLIBRE_CHAMP_INSTRUMENT Met une donnée à la forme attendue par le jeu.
  Les champs de texte deviennent un tableau de cellules d'une ligne par
  instrument ; les champs numériques une matrice, les dates converties
  en numéros de série.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_courbe_completer`

```
MATLIBRE_COURBE_COMPLETER Remplit les champs déductibles d'une courbe.
  Les dates de début, la date de valorisation, les durées et les
  facteurs d'actualisation se déduisent les uns des autres ; on ne
  demande à l'utilisateur que ce qu'il est seul à savoir.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_courbe_deplacer`

```
MATLIBRE_COURBE_DEPLACER Déplace toute la courbe d'un même écart.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_courbe_escompte`

```
MATLIBRE_COURBE_ESCOMPTE Facteurs d'actualisation aux dates demandées.
  Les taux sont interpolés linéairement en fonction du temps, et
  prolongés à plat au-delà des bornes de la courbe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_dates_reset`

```
MATLIBRE_DATES_RESET Dates de fixation et de paiement d'un échéancier.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_elargir`

```
MATLIBRE_ELARGIR Complète une matrice à droite par des NaN.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_instrument_valeurs`

```
MATLIBRE_INSTRUMENT_VALEURS Champs d'un instrument, rangés en structure.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_ajouter`

```
MATLIBRE_JEU_AJOUTER Ajoute des instruments d'un type à un jeu.
  Les données sont diffusées : un scalaire vaut pour tous les
  instruments ajoutés, et le nombre d'instruments est celui du plus
  grand argument.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_colonne`

```
MATLIBRE_JEU_COLONNE Valeurs d'un champ, pour des instruments donnés.
  Un instrument dont le type ne porte pas le champ reçoit NaN, ou une
  chaîne vide s'il s'agit d'un champ de texte.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_extraire`

```
MATLIBRE_JEU_EXTRAIRE Sous-jeu portant les instruments demandés.
  Les numéros sont renumérotés de un à N, dans l'ordre d'origine.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_filtrer`

```
MATLIBRE_JEU_FILTRER Numéros des instruments répondant à un critère.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_options`

```
MATLIBRE_JEU_OPTIONS Lit les options communes aux fonctions INST*.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_situer`

```
MATLIBRE_JEU_SITUER Type et rang local d'un instrument, d'après son numéro.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jeu_vide`

```
MATLIBRE_JEU_VIDE Jeu d'instruments sans instrument.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_modele_instrument`

```
MATLIBRE_MODELE_INSTRUMENT Champs attendus par un type d'instrument.
  Les noms et l'ordre sont ceux de MATLAB : c'est dans cet ordre que
  INSTADD prend ses arguments.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_options_actions`

```
MATLIBRE_OPTIONS_ACTIONS Prix et paramètres d'options sur action.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_plafond`

```
MATLIBRE_PLAFOND Somme des options élémentaires d'un plafond ou d'un plancher.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_prix_instrument`

```
MATLIBRE_PRIX_INSTRUMENT Valorise un instrument sur une courbe de taux.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `optstockbybls`

```
OPTSTOCKBYBLS Prix d'options européennes sur action.
  P = OPTSTOCKBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,EXERCICE) rend
  le prix de Black et Scholes, le taux étant lu sur la courbe et le
  dividende sur le descripteur d'actif. TYPE vaut 'call' ou 'put', et
  peut être un tableau de cellules.

  Exemple :
     c = intenvset('Rates', 0.05, 'StartDates', '01-Jan-2024', ...
                   'EndDates', '01-Jan-2025', 'Compounding', -1);
     s = stockspec(0.2, 100);
     optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 95)

  Voir aussi OPTSTOCKSENSBYBLS, BLSPRICE, STOCKSPEC, INTENVSET.
```

## `optstocksensbybls`

```
OPTSTOCKSENSBYBLS Sensibilités d'options européennes sur action.
  S = OPTSTOCKSENSBYBLS(...,SORTIES) rend les grandeurs demandées.
  SORTIES est un tableau de cellules parmi 'Price', 'Delta', 'Gamma',
  'Vega', 'Lambda', 'Rho', 'Theta' ; par défaut, le prix seul.

  Exemple :
     optstocksensbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 95, ...
                       {'Price', 'Delta', 'Gamma'})

  Voir aussi OPTSTOCKBYBLS, BLSDELTA, BLSGAMMA, BLSVEGA.
```

## `stockspec`

```
STOCKSPEC Décrit un actif sous-jacent.
  S = STOCKSPEC(VOLATILITE,COURS) décrit une action sans dividende.
  STOCKSPEC(...,TYPE,MONTANTS,DATES) ajoute des dividendes : TYPE vaut
  'continuous' pour un taux continu, 'cash' pour des montants versés à
  des dates données, 'constant' pour un rendement discret.

  Exemple :
     s = stockspec(0.2, 100);
     s = stockspec(0.2, 100, 'continuous', 0.03);

  Voir aussi INTENVSET, OPTSTOCKBYBLS, CRRTREE.
```

## `supersharebybls`

```
SUPERSHAREBYBLS Prix d'une superaction.
  P = SUPERSHAREBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,BASSE,HAUTE) rend
  le prix d'un titre qui livre une part de l'actif si le cours final
  tombe entre les deux bornes, et rien sinon.

  C'est la brique élémentaire de la théorie des marchés complets : avec
  assez de superactions on reproduit n'importe quel gain, comme on
  reproduit une fonction par des indicatrices.

  Exemple :
     supersharebybls(c, s, '01-Jan-2024', '01-Jan-2025', 90, 110)

  Voir aussi CASHBYBLS, ASSETBYBLS, GAPBYBLS.
```

## `swapbyzero`

```
SWAPBYZERO Prix d'un échange de taux, sur une courbe zéro-coupon.
  [P,T] = SWAPBYZERO(COURBE,[TAUXFIXE ECART],REGLEMENT,ECHEANCE) rend
  la valeur de l'échange pour le payeur de taux variable — la branche
  fixe reçue moins la branche variable payée — et le taux d'échange qui
  annulerait cette valeur.

  Ce taux d'échange est le taux fixe du marché : celui pour lequel
  personne ne paie rien à l'entrée. Il se lit directement sur la
  courbe, comme la valeur de la branche variable divisée par la somme
  des facteurs d'actualisation pondérés.

  FREQUENCES vaut [fixe variable], 1 et 1 par défaut.

  Exemple :
     [p, t] = swapbyzero(courbe, [0.04 0], '01-Jan-2024', '01-Jan-2029')

  Voir aussi FIXEDBYZERO, FLOATBYZERO, BONDBYZERO.
```

## `swaptionbyblk`

```
SWAPTIONBYBLK Prix d'une option sur échange de taux, modèle de Black.
  P = SWAPTIONBYBLK(COURBE,TYPE,EXERCICE,REGLEMENT,DATEEXERCICE,
  ECHEANCE,VOLATILITE) rend le prix d'une option d'entrer, à la date
  d'exercice, dans un échange de taux allant jusqu'à l'échéance. TYPE
  vaut 'call' pour le payeur de fixe, 'put' pour le receveur.

  L'option porte sur le taux d'échange à terme, dont la volatilité est
  donnée. Le facteur d'actualisation est l'annuité de l'échange sous-
  jacent : c'est elle qui transforme un taux en montant.

  Payeur moins receveur vaut l'échange à terme lui-même, soit l'annuité
  fois l'écart entre le taux à terme et le taux d'exercice.

  Exemple :
     swaptionbyblk(courbe, 'call', 0.04, '01-Jan-2024', '01-Jan-2026', ...
                   '01-Jan-2031', 0.2, 2)

  Voir aussi CAPBYBLK, FLOORBYBLK, BLKPRICE, SWAPBYZERO.
```

## `time2date`

```
TIME2DATE Date située à une durée donnée, comptée en périodes.
  D = TIME2DATE(REGLEMENT,TEMPS,COMPOSITION,BASE) est l'inverse de
  DATE2TIME : la date dont la durée depuis le règlement vaut TEMPS.

  L'inversion n'est pas immédiate : une convention comme 30/360 ne
  compte pas les jours linéairement. La date est donc cherchée par
  dichotomie sur le nombre de jours, puis arrondie au jour.

  Exemple :
     datestr(time2date('01-Jan-2024', 4, 2, 0))     % 01-Jan-2026

  Voir aussi DATE2TIME, YEARFRAC.
```

## `zeroprice`

```
ZEROPRICE Prix d'une obligation zéro-coupon.
  P = ZEROPRICE(RENDEMENT,REGLEMENT,ECHEANCE,PERIODE,BASE) rend le prix
  pour cent de nominal. PERIODE vaut 2 par défaut : le rendement est
  composé semestriellement, comme le veut la convention obligataire.

  Une obligation sans coupon ne verse rien avant l'échéance : son prix
  est le seul facteur d'actualisation, et sa duration est sa maturité.

  Exemple :
     zeroprice(0.05, '01-Jan-2024', '01-Jan-2029')

  Voir aussi ZEROYIELD, BONDBYZERO, BNDPRICE.
```

## `zeroyield`

```
ZEROYIELD Rendement d'une obligation zéro-coupon.
  R = ZEROYIELD(PRIX,REGLEMENT,ECHEANCE,PERIODE,BASE) est l'inverse de
  ZEROPRICE.

  Exemple :
     zeroyield(78.35, '01-Jan-2024', '01-Jan-2029')

  Voir aussi ZEROPRICE, BNDYIELD.
```

