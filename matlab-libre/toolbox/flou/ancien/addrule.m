function fis = addrule(fis, regles)
%ADDRULE Ajoute des règles.
%   Chaque ligne vaut [mfEntree1 ... mfEntreeN mfSortie poids operateur],
%   où l'opérateur vaut 1 pour « et », 2 pour « ou », comme dans la
%   documentation MathWorks.
%
%   C'est la forme d'avant R2018b, que MATLAB déconseille désormais au
%   profit d'addRule, qui lit aussi les règles écrites en clair. Les deux
%   noms ne diffèrent que par la casse, et Windows comme macOS ne savent
%   pas loger les deux fichiers dans un même dossier : celui-ci vit dans
%   flou/ancien, que le chemin de recherche emporte avec flou.
%
%   Exemple :
%      fis = mamfis('Name', 'pilote');
%      fis = addInput(fis, [0 10], 'Name', 'erreur');
%      fis = addMF(fis, 'erreur', 'trimf', [0 0 5], 'Name', 'petite');
%      fis = addMF(fis, 'erreur', 'trimf', [5 10 10], 'Name', 'grande');
%      fis = addOutput(fis, [0 1], 'Name', 'commande');
%      fis = addMF(fis, 'commande', 'trimf', [0 0 0.5], 'Name', 'faible');
%      fis = addMF(fis, 'commande', 'trimf', [0.5 1 1], 'Name', 'forte');
%      fis = addrule(fis, [1 1 1 1; 2 2 1 1]);
%      size(fis.regles, 1)         % 2
%
%   Voir aussi ADDMF, ADDINPUT, ADDOUTPUT, SHOWRULE.
    if isempty(fis.regles)
        fis.regles = regles;
    else
        fis.regles = [fis.regles; regles];
    end
end
