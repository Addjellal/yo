# Toolbox `acquisition`

```
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
```

## `addAnalogInput`

```
ADDANALOGINPUT Ajoute une voie d'entrée.
  SESSION = ADDANALOGINPUT(SESSION,NOM,GENERATEUR) ajoute une voie.
  GENERATEUR est une poignée @(t) qui donne la tension à l'instant t ;
  par défaut, un sinus à cinquante hertz.

  Les voies se lisent ensemble et aux mêmes instants : c'est la
  simultanéité qui fait l'intérêt d'une carte multivoie, et elle permet
  de mesurer un déphasage — donc une puissance active — que deux
  acquisitions séparées ne donneraient pas.

  Le générateur peut porter du bruit : @(t) 2.5 + 0.1 * randn() simule
  une tension continue bruitée, sur laquelle on peut éprouver le gain
  d'un moyennage.

  Exemple :
     s = addAnalogInput(s, 'tension', @(t) 5 * sin(2*pi*50*t));
     s = addAnalogInput(s, 'courant', @(t) 0.4 * sin(2*pi*50*t - pi/6));

  Voir aussi DAQ, READDATA, ADDANALOGOUTPUT.
```

## `addAnalogOutput`

```
ADDANALOGOUTPUT Ajoute une voie de sortie.
  SESSION = ADDANALOGOUTPUT(SESSION,NOM) déclare une voie de sortie.
  Ce qu'on lui écrit par WRITEDATA est mémorisé dans SESSION.ECRIT, ce
  qui permet de vérifier qu'on a bien envoyé ce qu'on croyait.

  Exemple :
     s = addAnalogOutput(s, 'ao0');
     s = writeData(s, linspace(0, 5, 500).');
     numel(s.ecrit)                  % 500

  Voir aussi WRITEDATA, DAQ, ADDANALOGINPUT.
```

## `daq`

```
DAQ Crée une session d'acquisition simulée.
  SESSION = DAQ() crée une session à mille échantillons par seconde ;
  DAQ(FOURNISSEUR) nomme le fournisseur, sans autre effet ici.

  La session porte quatre champs : FOURNISSEUR, FREQUENCE — qu'on règle
  directement —, ENTREES et SORTIES, remplis par ADDANALOGINPUT et
  ADDANALOGOUTPUT.

  Aucune carte n'est pilotée : les voies d'entrée produisent des
  signaux calculés. C'est assez pour écrire et éprouver une chaîne
  d'acquisition complète — cadence, repliement, moyennage — sans
  matériel, et pour la brancher ensuite sans rien changer au programme.

  Exemple :
     s = daq();
     s.frequence = 10000;
     s = addAnalogInput(s, 'ai0', @(t) sin(2 * pi * 100 * t));
     [donnees, temps] = readData(s, 1000);

  Voir aussi ADDANALOGINPUT, ADDANALOGOUTPUT, READDATA, WRITEDATA.
```

## `readData`

```
READDATA Lit un bloc d'échantillons sur toutes les voies d'entrée.
  [DONNEES,TEMPS] = READDATA(SESSION,N) rend N échantillons : une ligne
  par instant, une colonne par voie, et le vecteur des instants.

  Le pas d'échantillonnage est l'inverse de la fréquence de la session :
  c'est la seule chose que la fréquence veut dire. N échantillons
  couvrent donc (N-1)/frequence secondes, non N/frequence — l'erreur
  d'un pas est la plus fréquente du domaine.

  Échantillonner à moins du double de la fréquence du signal ne le
  dégrade pas : il le remplace par un autre, de fréquence |f - k fe|.
  C'est le repliement, et aucun traitement postérieur ne le défait.

  Exemple :
     [donnees, temps] = readData(s, 1000);
     1 / diff(temps(1:2))            % la frequence d'echantillonnage

  Voir aussi DAQ, ADDANALOGINPUT, WRITEDATA.
```

## `writeData`

```
WRITEDATA Écrit un bloc sur les voies de sortie.
  SESSION = WRITEDATA(SESSION,DONNEES) envoie un bloc d'échantillons.
  Il n'y a pas de matériel ici : le bloc est mémorisé dans
  SESSION.ECRIT, où les écritures successives s'accumulent comme sur
  une file de sortie réelle.

  Exemple :
     s = writeData(s, linspace(0, 5, 500).');
     s = writeData(s, linspace(5, 0, 500).');
     numel(s.ecrit)                  % 1000

  Voir aussi ADDANALOGOUTPUT, READDATA, DAQ.
```

