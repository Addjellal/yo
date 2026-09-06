function instrument = writeline(instrument, commande)
%WRITELINE Envoie une commande SCPI et prépare la réponse.
%   INSTRUMENT = WRITELINE(INSTRUMENT,COMMANDE) envoie la commande, la
%   consigne dans le journal, et prépare la réponse que READLINE lira.
%
%   La norme SCPI donne aux commandes une forme hiérarchique : des mots
%   séparés par des deux-points, un point d'interrogation pour interroger.
%   Une commande sans point d'interrogation règle l'appareil et n'attend
%   pas de réponse.
%
%   Commandes reconnues par l'instrument simulé :
%      *IDN?        l'identification, quatre champs séparés par des
%                   virgules : fabricant, modèle, numéro de série, version
%      *RST         remise à l'état initial
%      MEAS:VOLT?   une tension, autour de 5 V, bruitée
%      MEAS:CURR?   un courant, autour de 250 mA, bruité
%      les autres   sont consignées et ne répondent rien
%
%   Deux lectures successives diffèrent, comme sur un vrai appareil : un
%   programme de mesure ne doit jamais supposer deux lectures identiques.
%
%   Exemple :
%      instrument = writeline(instrument, 'CONF:VOLT:DC 10');
%      instrument = writeline(instrument, 'MEAS:VOLT?');
%      tension = str2double(readline(instrument));
%
%   Voir aussi READLINE, QUERY, VISADEV.
    instrument.journal{end+1} = commande;
    c = upper(strtrim(char(commande)));
    if strcmp(c, '*IDN?')
        instrument.derniereReponse = 'MatLibre,Instrument simule,0,1.0';
    elseif strcmp(c, 'MEAS:VOLT?')
        instrument.derniereReponse = sprintf('%.6f', 5 + 0.01 * randn());
    elseif strcmp(c, 'MEAS:CURR?')
        instrument.derniereReponse = sprintf('%.6f', 0.25 + 0.001 * randn());
    elseif strcmp(c, '*OPC?')
        instrument.derniereReponse = '1';
    else
        instrument.derniereReponse = '';
    end
end
