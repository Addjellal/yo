function fis = removeOutput(fis, variable)
%REMOVEOUTPUT Retire une variable de sortie d'un système flou.
%   FIS = REMOVEOUTPUT(FIS,NOM) retire la sortie nommée NOM, ou de rang
%   NOM si l'on donne un nombre, et la colonne correspondante des règles.
%
%   Exemple :
%      fis = addOutput(mamfis, [0 1], 'Name', 'y');
%      fis = removeOutput(fis, 'y');
%      numel(fis.sorties)             % 0
%
%   Voir aussi REMOVEINPUT, REMOVEMF, REMOVERULE, ADDOUTPUT, RMVAR.
    indice = rangDansGenre(fis, variable, false);
    fis = rmvar(fis, 'output', indice);
end
