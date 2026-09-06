# Toolbox `communications-sans-fil`

```
% WLAN / LTE Toolbox — communications sans fil.
%
% Propagation
%   pathLoss          - Affaiblissement de parcours, exposant réglable
%   rayleighChannel   - Canal à évanouissements, plat ou sélectif
%
% Modulation multiporteuse
%   ofdmMod           - Modulation OFDM, avec préfixe cyclique
%   ofdmDemod         - Démodulation
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
     evm(reference, reference)       % 0
     evm(reference + 0.1 * bruit, reference)

  Voir aussi OFDMMOD, OFDMDEMOD.
```

## `ofdmDemod`

```
OFDMDEMOD Démodulation OFDM.
  SYMBOLES = OFDMDEMOD(SIGNAL,NFFT,PREFIXE,NPORTEUSES) retire le préfixe
  cyclique de chaque symbole, applique la transformée de Fourier et rend
  les NPORTEUSES premières sous-porteuses.

  Sans canal, la démodulation rend exactement les symboles modulés :
  c'est la première vérification à faire, et elle prend une ligne.

  Avec un canal, il reste à égaliser : diviser chaque porteuse par la
  réponse du canal à sa fréquence. Un seul coefficient complexe par
  porteuse suffit, ce qui est tout l'intérêt de l'OFDM face à un
  égaliseur temporel.

  Un préfixe plus court que la réponse du canal laisse passer
  l'interférence entre symboles, que plus aucune égalisation ne défait :
  c'est la limite que le dimensionnement doit respecter.

  Exemple :
     recus = ofdmDemod(signal, 64, 16, 48);
     H = fft(canal, 64);
     egalises = recus ./ H(1:48);

  Voir aussi OFDMMOD, EVM.
```

## `ofdmMod`

```
OFDMMOD Modulation OFDM avec préfixe cyclique.
  SIGNAL = OFDMMOD(SYMBOLES,NFFT,PREFIXE) où SYMBOLES est une matrice
  dont chaque colonne est un symbole OFDM. PREFIXE vaut NFFT/8 par
  défaut.

  L'OFDM répond au multitrajet en découpant la bande en sous-porteuses
  assez étroites pour que chacune voie un canal plat. Chaque colonne de
  symboles devient un symbole temporel par transformée de Fourier
  inverse, précédé de sa propre fin — le préfixe cyclique.

  Ce préfixe est ce qui fait tout marcher : tant qu'il est plus long que
  la réponse du canal, la convolution linéaire du canal devient une
  convolution circulaire, donc une simple multiplication porteuse par
  porteuse en fréquence. Un seul coefficient par porteuse suffit alors à
  annuler le canal.

  Il rend aussi chaque symbole indépendant du précédent : le transitoire
  du canal est contenu dans les premiers échantillons du préfixe, qui
  sont jetés. Même le premier symbole est correct, sans rien avant lui.

  Le coût est le débit : le préfixe n'apporte aucune information.

  Exemple :
     symboles = exp(1i * (pi/4 + randi([0 3], 48, 20) * pi/2));
     signal = ofdmMod(symboles, 64, 16);
     numel(signal)                   % 20 * (64 + 16)

  Voir aussi OFDMDEMOD, EVM, RAYLEIGHCHANNEL.
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

