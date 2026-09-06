function [reponse, instrument] = query(instrument, commande)
%QUERY Envoie une commande puis lit la réponse.
%   [REPONSE,INSTRUMENT] = QUERY(INSTRUMENT,COMMANDE) enchaîne WRITELINE
%   et READLINE. C'est la forme à employer pour toute commande qui
%   interroge : elle ne laisse pas la place à la confusion entre la
%   réponse attendue et la précédente.
%
%   L'instrument est rendu en second : son journal a grandi, et il faut
%   le reprendre pour que les appels suivants en tiennent compte.
%
%   Exemple :
%      [identite, instrument] = query(instrument, '*IDN?');
%      [texte, instrument] = query(instrument, 'MEAS:VOLT?');
%      tension = str2double(texte);
%
%   Voir aussi WRITELINE, READLINE, VISADEV.
    instrument = writeline(instrument, commande);
    reponse = readline(instrument);
end
