# Toolbox `instruments`

```
% Instrument Control Toolbox — pilotage d'instruments programmables.
%
% Liaison
%   visadev    - Ouvre une liaison vers un instrument, par adresse VISA
%
% Échange
%   writeline  - Envoie une commande SCPI
%   readline   - Lit la réponse, sous forme de texte
%   query      - Envoie et lit d'un coup : la forme à préférer
```

## `query`

```
QUERY Envoie une commande puis lit la réponse.
  [REPONSE,INSTRUMENT] = QUERY(INSTRUMENT,COMMANDE) enchaîne WRITELINE
  et READLINE. C'est la forme à employer pour toute commande qui
  interroge : elle ne laisse pas la place à la confusion entre la
  réponse attendue et la précédente.

  L'instrument est rendu en second : son journal a grandi, et il faut
  le reprendre pour que les appels suivants en tiennent compte.

  Exemple :
     [identite, instrument] = query(instrument, '*IDN?');
     [texte, instrument] = query(instrument, 'MEAS:VOLT?');
     tension = str2double(texte);

  Voir aussi WRITELINE, READLINE, VISADEV.
```

## `readline`

```
READLINE Lit la dernière réponse de l'instrument.
  REPONSE = READLINE(INSTRUMENT) rend, sous forme de texte, ce que la
  dernière commande a préparé.

  La réponse arrive toujours en texte, jamais en nombre : c'est la
  source d'erreur la plus fréquente du pilotage d'instrument. Il faut
  la convertir soi-même, par STR2DOUBLE ou SSCANF.

  Une commande de réglage — sans point d'interrogation — ne prépare
  rien : READLINE rendrait alors la réponse précédente. QUERY, qui
  enchaîne l'envoi et la lecture, évite cette confusion.

  Exemple :
     instrument = writeline(instrument, 'MEAS:VOLT?');
     tension = str2double(readline(instrument));

  Voir aussi WRITELINE, QUERY, VISADEV, STR2DOUBLE.
```

## `visadev`

```
VISADEV Ouvre une liaison vers un instrument simulé.
  INSTRUMENT = VISADEV(ADRESSE) ouvre une liaison vers l'instrument
  désigné par une adresse VISA — 'TCPIP0::192.168.1.10::inst0::INSTR',
  'USB0::0x1234::0x5678::INSTR', 'GPIB0::14::INSTR'.

  L'objet rendu porte trois champs : ADRESSE, JOURNAL — la suite des
  commandes envoyées — et DERNIEREREPONSE.

  Il n'y a pas ici de vrai matériel : l'instrument est simulé, et
  répond aux commandes SCPI les plus courantes. C'est assez pour écrire
  et éprouver un programme de mesure, qui n'aura plus qu'à changer
  d'adresse le jour où l'appareil est branché.

  Le journal permet de rejouer une séance, ou de comprendre après coup
  ce qu'on a demandé — ce qui est le premier réflexe quand un
  instrument ne répond pas ce qu'on attend.

  Exemple :
     instrument = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
     [identite, instrument] = query(instrument, '*IDN?');

  Voir aussi WRITELINE, READLINE, QUERY.
```

## `writeline`

```
WRITELINE Envoie une commande SCPI et prépare la réponse.
  INSTRUMENT = WRITELINE(INSTRUMENT,COMMANDE) envoie la commande, la
  consigne dans le journal, et prépare la réponse que READLINE lira.

  La norme SCPI donne aux commandes une forme hiérarchique : des mots
  séparés par des deux-points, un point d'interrogation pour interroger.
  Une commande sans point d'interrogation règle l'appareil et n'attend
  pas de réponse.

  Commandes reconnues par l'instrument simulé :
     *IDN?        l'identification, quatre champs séparés par des
                  virgules : fabricant, modèle, numéro de série, version
     *RST         remise à l'état initial
     MEAS:VOLT?   une tension, autour de 5 V, bruitée
     MEAS:CURR?   un courant, autour de 250 mA, bruité
     les autres   sont consignées et ne répondent rien

  Deux lectures successives diffèrent, comme sur un vrai appareil : un
  programme de mesure ne doit jamais supposer deux lectures identiques.

  Exemple :
     instrument = writeline(instrument, 'CONF:VOLT:DC 10');
     instrument = writeline(instrument, 'MEAS:VOLT?');
     tension = str2double(readline(instrument));

  Voir aussi READLINE, QUERY, VISADEV.
```

