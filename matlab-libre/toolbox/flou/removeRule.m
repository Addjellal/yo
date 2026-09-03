function fis = removeRule(fis, indices)
%REMOVERULE Retire des règles d'un système flou.
%   FIS = REMOVERULE(FIS,I) retire les règles de rangs I, qui peut être
%   un vecteur. Les autres gardent leur ordre.
%
%   Exemple :
%      fis = addInput(mamfis, [0 1], 'Name', 'a', 'NumMFs', 2);
%      fis = addOutput(fis, [0 1], 'Name', 'b', 'NumMFs', 2);
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      fis = removeRule(fis, 1);
%      size(fis.regles, 1)            % 1
%
%   Voir aussi ADDRULE, SHOWRULE, REMOVEMF, REMOVEINPUT.
    if isempty(fis.regles)
        error('fuzzy:removeRule:Aucune', 'Le système n''a aucune règle.');
    end
    indices = round(double(indices(:)))';
    nombre = size(fis.regles, 1);
    if any(indices < 1) || any(indices > nombre)
        error('fuzzy:removeRule:Rang', ...
              'Le système n''a que %d règles.', nombre);
    end
    garder = true(1, nombre);
    garder(indices) = false;
    fis.regles = fis.regles(garder, :);
end
