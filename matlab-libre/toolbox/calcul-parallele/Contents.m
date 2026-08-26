% Parallel Computing Toolbox — exécution parallèle.
%
% « parfor » et « spmd » s'exécutent réellement en parallèle : chaque
% travailleur est un interpréteur complet, avec son propre espace de
% travail, et rien n'est partagé. Le résultat est celui de la boucle
% séquentielle ; le temps, lui, se divise par le nombre de cœurs.
%
% Pool
%   parpool     - Ouvre un pool de N travailleurs (natif)
%   gcp         - Pool courant, créé au besoin (natif)
%   delete      - Ferme le pool passé en argument (natif)
%
% Travaux asynchrones
%   parfeval      - Lance une fonction sur un travailleur (natif)
%   parfevalOnAll - La lance sur tous les travailleurs (natif)
%   fetchOutputs  - Récupère le résultat (natif)
%   wait, cancel  - Attend, annule (natif)
%
% Dans un bloc spmd
%   labindex, numlabs - Numéro du travailleur et taille du pool
%
% Tableaux
%   distributed, gather - Tableaux distribués (identité sur une machine)
%   pararrayfun         - arrayfun réparti sur le pool
%   parcellfun          - cellfun réparti sur le pool
