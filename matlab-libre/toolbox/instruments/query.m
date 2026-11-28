function [reponse, v] = query(v, commande)
%QUERY Envoie une requête et lit sa réponse, en texte.
%   [REPONSE,V] = QUERY(V,COMMANDE) enchaîne WRITELINE et READLINE et rend
%   la réponse en tableau de caractères, comme le QUERY des anciennes
%   interfaces de MATLAB. WRITEREAD est la forme moderne. V, une poignée,
%   est rendu en second pour les programmes qui le reprenaient.
%
%   Exemple :
%      v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
%      identite = query(v, '*IDN?');
%      tension = str2double(query(v, 'MEAS:VOLT?'));
%
%   Voir aussi WRITEREAD, WRITELINE, READLINE, VISADEV.
    reponse = char(writeread(v, commande));
end
