# Toolbox `communications-sans-fil`

```
% WLAN / LTE Toolbox — communications sans fil.
%
% Propagation
%   fspl              - Affaiblissement en espace libre, borné à 0 dB (MATLAB)
%   pathLoss          - Affaiblissement de parcours, exposant réglable
%   rayleighChannel   - Canal à évanouissements, plat ou sélectif
%
% Modulation multiporteuse (signatures de MATLAB)
%   ofdmmod           - Modulation OFDM : préfixe cyclique, porteuses nulles, pilotes
%   ofdmdemod         - Démodulation OFDM, décalage de fenêtre compensé
%
% Mesures
%   evm               - Amplitude du vecteur d'erreur
%   throughputShannon - Capacité du canal : la borne que rien ne franchit
```

## `evm`

```
EVM Amplitude du vecteur d'erreur, en pour cent.
  VALEUR = EVM(RECUS,REFERENCES) rend la racine du rapport entre la
  puissance de l'erreur et celle de la référence, en pour cent.

  C'est la mesure de qualité d'une modulation numérique : elle rapporte
  l'erreur à la référence, donc elle ne dépend pas du niveau. Elle se
  relie directement au rapport signal à bruit — l'EVM en pour cent vaut
  cent fois l'inverse de la racine du RSB.

  Vingt décibels de RSB donnent donc dix pour cent d'EVM, trente
  décibels trois pour cent. Les normes de radiocommunication fixent des
  plafonds d'EVM par ordre de modulation : plus la constellation est
  dense, moins on tolère d'erreur.

  Exemple :
     rng(1);
     reference = exp(1i * (pi/4 + randi([0 3], 48, 5) * pi/2));
     bruit = (randn(size(reference)) + 1i * randn(size(reference))) / sqrt(2);
     evm(reference, reference)       % 0
     evm(reference + 0.1 * bruit, reference)

  Voir aussi OFDMMOD, OFDMDEMOD.
```

## `fspl`

```
FSPL Affaiblissement de propagation en espace libre, en décibels.
  L = FSPL(R,LAMBDA) = 20 log10(4 pi R / LAMBDA) pour une distance R et
  une longueur d'onde LAMBDA en mètres, comme MATLAB. Pour M distances
  et N longueurs d'onde, L est M x N ; avec une seule longueur d'onde,
  L a la forme de R.

  La formule suppose le champ lointain ; plus près, elle rendrait un
  gain. L'affaiblissement est donc borné à 0 dB pour R <= LAMBDA/(4 pi).

  Exemple :
     % Documentation de MATLAB.
     L = fspl(10e3, physconst('LightSpeed') / 10e9)    % 132.4478 dB

  Voir aussi FRIIS, PATHLOSS, RADAREQRNG.
```

## `matlibre_ofdm_indices`

```
MATLIBRE_OFDM_INDICES Indices des sous-porteuses de données d'une grille OFDM.
  [DONNEES,NULLIDX,PILOTIDX] = MATLIBRE_OFDM_INDICES(NFFT,NULLIDX,
  PILOTIDX,FONCTION) vérifie les indices nuls et pilotes (entre 1 et
  NFFT, distincts) et rend, en colonne et dans l'ordre croissant, les
  indices qui restent aux données.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     d = matlibre_ofdm_indices(64, [1:6 33 60:64].', [12 26 40 54].', 'ofdmmod');
     numel(d)                    % 48 : les données de 802.11a

  Voir aussi OFDMMOD, OFDMDEMOD.
```

## `matlibre_ofdm_prefixes`

```
MATLIBRE_OFDM_PREFIXES Longueurs de préfixe cyclique, une par symbole.
  CP = MATLIBRE_OFDM_PREFIXES(CPLEN,NSYM,NFFT,FONCTION) développe un
  scalaire en NSYM longueurs, ou vérifie une ligne de NSYM longueurs.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     cp = matlibre_ofdm_prefixes(16, 3, 64, 'ofdmmod')     % 16 16 16

  Voir aussi OFDMMOD, OFDMDEMOD.
```

