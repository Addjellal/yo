function fis = poserVariables(fis, entree, variables)
%POSERVARIABLES Remplace la liste des entrées ou celle des sorties.
%   FIS = POSERVARIABLES(FIS,ENTREE,VARIABLES) remplace la liste des
%   variables d'entrée du système si ENTREE est vrai, celle des variables
%   de sortie sinon.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Elle existe en pendant de VARIABLESDE, pour que les fonctions qui
%   modifient une variable — ajouter une fonction d'appartenance, changer
%   une borne — n'aient pas à savoir dans quel champ de la structure les
%   entrées et les sorties sont rangées. Toute la connaissance de cette
%   disposition tient dans ces deux fonctions.
%
%   Exemple :
%      fis = mamfis();
%      fis = poserVariables(fis, true, {});
%
%   Voir aussi VARIABLESDE, ADDINPUT, ADDOUTPUT.
    if entree
        fis.entrees = variables;
    else
        fis.sorties = variables;
    end
end
