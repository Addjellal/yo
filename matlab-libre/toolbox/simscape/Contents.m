% Simscape — réseaux physiques.
%
% Le solveur écrit les équations nodales du circuit — la loi des nœuds —
% par la méthode d'analyse nodale modifiée : les sources de tension et les
% bobines ajoutent chacune une inconnue de courant et une équation, ce que
% l'analyse nodale seule ne saurait traiter.
%
% Description
%   circuit            - Crée un circuit vide, le nœud 0 étant la masse
%   addComponent       - Forme générale dont dérivent les suivantes
%   addResistor        - Résistance
%   addCapacitor       - Condensateur
%   addInductor        - Bobine
%   addVoltageSource   - Source de tension idéale
%   addCurrentSource   - Source de courant idéale
%
% Résolution
%   solveDC            - Point de fonctionnement continu
%   solveTransient     - Réponse temporelle, par Euler implicite
