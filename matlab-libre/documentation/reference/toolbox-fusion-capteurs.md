# Toolbox `fusion-capteurs`

```
% Sensor Fusion and Tracking Toolbox — fusion de capteurs.
%
% Fusion d'attitude
%   complementaryFilter - Un pôle, deux gains : le plus simple des filtres
%   kalmanFilter        - Un pas de filtre de Kalman linéaire
%   madgwickUpdate      - Attitude en quaternion, par descente de gradient
%
% Suivi de plusieurs objets
%   trackAssign         - Association mesures / pistes, avec seuil
```

## `complementaryFilter`

```
COMPLEMENTARYFILTER Fusion d'un angle bruité et d'une vitesse dérivante.
  ANGLE = COMPLEMENTARYFILTER(ANGLEACCEL,VITESSEGYRO,DT,ALPHA,PRECEDENT)
  combine un angle mesuré — juste en moyenne mais bruité — et une
  vitesse angulaire — propre mais dont l'intégrale dérive :

     angle = ALPHA (precedent + vitesse DT) + (1 - ALPHA) angleAccel

  ALPHA vaut 0,98 par défaut ; PRECEDENT vaut l'angle mesuré au premier
  appel, ce qui évite un transitoire au démarrage.

  C'est un passe-haut sur le gyromètre et un passe-bas sur
  l'accéléromètre, dont la somme fait exactement un — d'où « filtre
  complémentaire ». La constante de temps de la coupure vaut
  ALPHA DT / (1 - ALPHA) : c'est la durée pendant laquelle on fait
  confiance au gyromètre avant que l'accéléromètre reprenne la main.

  Le réglage d'ALPHA arbitre entre bruit et retard, une fois pour
  toutes. KALMANFILTER refait cet arbitrage à chaque pas à partir des
  covariances, et sait en prime estimer le biais du gyromètre — au prix
  d'un modèle qu'il faut écrire.

  Exemple :
     angle = 0;
     for k = 1:100
         angle = complementaryFilter(mesure(k), gyro(k), 0.01, 0.98, angle);
     end

  Voir aussi KALMANFILTER, MADGWICKUPDATE.
```

## `kalmanFilter`

```
KALMANFILTER Un pas de filtre de Kalman linéaire (prédiction et correction).
  [X,P] = KALMANFILTER(X,P,Z,A,H,Q,R) fait un pas complet : la
  prédiction par le modèle A, puis la correction par la mesure Z.
  [X,P] = KALMANFILTER(X,P,Z,A,H,Q,R,U,B) ajoute une commande connue.

     X  l'état estimé          P  sa covariance
     Z  la mesure              A  la matrice d'évolution
     H  la matrice de mesure   Q  le bruit de modèle
     R  le bruit de mesure     U, B la commande et son effet

  Le gain K = P H' / (H P H' + R) est ce qui distingue ce filtre d'une
  moyenne pondérée fixe : il se recalcule à chaque pas selon la
  confiance qu'on a dans l'estimation courante face à la mesure. Quand
  P est grand, la mesure l'emporte ; quand il est petit, le modèle.

  Le filtre estime aussi ce qu'aucune mesure ne donne — une vitesse, un
  biais de capteur — pourvu que le modèle les relie à ce qu'on mesure.
  C'est là son intérêt principal, et il ne tient qu'à cette liaison.

  Exemple :
     A = [1 0.1; 0 1]; H = [1 0];
     Q = diag([1e-4 1e-3]); R = 0.5;
     x = [0; 0]; P = eye(2);
     [x, P] = kalmanFilter(x, P, mesure, A, H, Q, R);

  Voir aussi COMPLEMENTARYFILTER, EKFPREDICT, EKFUPDATE, TRACKASSIGN.
```

## `madgwickUpdate`

```
MADGWICKUPDATE Estimation d'attitude par la méthode de Madgwick.
  Q = MADGWICKUPDATE(Q,GYRO,ACCEL,DT,BETA) fait avancer d'un pas
  l'estimation d'attitude, rendue en quaternion [W X Y Z].

     GYRO   la vitesse angulaire, trois axes, en radians par seconde
     ACCEL  l'accélération mesurée, trois axes ; seule sa direction
            compte, la fonction la normalise
     BETA   le poids de la correction par l'accéléromètre, 0,1 par
            défaut ; zéro revient à intégrer le gyromètre seul

  Le principe : intégrer le gyromètre, puis corriger d'un pas de
  descente de gradient dans la direction qui rapproche la gravité
  prédite de la gravité mesurée. C'est bien moins coûteux qu'un filtre
  de Kalman étendu sur un quaternion, ce qui explique son emploi sur les
  petits calculateurs.

  L'accéléromètre ne voit que la gravité : il fixe le roulis et le
  tangage, jamais le lacet. C'est une limite de principe, non de
  méthode — il faut un magnétomètre pour lever cette dernière
  indétermination.

  Il suppose aussi que l'accélération mesurée est la gravité seule :
  pendant une accélération franche, la correction tire dans une
  direction fausse. BETA règle à quel point on la laisse faire.

  Exemple :
     q = [1 0 0 0];
     for k = 1:1000
         q = madgwickUpdate(q, gyro(k, :), accel(k, :), 0.01, 0.1);
     end
     quat2eul(q)

  Voir aussi COMPLEMENTARYFILTER, KALMANFILTER, QUAT2EUL.
```

## `trackAssign`

```
TRACKASSIGN Association mesures / pistes par plus proche voisin global.
  A = TRACKASSIGN(PISTES,MESURES,SEUIL) rend, pour chaque piste, l'indice
  de la mesure qui lui est attribuée, ou zéro si aucune ne convient.
  PISTES et MESURES ont une ligne par objet et une colonne par
  coordonnée. SEUIL est la distance au-delà de laquelle on préfère ne
  rien attribuer ; il vaut l'infini par défaut.

  Suivre plusieurs objets demande d'abord de savoir quelle mesure va à
  quelle piste. Sans cette étape, deux objets qui se croisent échangent
  leurs identités et les deux trajectoires deviennent fausses.

  Une mesure attribuée ne l'est qu'une fois : les pistes se servent dans
  l'ordre, chacune prenant la plus proche encore libre. Ce n'est pas
  l'optimum global de l'affectation — l'algorithme hongrois le
  donnerait — mais il ne peut pas attribuer la même mesure deux fois,
  ce qui est l'erreur qui coûte le plus cher.

  Le seuil est ce qui distingue le suivi de l'invention : sans lui, une
  piste dont l'objet a disparu s'accroche à n'importe quoi.

  Exemple :
     pistes  = [0 0; 10 0];
     mesures = [10.2 0.3; 0.1 -0.2];
     trackAssign(pistes, mesures)          % [2 1]
     trackAssign(pistes, [0.1 -0.2; 50 50], 3)   % [1 0]

  Voir aussi KALMANFILTER, PDIST2.
```

