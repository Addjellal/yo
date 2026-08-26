% Simscape — réseaux physiques.
%
% Le solveur écrit les équations nodales du circuit (loi des nœuds), avec
% la méthode d'analyse nodale modifiée : les sources de tension et les
% inductances ajoutent une inconnue de courant.
%
%   circuit      - Crée un circuit vide
%   addResistor, addCapacitor, addInductor, addVoltageSource,
%   addCurrentSource - Ajout de composants entre deux nœuds
%   solveDC      - Point de fonctionnement continu
%   solveTransient - Réponse temporelle (Euler implicite)
