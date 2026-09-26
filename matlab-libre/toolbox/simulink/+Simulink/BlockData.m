classdef BlockData < handle
%BLOCKDATA Une donnée d'une S-fonction de niveau 2.
%   Un paramètre du bloc (block.DialogPrm(i)), ses états continus
%   (block.ContStates) et leurs dérivées (block.Derivatives), un vecteur
%   de travail (block.Dwork(i)) : chacun porte sa valeur dans Data. Un
%   vecteur de travail a aussi un nom, des dimensions, et peut tenir un
%   état discret (UsedAsDiscState).
%
%   Exemple :
%      d = Simulink.BlockData;
%      d.Name = 'total';
%      d.Dimensions = 1;
%      d.Data = 0;
%
%   Voir aussi SIMULINK.MSFCNRUNTIMEBLOCK.
    properties
        Name = ''
        Data = []
        Dimensions = 1
        DatatypeID = 0
        Complexity = 'Real'
        UsedAsDiscState = false
    end
end
