function reponse = readline(v)
%READLINE Lit une réponse de l'instrument.
%   REPONSE = READLINE(V) lit la plus ancienne réponse que l'instrument V
%   (VISADEV) tient prête, sous forme de chaîne, comme MATLAB.
%
%   La réponse arrive toujours en texte, jamais en nombre : c'est la
%   source d'erreur la plus fréquente du pilotage d'instrument. Il faut
%   la convertir soi-même, par STR2DOUBLE ou SSCANF.
%
%   Si rien n'attend — la dernière commande réglait sans interroger, ou
%   l'instrument ne l'a pas comprise —, un vrai appareil laisse expirer
%   le délai : READLINE avertit et rend une chaîne vide, et l'instrument
%   range l'erreur -420 (« Query UNTERMINATED »). Il ne rend jamais une
%   réponse ancienne à la place de celle attendue.
%
%   Exemple :
%      v = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
%      writeline(v, 'MEAS:VOLT?');
%      tension = str2double(readline(v))
%
%   Voir aussi WRITELINE, WRITEREAD, VISADEV, STR2DOUBLE.
    if ~isa(v, 'visadev')
        error('instrument:readline:Objet', 'READLINE attend une liaison VISADEV.');
    end
    if isempty(v.reponses)
        warning('instrument:readline:Delai', ...
                ['Aucune réponse dans le délai (%g s) : la dernière commande n''interrogeait ' ...
                 'pas, ou l''instrument ne l''a pas comprise (SYST:ERR? le dit).'], v.Timeout);
        v.erreurs{end + 1} = '-420,"Query UNTERMINATED"';
        v.derniereReponse = '';
        reponse = "";
        return
    end
    texte = v.reponses{1};
    v.reponses(1) = [];
    v.derniereReponse = texte;
    reponse = string(texte);
end
