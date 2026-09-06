function variables = variablesDe(fis, entree)
%VARIABLESDE Liste des variables d'entrée ou de sortie d'un système flou.
%   VARIABLES = VARIABLESDE(FIS,ENTREE) rend la liste des variables
%   d'entrée du système flou si ENTREE est vrai, celle des variables de
%   sortie sinon.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Avec POSERVARIABLES, elle isole la disposition interne de la structure
%   FIS : le reste de la boîte à outils parcourt les variables sans savoir
%   qu'elles sont rangées dans deux champs distincts, et un changement de
%   représentation ne touche que ces deux fonctions.
%
%   Exemple :
%      fis = mamfis();
%      numel(variablesDe(fis, true))
%
%   Voir aussi POSERVARIABLES, ADDINPUT, ADDOUTPUT, EVALFIS.
    if entree
        variables = fis.entrees;
    else
        variables = fis.sorties;
    end
end
