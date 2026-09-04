function [M, classes] = confusionmat(vrai, predit, varargin)
%CONFUSIONMAT Matrice de confusion.
%   M = CONFUSIONMAT(VRAI,PREDIT) compte, en M(i,j), les observations de
%   la classe i classées en j. La diagonale porte les bonnes réponses ;
%   chaque case hors diagonale dit quelle classe a été prise pour quelle
%   autre — ce que la seule justesse ne dit pas.
%
%   [M,CLASSES] = CONFUSIONMAT(...) rend aussi la liste des classes, dans
%   l'ordre des lignes et des colonnes.
%
%   CONFUSIONMAT(...,'Order',C) impose cet ordre, et permet de faire
%   figurer une classe qu'aucune observation ne porte.
%
%   Les étiquettes peuvent être des nombres, des chaînes rangées en
%   tableau de cellules, un tableau de caractères, ou un tableau
%   catégoriel.
%
%   Exemple :
%      confusionmat({'a','b','a'}, {'a','b','b'})      % [1 1; 0 1]
%
%   Voir aussi CONFUSIONCHART, CROSSTAB, ACCURACY.
    ordre = {};
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'order')
            ordre = varargin{k + 1};
        end
    end
    [indicesVrai, classes] = matlibre_etiquettes_communes(vrai, predit, ordre);
    [indicesPredit, ~] = matlibre_etiquettes_communes(predit, vrai, classes);
    k = numel(classes);
    M = zeros(k, k);
    for i = 1:numel(indicesVrai)
        if indicesVrai(i) > 0 && indicesPredit(i) > 0
            M(indicesVrai(i), indicesPredit(i)) = M(indicesVrai(i), indicesPredit(i)) + 1;
        end
    end
end