## `matlibre_ofdm_surechantillonnage`

```
MATLIBRE_OFDM_SURECHANTILLONNAGE Refuse un facteur de suréchantillonnage autre que un.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_ofdm_surechantillonnage({'OversamplingFactor', 1}, 'ofdmmod')

  Voir aussi OFDMMOD, OFDMDEMOD.
```

## `ofdmdemod`

```
OFDMDEMOD Démodulation OFDM : retire le préfixe, transforme, trie les porteuses.
  Y = OFDMDEMOD(X,NFFT,CPLEN) démodule le signal X (une colonne par
  flux) modulé par OFDMMOD sur NFFT sous-porteuses avec des préfixes
  cycliques de CPLEN échantillons (scalaire, ou ligne d'une longueur par
  symbole). Y est NDataSC x NSym x NStreams.
  Y = OFDMDEMOD(X,NFFT,CPLEN,SYMOFFSET) place la fenêtre de la FFT
  SYMOFFSET échantillons après le début de chaque symbole (CPLEN par
  défaut : juste après le préfixe ; un scalaire ou une ligne par
  symbole). Une fenêtre avancée dans le préfixe décale le symbole
  circulairement ; la rotation de phase qui en résulte sur chaque
  porteuse est compensée, et l'aller-retour reste exact.
  Y = OFDMDEMOD(X,NFFT,CPLEN,SYMOFFSET,NULLIDX) écarte les porteuses
  nulles ; [Y,PILOTS] = OFDMDEMOD(...,NULLIDX,PILOTIDX) rend aussi les
  pilotes, NPilot x NSym x NStreams.

  Les indices suivent OFDMMOD : de 1 à NFFT, de la fréquence la plus
  négative à la plus positive. La FFT est celle de MATLAB, sans facteur,
  inverse exacte de l'IFFT d'OFDMMOD. L'option 'OversamplingFactor'
  n'est acceptée qu'à sa valeur un.

  Exemple :
     x = qammod(randi([0 15], 64, 2), 16);
     y = ofdmdemod(ofdmmod(x, 64, [16 32]), 64, [16 32]);
     max(abs(y(:) - x(:))) < 1e-12        % 1

  Voir aussi OFDMMOD, QAMDEMOD, FFT.
```

## `ofdmmod`

```
OFDMMOD Modulation OFDM, avec préfixe cyclique, porteuses nulles et pilotes.
  Y = OFDMMOD(X,NFFT,CPLEN) module les sous-porteuses X (NDataSC x NSym
  x NStreams) sur NFFT sous-porteuses, et précède chaque symbole de son
  préfixe cyclique de CPLEN échantillons : un scalaire, ou une ligne
  d'une longueur par symbole. Y a une colonne par flux.
  Y = OFDMMOD(X,NFFT,CPLEN,NULLIDX) laisse vides les sous-porteuses
  NULLIDX (bandes de garde, continu) ; Y = OFDMMOD(X,NFFT,CPLEN,
  NULLIDX,PILOTIDX,PILOTS) place les pilotes PILOTS (NPilot x NSym x
  NStreams) aux indices PILOTIDX. Les données occupent les indices
  restants, dans l'ordre croissant.

  Comme MATLAB, les indices vont de 1 à NFFT dans l'ordre des
  fréquences, de la plus négative à la plus positive : le continu est
  à l'indice NFFT/2+1 (NFFT pair) ou (NFFT+1)/2 (impair). Chaque symbole
  est l'IFFT de MATLAB du peigne remis dans l'ordre de la transformée
  (ifftshift), donc normalisée par 1/NFFT ; OFDMDEMOD en est l'inverse
  exact. L'option 'OversamplingFactor' n'est acceptée qu'à sa valeur un.

  Le préfixe cyclique change la convolution linéaire du canal en
  convolution circulaire, tant que la réponse du canal est plus courte
  que lui : chaque sous-porteuse ne voit plus qu'un gain complexe, que
  l'on divise.

  Exemple :
     % La numérologie d'IEEE 802.11a.
     nullidx = [1:6 33 60:64].'; pilotidx = [12 26 40 54].';
     x = qammod(randi([0 15], 48, 10), 16, 'UnitAveragePower', true);
     y = ofdmmod(x, 64, 16, nullidx, pilotidx, ones(4, 10));
     size(y)                     % 800 x 1 : dix symboles de 80 échantillons

  Voir aussi OFDMDEMOD, QAMMOD, IFFT.
```

