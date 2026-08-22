% Parallel Computing Toolbox — exécution parallèle.
%
% MatLibre exécute « parfor » et « spmd » séquentiellement : le résultat
% est le même, seul le temps diffère. Les fonctions ci-dessous existent
% pour que le code écrit pour la toolbox tourne sans modification.
%
%   parpool, gcp, delete  - Pool de travailleurs (simulé)
%   parfeval, fetchOutputs- Exécution différée
%   distributed, gather   - Tableaux distribués (identité)
%   numlabs, labindex     - Identifiants de travailleur
%   pararrayfun           - arrayfun « parallèle »
