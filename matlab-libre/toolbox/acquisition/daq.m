classdef daq < handle
%DAQ Crée une session d'acquisition simulée.
%   SESSION = DAQ() crée une session à mille échantillons par seconde ;
%   DAQ(FOURNISSEUR) nomme le fournisseur, sans autre effet ici.
%
%   Comme dans MATLAB, la session est une poignée, et elle a une horloge :
%   deux lectures successives se suivent dans le temps, la seconde
%   commençant où la première s'est arrêtée — c'est une acquisition
%   continue, non deux fois le même bloc.
%
%   La session porte FOURNISSEUR, FREQUENCE (ou Rate, le nom de MATLAB),
%   qu'on règle directement, ENTREES et SORTIES, remplis par
%   ADDANALOGINPUT et ADDANALOGOUTPUT, ECRIT, ce qu'on a envoyé aux
%   sorties, et INSTANT, l'instant du prochain échantillon.
%
%   Aucune carte n'est pilotée : les voies d'entrée produisent des
%   signaux calculés. C'est assez pour écrire et éprouver une chaîne
%   d'acquisition complète — cadence, repliement, moyennage — sans
%   matériel.
%
%   Exemple :
%      s = daq();
%      s.frequence = 10000;
%      s = addAnalogInput(s, 'ai0', @(t) sin(2 * pi * 100 * t));
%      [donnees, temps] = readData(s, 1000);
%      [suite, temps2] = readData(s, 1000);
%      temps2(1)                       % 0.1 : la lecture continue
%
%   Voir aussi ADDANALOGINPUT, ADDANALOGOUTPUT, READDATA, WRITEDATA.
    properties
        fournisseur = 'simule';
        frequence = 1000;
        entrees = {};
        sorties = {};
        ecrit = [];
        instant = 0;
    end
    properties (Dependent)
        Rate
        Vendor
    end
    methods
        function s = daq(fournisseur)
            if nargin >= 1
                s.fournisseur = char(fournisseur);
            end
        end

        function f = get.Rate(s)
            f = s.frequence;
        end

        function set.Rate(s, f)
            s.frequence = f;
        end

        function v = get.Vendor(s)
            v = s.fournisseur;
        end
    end
end
