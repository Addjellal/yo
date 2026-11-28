classdef visadev < handle
%VISADEV Liaison VISA vers un instrument simulé.
%   V = VISADEV(ADRESSE) ouvre une liaison vers l'instrument désigné par
%   une adresse VISA — 'TCPIP0::192.168.1.10::inst0::INSTR',
%   'USB0::0x1234::0x5678::INSTR', 'GPIB0::14::INSTR'.
%
%   Comme dans MATLAB, V est une poignée : WRITELINE(V,COMMANDE) puis
%   READLINE(V) lit la réponse, sans qu'il faille reprendre V. WRITEREAD
%   enchaîne les deux.
%
%   Il n'y a pas ici de vrai matériel : l'instrument est un multimètre et
%   une alimentation simulés, qui suivent IEEE 488.2 et SCPI. Les
%   commandes s'écrivent en forme courte ou longue, en majuscules ou non
%   (MEAS:VOLT? ou measure:voltage:dc?) ; une commande inconnue va dans la
%   file d'erreurs (-113, « Undefined header »), que SYST:ERR? lit, et ne
%   prépare aucune réponse. L'instrument répond à *IDN?, *RST, *CLS,
%   *OPC?, *ESR?, *TST?, SYST:ERR?, MEAS:VOLT[:DC]?, MEAS:CURR[:DC]?,
%   VOLT, VOLT?, CURR, CURR?, CONF:VOLT[:DC], CONF:CURR[:DC], TRIG:SOUR et
%   OUTP.
%
%   Propriétés : ResourceName (ou adresse), Timeout, journal (les
%   commandes envoyées, dans l'ordre) et derniereReponse.
%
%   Exemple :
%      v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
%      writeline(v, '*IDN?');
%      identite = readline(v)
%      tension = str2double(writeread(v, 'MEASure:VOLTage:DC?'));
%
%   Voir aussi WRITELINE, READLINE, WRITEREAD, QUERY.
    properties
        Timeout = 10;
    end
    properties (SetAccess = private)
        ResourceName = '';
    end
    properties
        journal = {};
        derniereReponse = '';
    end
    properties (Dependent)
        adresse
    end
    properties (Hidden)
        reponses = {};
        erreurs = {};
        etat = struct('tension', 0, 'courant', 0.1, 'sortie', false);
    end
    methods
        function v = visadev(adresse)
            if nargin < 1
                error('instrument:visadev:Adresse', 'VISADEV requires a VISA resource name.');
            end
            v.ResourceName = char(adresse);
        end

        function a = get.adresse(v)
            a = v.ResourceName;
        end
    end
end
