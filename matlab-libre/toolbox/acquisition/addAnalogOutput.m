function session = addAnalogOutput(session, nom)
%ADDANALOGOUTPUT Ajoute une voie de sortie.
%   SESSION = ADDANALOGOUTPUT(SESSION,NOM) déclare une voie de sortie.
%   Ce qu'on lui écrit par WRITEDATA est mémorisé dans SESSION.ECRIT, ce
%   qui permet de vérifier qu'on a bien envoyé ce qu'on croyait.
%
%   Exemple :
%      s = addAnalogOutput(s, 'ao0');
%      s = writeData(s, linspace(0, 5, 500).');
%      numel(s.ecrit)                  % 500
%
%   Voir aussi WRITEDATA, DAQ, ADDANALOGINPUT.
    session.sorties{end+1} = struct('nom', nom);
end
