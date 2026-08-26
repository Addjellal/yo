# Toolbox `simulink`

```
% Simulink — simulation de schémas-blocs.
%
% Un modèle est une structure : une liste de blocs et une liste de liens.
% La simulation est à pas fixe, l'ordre d'exécution est déterminé par tri
% topologique des blocs sans état ; les intégrateurs et les retards
% fournissent la mémoire, ce qui casse les boucles algébriques.
%
%   new_system   - Modèle vide
%   add_block    - Ajout d'un bloc
%   add_line     - Connexion d'une sortie à une entrée
%   set_param    - Réglage d'un paramètre de bloc
%   sim          - Simulation
%   simplot      - Tracé des signaux relevés
%
% Blocs disponibles : constant, step, ramp, sine, gain, sum, product,
% integrator, derivative, transferfcn, statespace, saturation, delay,
% relay, abs, math, mux, scope, terminator.
```

## `add_block`

```
ADD_BLOCK Ajoute un bloc au modèle.
  MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...)

  Paramètres reconnus selon le type :
    constant     Value
    step         Time, Before, After
    ramp         Slope
    sine         Amplitude, Frequency, Phase
    gain         Gain
    sum          Signs (par exemple '+-')
    integrator   InitialCondition
    transferfcn  Numerator, Denominator
    statespace   A, B, C, D, X0
    saturation   UpperLimit, LowerLimit
    delay        InitialCondition
    relay        OnSwitch, OffSwitch, OnOutput, OffOutput
```

## `add_line`

```
ADD_LINE Relie la sortie d'un bloc à l'entrée d'un autre.
  MODELE = ADD_LINE(MODELE,'source','destination') ou
  ADD_LINE(MODELE,'source','destination',NUMERO) pour choisir l'entrée.
```

## `new_system`

```
NEW_SYSTEM Crée un modèle Simulink vide.
```

## `set_param`

```
SET_PARAM Modifie les paramètres d'un bloc.
```

## `sim`

```
SIM Simule un modèle à pas fixe.
  RESULTAT = SIM(MODELE,TFINAL,PAS) rend une structure contenant le
  vecteur des instants et, pour chaque bloc, le signal relevé à sa
  sortie.

  L'intégration se fait par la méthode d'Euler explicite ; les blocs
  sans état sont évalués dans l'ordre d'un tri topologique, ce qui
  garantit qu'une entrée est calculée avant la sortie qui l'utilise.
  Les intégrateurs et les retards fournissent la mémoire, et cassent
  donc les boucles algébriques.

  Tous les paramètres sont résolus avant la boucle : à l'intérieur, il
  ne reste que de l'arithmétique.
```

## `simplot`

```
SIMPLOT Trace les signaux relevés par SIM.
```

