classdef CoderInfo
%CODERINFO Ce que la génération de code saurait d'une donnée.
%   C = SIMULINK.CODERINFO porte la classe de stockage d'un paramètre ou
%   d'un signal — StorageClass, 'Auto' par défaut —, son identifiant dans
%   le code et son alignement. MatLibre ne génère pas de code : ces
%   réglages se gardent, pour les modèles qui les posent, sans rien
%   changer à la simulation.
%
%   Exemple :
%      K = Simulink.Parameter(2);
%      K.CoderInfo.StorageClass           % 'Auto'
%
%   Voir aussi SIMULINK.PARAMETER, SIMULINK.SIGNAL.
    properties
        StorageClass = 'Auto'
        Identifier = ''
        Alignment = -1
    end
end
