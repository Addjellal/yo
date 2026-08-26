function instrument = writeline(instrument, commande)
%WRITELINE Envoie une commande SCPI et prépare la réponse.
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