## `pathLoss`

```
PATHLOSS Affaiblissement de parcours en décibels.
  L = PATHLOSS(D,F) applique le modèle en espace libre ; l'exposant
  permet de rendre compte d'un environnement plus difficile.

  L = PATHLOSS(D,F,N) rend 10 N log10(4 pi D / lambda) décibels.

  L'exposant vaut deux en espace libre : la puissance s'étale sur une
  sphère, et chaque doublement de distance coûte six décibels. En ville
  il monte à trois ou quatre — réflexions, diffractions, obstacles — et
  chaque doublement coûte alors neuf ou douze décibels.

  Monter en fréquence coûte aussi : à distance égale, doubler la
  fréquence coûte six décibels, parce qu'une antenne de gain donné y
  capte une surface plus petite.

  Exemple :
     pathLoss(1000, 2.4e9)           % environ 100 dB
     pathLoss(2000, 2.4e9) - pathLoss(1000, 2.4e9)   % 6 dB
     pathLoss(2000, 2.4e9, 4) - pathLoss(1000, 2.4e9, 4)   % 12 dB

  Voir aussi FRIIS, THROUGHPUTSHANNON, W2DBM.
```

## `rayleighChannel`

```
RAYLEIGHCHANNEL Canal à évanouissements de Rayleigh.
  [Y,H] = RAYLEIGHCHANNEL(X,NTRAJETS) fait passer le signal dans un
  canal à NTRAJETS trajets, et rend aussi la réponse impulsionnelle
  tirée. La puissance totale du canal est normalisée à un.

  Quand aucun trajet ne domine, la somme de nombreux trajets
  indépendants donne un gain complexe gaussien : c'est le canal de
  Rayleigh, dont l'amplitude suit la loi du même nom et la puissance
  une loi exponentielle.

  Les évanouissements profonds y sont fréquents : la puissance tombe
  sous un dixième de sa moyenne près d'une fois sur dix. C'est ce qui
  rend la diversité — plusieurs antennes, plusieurs fréquences,
  plusieurs instants — indispensable, bien plus que la puissance
  d'émission.

  Un seul trajet donne un canal plat ; plusieurs le rendent sélectif en
  fréquence, et c'est précisément ce que l'OFDM sait traiter porteuse
  par porteuse.

  Exemple :
     [~, h] = rayleighChannel(1, 8);
     max(abs(fft(h, 64))) / min(abs(fft(h, 64)))   % la selectivite

  Voir aussi OFDMMOD, PATHLOSS, EVM.
```

## `throughputShannon`

```
THROUGHPUTSHANNON Capacité de Shannon, en bits par seconde.
  DEBIT = THROUGHPUTSHANNON(LARGEURBANDE,SNRDB) rend B log2(1 + RSB).

  Elle borne tout : aucun codage, aussi ingénieux soit-il, ne peut faire
  passer plus de bits par seconde sur ce canal. C'est un théorème, non
  une limite technologique.

  Doubler la bande double la capacité ; doubler la puissance n'ajoute
  qu'un bit par hertz. C'est pourquoi les gains des dernières décennies
  sont venus de la bande et du nombre d'antennes, non de la puissance.

  À zéro décibel de rapport signal à bruit, la capacité vaut exactement
  un bit par seconde et par hertz. Elle reste positive à très bas RSB,
  mais devient négligeable.

  Exemple :
     throughputShannon(20e6, 20) / 1e6           % en Mbit/s
     throughputShannon(1, 33) - throughputShannon(1, 30)   % 1 bit/s/Hz

  Voir aussi PATHLOSS, EVM.
```

