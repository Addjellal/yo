function session = daq(fournisseur)
%DAQ Crée une session d'acquisition simulée.
%   SESSION = DAQ() crée une session à mille échantillons par seconde ;
%   DAQ(FOURNISSEUR) nomme le fournisseur, sans autre effet ici.
%
%   La session porte quatre champs : FOURNISSEUR, FREQUENCE — qu'on règle
%   directement —, ENTREES et SORTIES, remplis par ADDANALOGINPUT et
%   ADDANALOGOUTPUT.
%
%   Aucune carte n'est pilotée : les voies d'entrée produisent des
%   signaux calculés. C'est assez pour écrire et éprouver une chaîne
%   d'acquisition complète — cadence, repliement, moyennage — sans
%   matériel, et pour la brancher ensuite sans rien changer au programme.
%
%   Exemple :
%      s = daq();
%      s.frequence = 10000;
%      s = addAnalogInput(s, 'ai0', @(t) sin(2 * pi * 100 * t));
%      [donnees, temps] = readData(s, 1000);
%
%   Voir aussi ADDANALOGINPUT, ADDANALOGOUTPUT, READDATA, WRITEDATA.
    if nargin < 1
        fournisseur = 'simule';
    end
    session = struct();
    session.fournisseur = fournisseur;
    session.frequence = 1000;
    session.entrees = {};
    session.sorties = {};
    session.ecrit = [];
end
