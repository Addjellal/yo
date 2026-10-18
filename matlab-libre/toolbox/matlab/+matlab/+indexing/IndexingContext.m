classdef IndexingContext
%MATLAB.INDEXING.INDEXINGCONTEXT Le lieu d'une indexation.
%   Le troisième argument que reçoit la méthode numArgumentsFromSubscript
%   d'une classe qui surcharge SUBSREF : Statement pour une instruction
%   seule, Expression là où une liste de valeurs est attendue — les
%   éléments de « {o.a.b} », les arguments d'un appel —, Assignment pour
%   la cible d'une affectation.
%
%   Exemple :
%      c = matlab.indexing.IndexingContext.Expression;
%      c == matlab.indexing.IndexingContext.Expression   % vrai
%
%   Voir aussi SUBSREF, NUMEL.
    enumeration
        Statement
        Expression
        Assignment
    end
end
