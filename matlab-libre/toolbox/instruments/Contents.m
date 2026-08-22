% Instrument Control Toolbox — pilotage d'instruments (simulé).
%
%   visadev, fopen, fclose - Connexion à un instrument
%   writeline, readline    - Dialogue SCPI
%   query                  - Écriture puis lecture
%
% L'instrument simulé répond aux commandes SCPI usuelles (*IDN?,
% MEAS:VOLT?, MEAS:CURR?), ce qui suffit à mettre au point un script de
% banc avant de le brancher sur le vrai matériel.
