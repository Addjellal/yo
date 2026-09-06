function instrument = visadev(adresse)
%VISADEV Ouvre une liaison vers un instrument simulé.
%   INSTRUMENT = VISADEV(ADRESSE) ouvre une liaison vers l'instrument
%   désigné par une adresse VISA — 'TCPIP0::192.168.1.10::inst0::INSTR',
%   'USB0::0x1234::0x5678::INSTR', 'GPIB0::14::INSTR'.
%
%   L'objet rendu porte trois champs : ADRESSE, JOURNAL — la suite des
%   commandes envoyées — et DERNIEREREPONSE.
%
%   Il n'y a pas ici de vrai matériel : l'instrument est simulé, et
%   répond aux commandes SCPI les plus courantes. C'est assez pour écrire
%   et éprouver un programme de mesure, qui n'aura plus qu'à changer
%   d'adresse le jour où l'appareil est branché.
%
%   Le journal permet de rejouer une séance, ou de comprendre après coup
%   ce qu'on a demandé — ce qui est le premier réflexe quand un
%   instrument ne répond pas ce qu'on attend.
%
%   Exemple :
%      instrument = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
%      [identite, instrument] = query(instrument, '*IDN?');
%
%   Voir aussi WRITELINE, READLINE, QUERY.
    instrument = struct();
    instrument.adresse = adresse;
    instrument.journal = {};
    instrument.derniereReponse = '';
end
