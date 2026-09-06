# Toolbox `maintenance-predictive`

```
% Predictive Maintenance Toolbox — surveillance et pronostic.
%
% Une machine ne tombe pas en panne sans prévenir : elle vibre autrement.
% La démarche va des descripteurs à l'indicateur, puis de l'indicateur à
% la durée de vie restante.
%
% Descripteurs
%   faultFeatures    - Efficace, crête, kurtosis, asymétrie, centroïde
%
% Indicateur
%   healthIndicator  - Une seule courbe, par composantes principales
%
% Pronostic
%   rulDegradation   - Par extrapolation de la tendance : peu d'exigences
%   rulSimilarity    - Par similarité d'historiques : aucune forme imposée
```

## `faultFeatures`

```
FAULTFEATURES Descripteurs vibratoires : efficace, crête, kurtosis, centroïde.
  D = FAULTFEATURES(SIGNAL,FS) rend une structure de six descripteurs :

     rms           la valeur efficace : l'énergie du signal
     crete         le maximum en valeur absolue
     facteurCrete  leur rapport : la « pointe » du signal
     kurtosis      le moment d'ordre quatre normalisé
     asymetrie     le moment d'ordre trois normalisé
     centroide     la fréquence où l'énergie se concentre

  Chacun répond à un défaut différent, et c'est pour cela qu'on les
  calcule tous. Le kurtosis, en particulier, monte dès que des chocs
  apparaissent — la signature d'un écaillage de roulement — alors que la
  valeur efficace bouge à peine : un défaut naissant a peu d'énergie
  mais une forme très pointue.

  Les repères : le kurtosis d'un bruit gaussien vaut trois, celui d'un
  sinus 1,5. Le centroïde d'un sinus pur est sa fréquence ; celui d'un
  bruit blanc tombe au milieu de la bande.

  Exemple :
     d = faultFeatures(vibration, 10000);
     d.kurtosis                      % au-dessus de 3 : des chocs
     d.centroide                     % ou l'energie se concentre

  Voir aussi HEALTHINDICATOR, RULDEGRADATION, RULSIMILARITY.
```

## `healthIndicator`

```
HEALTHINDICATOR Indicateur de santé : première composante principale
  des descripteurs, normalisée entre 0 et 1.

  INDICATEUR = HEALTHINDICATOR(DONNEES) prend une matrice à une ligne
  par cycle et une colonne par descripteur, et rend une seule courbe.

  Plusieurs descripteurs, une seule courbe : l'analyse en composantes
  principales trouve la direction où ils varient le plus ensemble, et
  c'est celle-là qui suit la dégradation. Les descripteurs n'ont pas les
  mêmes unités ni les mêmes ordres de grandeur, et la normalisation
  finale rend l'indicateur comparable d'une machine à l'autre.

  L'orientation est fixée : l'indicateur croît toujours, quel que soit
  le signe des descripteurs. Sans cela un seuil n'aurait pas de sens.

  Il croît par blocs, non à chaque cycle : le bruit de mesure domine les
  écarts d'un cycle au suivant, et c'est la tendance qui porte
  l'information.

  Exemple :
     sante = healthIndicator([efficaces, kurtosis, centroides]);
     rulDegradation(sante, 1.0)

  Voir aussi FAULTFEATURES, RULDEGRADATION, RULSIMILARITY, PCA.
```

## `rulDegradation`

```
RULDEGRADATION Durée de vie restante par extrapolation linéaire.
  RUL = RULDEGRADATION(INDICATEUR,SEUIL) rend le nombre de cycles avant
  que la tendance n'atteigne le seuil.

  La méthode est directe : ajuster une droite sur l'indicateur, et
  chercher quand elle coupera le seuil. Elle demande peu — un seul
  historique, le sien — et ne vaut que si la dégradation est bien
  linéaire.

  Sur une dégradation accélérée, l'extrapolation linéaire est trop
  optimiste tant qu'on est loin de la fin : la droite sous-estime la
  pente à venir. RULSIMILARITY, qui n'impose aucune forme, fait mieux
  dans ce cas — au prix d'historiques à fournir.

  Un indicateur qui ne monte pas rend l'infini : rien ne permet alors de
  prédire une panne, et le dire vaut mieux qu'inventer un chiffre. Un
  seuil déjà franchi rend zéro, jamais un nombre négatif.

  Exemple :
     rulDegradation(0.01 * (1:50).', 1.0)        % 50 cycles restants
     rulDegradation(ones(50, 1), 1.0)            % Inf : rien ne bouge

  Voir aussi RULSIMILARITY, HEALTHINDICATOR.
```

## `rulSimilarity`

```
RULSIMILARITY Durée de vie restante par similarité de trajectoires.
  Les trajectoires historiques les plus proches, au sens de l'écart
  quadratique sur la partie commune, votent au prorata de l'inverse de
  leur distance.

  RUL = RULSIMILARITY(TRAJECTOIRE,HISTORIQUES,DUREESVIE) compare la
  trajectoire en cours à celles de machines dont on connaît la fin.
  HISTORIQUES est une cellule de vecteurs, DUREESVIE leurs durées.

  Chaque historique vote pour ce qu'il lui restait au même stade, au
  prorata de sa ressemblance. La méthode n'exige aucune forme de
  dégradation particulière — seulement des exemples, ce qui la rend
  supérieure à l'extrapolation linéaire dès que la dégradation
  s'accélère.

  Deux propriétés la valident : plus on observe, moins il reste ; et une
  trajectoire identique à un historique connu hérite de sa durée de vie.

  Sa faiblesse est celle de tout apprentissage par l'exemple : elle ne
  sait rien d'un mode de défaillance qu'aucun historique ne contient.

  Exemple :
     rul = rulSimilarity(enCours, historiques, [100 120 90 110]);

  Voir aussi RULDEGRADATION, HEALTHINDICATOR, FAULTFEATURES.
```

