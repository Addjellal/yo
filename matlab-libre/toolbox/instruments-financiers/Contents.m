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
