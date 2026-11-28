% Instrument Control Toolbox — pilotage d'instruments programmables.
%
% L'instrument est simulé — un multimètre et une alimentation qui suivent
% IEEE 488.2 et SCPI : formes courtes et longues des commandes, file
% d'erreurs lue par SYST:ERR?.
%
% Liaison
%   visadev    - Ouvre une liaison, une poignée, vers une adresse VISA
%
% Échange
%   writeline  - Envoie une commande SCPI
%   readline   - Lit la réponse qui attend, sous forme de chaîne
%   writeread  - Envoie et lit d'un coup : la forme à préférer
%   query      - La même chose, en caractères, comme les anciennes interfaces
