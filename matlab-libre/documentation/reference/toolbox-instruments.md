# Toolbox `instruments`

```
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
```

## `matlibre_scpi`

```
MATLIBRE_SCPI Fait exécuter une commande SCPI par l'instrument simulé.
  MATLIBRE_SCPI(V,COMMANDE) interprète COMMANDE comme le ferait un
  multimètre doublé d'une alimentation : une requête (terminée par « ? »)
  range sa réponse dans la file de sortie de V, une commande de réglage
  change l'état, et une commande inconnue range l'erreur -113 dans la
  file d'erreurs. Les en-têtes suivent SCPI-99 : forme courte (les
  majuscules du mot-clé) ou longue, sans égard à la casse, nœuds entre
  crochets facultatifs. Plusieurs commandes se séparent par « ; ».

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi VISADEV, WRITELINE.
```

## `query`

```
QUERY Envoie une requête et lit sa réponse, en texte.
  [REPONSE,V] = QUERY(V,COMMANDE) enchaîne WRITELINE et READLINE et rend
  la réponse en tableau de caractères, comme le QUERY des anciennes
  interfaces de MATLAB. WRITEREAD est la forme moderne. V, une poignée,
  est rendu en second pour les programmes qui le reprenaient.

  Exemple :
     v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
     identite = query(v, '*IDN?');
     tension = str2double(query(v, 'MEAS:VOLT?'));

  Voir aussi WRITEREAD, WRITELINE, READLINE, VISADEV.
```

## `readline`

```
READLINE Lit une réponse de l'instrument.
  REPONSE = READLINE(V) lit la plus ancienne réponse que l'instrument V
  (VISADEV) tient prête, sous forme de chaîne, comme MATLAB.

  La réponse arrive toujours en texte, jamais en nombre : c'est la
  source d'erreur la plus fréquente du pilotage d'instrument. Il faut
  la convertir soi-même, par STR2DOUBLE ou SSCANF.

  Si rien n'attend — la dernière commande réglait sans interroger, ou
  l'instrument ne l'a pas comprise —, un vrai appareil laisse expirer
  le délai : READLINE avertit et rend une chaîne vide, et l'instrument
  range l'erreur -420 (« Query UNTERMINATED »). Il ne rend jamais une
  réponse ancienne à la place de celle attendue.

  Exemple :
     v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
     writeline(v, 'MEAS:VOLT?');
     tension = str2double(readline(v))

  Voir aussi WRITELINE, WRITEREAD, VISADEV, STR2DOUBLE.
```

## `visadev`

```
VISADEV Liaison VISA vers un instrument simulé.
  V = VISADEV(ADRESSE) ouvre une liaison vers l'instrument désigné par
  une adresse VISA — 'TCPIP0::192.168.1.10::inst0::INSTR',
  'USB0::0x1234::0x5678::INSTR', 'GPIB0::14::INSTR'.

  Comme dans MATLAB, V est une poignée : WRITELINE(V,COMMANDE) puis
  READLINE(V) lit la réponse, sans qu'il faille reprendre V. WRITEREAD
  enchaîne les deux.

  Il n'y a pas ici de vrai matériel : l'instrument est un multimètre et
  une alimentation simulés, qui suivent IEEE 488.2 et SCPI. Les
  commandes s'écrivent en forme courte ou longue, en majuscules ou non
  (MEAS:VOLT? ou measure:voltage:dc?) ; une commande inconnue va dans la
  file d'erreurs (-113, « Undefined header »), que SYST:ERR? lit, et ne
  prépare aucune réponse. L'instrument répond à *IDN?, *RST, *CLS,
  *OPC?, *ESR?, *TST?, SYST:ERR?, MEAS:VOLT[:DC]?, MEAS:CURR[:DC]?,
  VOLT, VOLT?, CURR, CURR?, CONF:VOLT[:DC], CONF:CURR[:DC], TRIG:SOUR et
  OUTP.

  Propriétés : ResourceName (ou adresse), Timeout, journal (les
  commandes envoyées, dans l'ordre) et derniereReponse.

  Exemple :
     v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
     writeline(v, '*IDN?');
     identite = readline(v)
     tension = str2double(writeread(v, 'MEASure:VOLTage:DC?'));

  Voir aussi WRITELINE, READLINE, WRITEREAD, QUERY.
```

## `writeline`

```
WRITELINE Envoie une commande à l'instrument.
  WRITELINE(V,COMMANDE) envoie COMMANDE, une ligne de texte SCPI, à
  l'instrument V (VISADEV). Comme dans MATLAB, V est une poignée : la
  réponse d'une requête attend dans l'instrument, et READLINE(V) la lit
  ensuite. V = WRITELINE(V,COMMANDE) rend la même poignée, pour les
  programmes écrits quand l'instrument était une valeur.

  Une commande de réglage — sans point d'interrogation — ne prépare
  aucune réponse ; une commande que l'instrument ne connaît pas non
  plus : elle range l'erreur -113 dans sa file, que SYST:ERR? lit.

  Exemple :
     v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
     writeline(v, 'VOLT 3.3');
     writeline(v, 'VOLT?');
     str2double(readline(v))         % 3.3

  Voir aussi READLINE, WRITEREAD, VISADEV.
```

## `writeread`

```
WRITEREAD Envoie une requête et lit sa réponse.
  REPONSE = WRITEREAD(V,COMMANDE) enchaîne WRITELINE et READLINE, comme
  dans MATLAB : c'est la forme à employer pour toute requête, elle ne
  laisse pas de place à la confusion entre la réponse attendue et une
  autre.

  Exemple :
     v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
     identite = writeread(v, '*IDN?')
     tension = str2double(writeread(v, 'MEASure:VOLTage:DC?'));

  Voir aussi WRITELINE, READLINE, VISADEV.
```

