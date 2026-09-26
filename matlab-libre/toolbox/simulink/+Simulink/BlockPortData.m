classdef BlockPortData < handle
%BLOCKPORTDATA Un port d'une S-fonction de niveau 2.
%   Le bloc que reçoit une S-fonction de niveau 2 porte ses ports dans
%   block.InputPort(i) et block.OutputPort(j). Chacun a ces propriétés :
%      Dimensions         -1         un nombre, [lignes colonnes], ou -1 :
%                                    les dimensions du signal qu'il reçoit
%      DirectFeedthrough  false      l'entrée est-elle lue par Outputs ?
%      Data               []         la valeur du port, que la S-fonction
%                                    lit (entrée) ou pose (sortie)
%      DatatypeID         0          0 : double
%      Complexity         'Real'
%      SamplingMode       'Sample'
%      DimensionsMode     'Fixed'
%
%   Exemple :
%      p = Simulink.BlockPortData;
%      p.Dimensions = 3;
%      p.Data = [1; 2; 3];
%
%   Voir aussi SIMULINK.MSFCNRUNTIMEBLOCK.
    properties
        Dimensions = -1
        DirectFeedthrough = false
        Data = []
        DatatypeID = 0
        Complexity = 'Real'
        SamplingMode = 'Sample'
        DimensionsMode = 'Fixed'
    end
end
