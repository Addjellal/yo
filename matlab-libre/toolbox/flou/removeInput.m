function fis = removeInput(fis, variable)
%REMOVEINPUT Retire une variable d'entrée d'un système flou.
%   FIS = REMOVEINPUT(FIS,NOM) retire l'entrée nommée NOM, ou de rang NOM
%   si l'on donne un nombre. La colonne correspondante disparaît de la
%   matrice des règles : celles qui la mentionnaient portent désormais
%   sur les autres variables.
%
%   Exemple :
%      fis = addInput(addInput(mamfis, [0 1], 'Name', 'a'), [0 1], 'Name', 'b');
%      fis = removeInput(fis, 'a');
%      fis.entrees{1}.nom             % 'b'
%
%   Voir aussi REMOVEOUTPUT, REMOVEMF, REMOVERULE, ADDINPUT, RMVAR.
    indice = rangDansGenre(fis, variable, true);
    fis = rmvar(fis, 'input', indice);
end
