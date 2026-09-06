function session = writeData(session, donnees)
%WRITEDATA Écrit un bloc sur les voies de sortie.
%   SESSION = WRITEDATA(SESSION,DONNEES) envoie un bloc d'échantillons.
%   Il n'y a pas de matériel ici : le bloc est mémorisé dans
%   SESSION.ECRIT, où les écritures successives s'accumulent comme sur
%   une file de sortie réelle.
%
%   Exemple :
%      s = writeData(s, linspace(0, 5, 500).');
%      s = writeData(s, linspace(5, 0, 500).');
%      numel(s.ecrit)                  % 1000
%
%   Voir aussi ADDANALOGOUTPUT, READDATA, DAQ.
    session.ecrit = [session.ecrit; donnees(:)];
end
