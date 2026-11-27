function varargout = writeline(v, commande)
%WRITELINE Envoie une commande à l'instrument.
%   WRITELINE(V,COMMANDE) envoie COMMANDE, une ligne de texte SCPI, à
%   l'instrument V (VISADEV). Comme dans MATLAB, V est une poignée : la
%   réponse d'une requête attend dans l'instrument, et READLINE(V) la lit
%   ensuite. V = WRITELINE(V,COMMANDE) rend la même poignée, pour les
%   programmes écrits quand l'instrument était une valeur.
%
%   Une commande de réglage — sans point d'interrogation — ne prépare
%   aucune réponse ; une commande que l'instrument ne connaît pas non
%   plus : elle range l'erreur -113 dans sa file, que SYST:ERR? lit.
%
%   Exemple :
%      v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
%      writeline(v, 'VOLT 3.3');
%      writeline(v, 'VOLT?');
%      str2double(readline(v))         % 3.3
%
%   Voir aussi READLINE, WRITEREAD, VISADEV.
    if ~isa(v, 'visadev')
        error('instrument:writeline:Objet', 'WRITELINE requires a VISADEV connection.');
    end
    v.journal{end + 1} = char(commande);
    matlibre_scpi(v, commande);
    if nargout > 0
        varargout{1} = v;
    end
end
