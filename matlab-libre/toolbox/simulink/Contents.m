% Simulink — simulation de schémas-blocs.
%
% Un modèle est une structure : une liste de blocs et une liste de liens.
% La simulation est à pas fixe et l'ordre d'exécution vient d'un tri
% topologique, si bien qu'une entrée est toujours calculée avant la sortie
% qui l'emploie. Les intégrateurs et les retards fournissent la mémoire,
% et cassent donc les boucles algébriques.
%
% Modèle
%   new_system  - Crée un modèle vide
%   add_block   - Ajoute un bloc, avec ses paramètres
%   add_line    - Relie une sortie à une entrée
%   set_param   - Change les paramètres d'un bloc
%
% Simulation
%   sim         - Simule à pas fixe ; rend temps et signaux
%   simplot     - Trace les signaux relevés
