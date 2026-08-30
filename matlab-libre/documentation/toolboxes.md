# Les toolboxes

Un dossier par toolbox, sous `toolbox/`. Chaque dossier porte un
`Contents.m` qui nomme la toolbox MathWorks correspondante et liste ses
fonctions. Tout est écrit dans le langage MATLAB lui-même : c'est lisible,
modifiable sans recompiler, et cela met l'interpréteur à l'épreuve.

Le nom du dossier est en français, comme le reste du dépôt ; le nom des
fonctions est celui de MathWorks, puisque c'est lui qu'un programme
existant appellera.

| Dossier | Toolbox | Fonctions |
|---|---|---|
| `acquisition` | Data Acquisition Toolbox — acquisition simulée. | 5 |
| `aerospatial` | Aerospace Toolbox — atmosphère, repères et grandeurs de vol. | 6 |
| `ajustement-courbes` | Curve Fitting Toolbox — ajustement de courbes et de surfaces. | 4 |
| `analyse-de-texte` | Text Analytics Toolbox — analyse de textes. | 8 |
| `antennes` | Antenna Toolbox — rayonnement et réseaux. | 5 |
| `apprentissage-profond` | Deep Learning Toolbox — réseaux de neurones, denses et convolutifs. | 27 |
| `audio` | Audio Toolbox — sons et descripteurs. | 7 |
| `automatique` | Control System Toolbox — systèmes asservis linéaires. | 108 |
| `base-de-donnees` | Database Toolbox — stockage tabulaire. | 8 |
| `bioinformatique` | Bioinformatics Toolbox — séquences biologiques. | 8 |
| `calcul-parallele` | Parallel Computing Toolbox — exécution parallèle. | 4 |
| `cartographie` | Mapping Toolbox — géodésie et cartographie. | 4 |
| `coder` | MATLAB Coder — génération de code C. | 4 |
| `communications` | Communications Toolbox — transmissions numériques. | 67 |
| `communications-sans-fil` | Wireless (5G / LTE / WLAN) — couche physique. | 6 |
| `compilateur` | MATLAB Compiler — distribution d'un programme. | 2 |
| `conduite-automatisee` | Automated Driving Toolbox — aide à la conduite. | 4 |
| `dsp` | DSP System Toolbox — traitement du signal en temps réel. | 6 |
| `econometrie` | Econometrics Toolbox — séries temporelles et économétrie. | 8 |
| `edp` | Partial Differential Equation Toolbox — équations aux dérivées partielles. | 5 |
| `finance` | Financial Toolbox — finance quantitative. | 16 |
| `flou` | Fuzzy Logic Toolbox — logique floue. | 42 |
| `fusion-capteurs` | Sensor Fusion and Tracking Toolbox — fusion de capteurs. | 4 |
| `gestion-risques` | Risk Management Toolbox — mesures de risque. | 5 |
| `identification` | System Identification Toolbox — identification de modèles. | 6 |
| `imagerie-medicale` | Medical Imaging Toolbox — imagerie médicale. | 5 |
| `images` | Image Processing Toolbox — traitement d'images. | 123 |
| `instruments` | Instrument Control Toolbox — pilotage d'instruments (simulé). | 4 |
| `instruments-financiers` | Financial Instruments Toolbox — instruments de taux. | 6 |
| `lidar` | Lidar Toolbox — nuages de points. | 4 |
| `maintenance-predictive` | Predictive Maintenance Toolbox — pronostic et santé des équipements. | 4 |
| `matlab` | MATLAB de base — fonctions écrites dans le langage lui-même. | 48 |
| `mpc` | Model Predictive Control Toolbox — commande prédictive. | 3 |
| `navigation` | Navigation Toolbox — localisation et planification. | 5 |
| `ondelettes` | Wavelet Toolbox — analyse en ondelettes. | 54 |
| `optimisation` | Optimization Toolbox — optimisation sous contraintes. | 12 |
| `optimisation-globale` | Global Optimization Toolbox — optimisation globale. | 9 |
| `radar` | Radar Toolbox — équation du radar et traitement d'impulsions. | 7 |
| `renforcement` | Reinforcement Learning Toolbox — apprentissage par renforcement. | 5 |
| `reseaux-antennes` | Phased Array System Toolbox — réseaux d'antennes. | 4 |
| `rf` | RF Toolbox — grandeurs de radiofréquence. | 7 |
| `robotique` | Robotics System Toolbox — cinématique et transformations. | 19 |
| `robuste` | Robust Control Toolbox — analyse de robustesse. | 9 |
| `signal` | Signal Processing Toolbox — traitement du signal. | 163 |
| `simscape` | Simscape — réseaux physiques. | 9 |
| `simulink` | Simulink — simulation de schémas-blocs. | 6 |
| `stateflow` | Stateflow — machines à états finis. | 4 |
| `statistiques` | Statistics and Machine Learning Toolbox — statistiques et apprentissage. | 127 |
| `symbolique` | Symbolic Math Toolbox — calcul formel. | 14 |
| `vehicule` | Vehicle Dynamics / Powertrain — dynamique du véhicule. | 4 |
| `vision` | Computer Vision Toolbox — vision par ordinateur. | 33 |

Les fonctions natives — 633, écrites en C++ — couvrent le MATLAB de base :
tableaux, mathématiques élémentaires, algèbre linéaire, Fourier, chaînes,
cellules et structures, entrées-sorties, graphique, temps, système. Elles
sont documentées dans [`reference.md`](reference.md), généré par
`outils/genererReference.m`.

## Comment lire une toolbox

Prenons `automatique/` (Control System Toolbox). Un modèle y est une
structure : `tf` porte `num`/`den`, `ss` porte `A`/`B`/`C`/`D`, et le champ
`Ts` vaut 0 pour un modèle continu.

```matlab
G = tf(1, [1 2 1]);          % 1/(s+1)^2
step(G);                     % réponse indicielle, tracée
[m, p] = bode(G, 1);         % module et phase à 1 rad/s
F = feedback(G, tf(1, 1));   % boucle fermée
K = place(A, B, [-2 -3]);    % placement de pôles
```

Les valeurs rendues sont celles de la théorie : `dcgain(G)` vaut 1,
`bode(G, 1)` rend 0,5 et -90 degrés, `place` place effectivement les pôles.
C'est ce que vérifie `tests/scripts/test_toolboxes.m`, qui contrôle au
moins un résultat exact par toolbox.

## Ce que couvre chaque module

Chaque `Contents.m` liste ses fonctions avec une ligne de description. Le
détail — signature, options, exemple — est dans le bloc d'aide de chaque
fichier, que `help nom` affiche et que la référence reprend.
