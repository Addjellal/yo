# Toolbox `instruments`

```
% Instrument Control Toolbox — pilotage d'instruments (simulé).
%
%   visadev, fopen, fclose - Connexion à un instrument
%   writeline, readline    - Dialogue SCPI
%   query                  - Écriture puis lecture
%
% L'instrument simulé répond aux commandes SCPI usuelles (*IDN?,
% MEAS:VOLT?, MEAS:CURR?), ce qui suffit à mettre au point un script de
% banc avant de le brancher sur le vrai matériel.
```

## `query`

```
QUERY Envoie une commande puis lit la réponse.
```

## `readline`

```
READLINE Lit la dernière réponse de l'instrument.
```

## `visadev`

```
VISADEV Ouvre une liaison vers un instrument simulé.
```

## `writeline`

```
WRITELINE Envoie une commande SCPI et prépare la réponse.
```

