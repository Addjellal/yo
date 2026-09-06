% Data Acquisition Toolbox — acquisition simulée.
%
% Aucune carte n'est pilotée : les voies d'entrée produisent des signaux
% calculés, ce qui permet d'écrire et d'éprouver une chaîne d'acquisition
% complète — cadence, repliement, moyennage — sans matériel.
%
% Session
%   daq              - Crée une session, à une fréquence donnée
%
% Voies
%   addAnalogInput   - Ajoute une entrée, décrite par son générateur
%   addAnalogOutput  - Ajoute une sortie
%
% Échanges
%   readData         - Lit un bloc sur toutes les entrées, aux mêmes instants
%   writeData        - Écrit un bloc sur les sorties
