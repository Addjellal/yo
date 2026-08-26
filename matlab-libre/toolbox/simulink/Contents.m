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
