# Toolbox `vehicule`

```
% Vehicle Dynamics Blockset — dynamique du véhicule.
%
% Tout ce qu'un véhicule peut faire passe par quatre empreintes de pneu de
% la taille d'une main ; le reste n'est qu'une façon de leur demander des
% choses.
%
% Trajectoire
%   bicycleModel   - Modèle cinématique à direction avant
%
% Efforts
%   tireForce      - Formule magique de Pacejka, avec sa limite d'adhérence
%   longitudinal   - Accélération sous traînée, roulement et pente
%
% Transmission
%   gearRatioSpeed - Vitesse pour un régime et un rapport donnés
```

## `bicycleModel`

```
BICYCLEMODEL Un pas du modèle bicyclette cinématique.
  ETAT = BICYCLEMODEL(ETAT,VITESSE,BRAQUAGE,EMPATTEMENT,DT) avance d'un
  pas. ETAT vaut [X Y THETA], BRAQUAGE est en radians.

  À braquage constant, le véhicule décrit un cercle de rayon
  EMPATTEMENT / tan(BRAQUAGE) : c'est la formule d'Ackermann, et le
  rayon ne dépend pas de la vitesse. C'est ce qui fait de ce modèle un
  modèle *cinématique* : il ignore le glissement, la force centrifuge et
  la limite d'adhérence, donc il ne vaut qu'à basse vitesse.

  Braquer autant d'un côté puis de l'autre ramène le cap mais déplace
  latéralement : c'est un changement de file, et c'est ainsi qu'on en
  construit un.

  Exemple :
     etat = [0 0 0];
     for k = 1:1000
         etat = bicycleModel(etat, 5, deg2rad(10), 2.7, 0.01);
     end

  Voir aussi BICYCLEKINEMATICS, TIREFORCE, PUREPURSUIT.
```

## `gearRatioSpeed`

```
GEARRATIOSPEED Vitesse du véhicule pour un régime moteur donné.
  VITESSE = GEARRATIOSPEED(REGIME,RAPPORT,RAPPORTFINAL,RAYONROUE) rend
  la vitesse du véhicule. REGIME est en tours par minute, VITESSE en
  mètres par seconde.

  La boîte ne fait qu'échanger couple contre vitesse : une fois le
  rapport choisi, régime moteur et vitesse sont liés rigidement. La roue
  tourne à REGIME/(RAPPORT x RAPPORTFINAL) tours par minute et avance de
  2 pi R par tour — c'est tout le calcul.

  La vitesse est donc proportionnelle au régime et inversement
  proportionnelle à la démultiplication.

  Exemple :
     gearRatioSpeed(3000, 1.0, 3.9, 0.32) * 3.6   % en km/h, en 4e
     gearRatioSpeed(6000, 1.0, 3.9, 0.32)         % le double

  Voir aussi LONGITUDINAL, TIREFORCE.
```

## `longitudinal`

```
LONGITUDINAL Accélération longitudinale avec résistances.
  A = LONGITUDINAL(FORCE,MASSE,VITESSE,CX,SURFACE,RHO,CRR,PENTE) rend
  l'accélération, en mètres par seconde carrée, sous une force motrice
  et contre les trois résistances :

     la traînée      0.5 RHO CX SURFACE V^2, qui croît comme le carré
     le roulement    CRR MASSE g cos(PENTE), à peu près constant
     la pente        MASSE g sin(PENTE)

  SURFACE vaut 2,2 m2, RHO 1,225 kg/m3, CRR 0,012 et PENTE zéro par
  défaut.

  La vitesse maximale est celle où la poussée égale les résistances :
  on la trouve en cherchant le zéro de cette fonction. Doubler la
  vitesse quadruple la traînée, d'où le peu qu'on gagne en puissance
  aux grandes vitesses.

  Une pente de dix pour cent coûte g sin(atan(0,1)), près d'un mètre par
  seconde carrée : à la portée d'un petit moteur, mais pas négligeable.

  Exemple :
     longitudinal(0, 1500, 0, 0.3)             % -0.118 : le roulement
     fzero(@(v) longitudinal(2500, 1500, v, 0.3), [1 200])

  Voir aussi TIREFORCE, GEARRATIOSPEED, BICYCLEMODEL.
```

## `tireForce`

```
TIREFORCE Force du pneu par la formule magique de Pacejka.
  F = TIREFORCE(GLISSEMENT,CHARGEVERTICALE,B,C,D,E) rend la force
  transmise par le pneu. B, C, D et E sont les quatre coefficients de la
  formule ; leurs valeurs par défaut décrivent un pneu de tourisme sur
  route sèche.

  La formule est dite magique parce qu'elle n'a pas de fondement
  physique : c'est une forme qui s'ajuste bien aux mesures, et rien de
  plus. Elle en reproduit néanmoins tout ce qui compte.

  La force ne croît pas indéfiniment avec le glissement : elle passe par
  un maximum vers dix à vingt pour cent, puis retombe. Ce maximum est la
  limite d'adhérence, et la zone au-delà est instable — c'est là que la
  roue se bloque ou patine. Tout l'ABS et tout le contrôle de traction
  consistent à ne pas y entrer.

  Près de zéro la relation est linéaire : c'est la rigidité de dérive,
  celle qu'emploient les modèles linéarisés. La formule est impaire, et
  proportionnelle à la charge verticale — d'où l'intérêt de charger
  l'essieu moteur au démarrage.

  Exemple :
     g = linspace(0, 0.6, 601);
     [Fmax, k] = max(arrayfun(@(x) tireForce(x, 4000), g));
     g(k)                            % le glissement optimal
     Fmax / 4000                     % le coefficient d'adherence

  Voir aussi LONGITUDINAL, BICYCLEMODEL.
```

