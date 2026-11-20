function reponse = writeread(v, commande)
%WRITEREAD Envoie une requête et lit sa réponse.
%   REPONSE = WRITEREAD(V,COMMANDE) enchaîne WRITELINE et READLINE, comme
%   dans MATLAB : c'est la forme à employer pour toute requête, elle ne
%   laisse pas de place à la confusion entre la réponse attendue et une
%   autre.
%
%   Exemple :
%      v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
%      identite = writeread(v, '*IDN?')
%      tension = str2double(writeread(v, 'MEASure:VOLTage:DC?'));
%
%   Voir aussi WRITELINE, READLINE, VISADEV.
    writeline(v, commande);
    reponse = readline(v);
end
