function reponse = readline(instrument)
%READLINE Lit la dernière réponse de l'instrument.
%   REPONSE = READLINE(INSTRUMENT) rend, sous forme de texte, ce que la
%   dernière commande a préparé.
%
%   La réponse arrive toujours en texte, jamais en nombre : c'est la
%   source d'erreur la plus fréquente du pilotage d'instrument. Il faut
%   la convertir soi-même, par STR2DOUBLE ou SSCANF.
%
%   Une commande de réglage — sans point d'interrogation — ne prépare
%   rien : READLINE rendrait alors la réponse précédente. QUERY, qui
%   enchaîne l'envoi et la lecture, évite cette confusion.
%
%   Exemple :
%      instrument = writeline(instrument, 'MEAS:VOLT?');
%      tension = str2double(readline(instrument));
%
%   Voir aussi WRITELINE, QUERY, VISADEV, STR2DOUBLE.
    reponse = instrument.derniereReponse;
end
