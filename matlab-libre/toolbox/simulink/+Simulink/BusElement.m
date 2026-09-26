classdef BusElement
%BUSELEMENT Un élément d'un type de bus : son nom, ses dimensions, son type.
%   E = SIMULINK.BUSELEMENT crée un élément, que SIMULINK.BUS range dans
%   sa propriété Elements. Ses propriétés sont celles de Simulink :
%      Name            'a'        le nom de l'élément
%      Dimensions      1          un nombre, ou [lignes colonnes]
%      DataType        'double'   'Bus: Y' en fait un bus emboîté, de type Y
%      Complexity      'real'
%      DimensionsMode  'Fixed'
%      Min, Max        []         les bornes de ses valeurs
%      Unit            ''
%      Description     ''
%
%   Exemple :
%      e = Simulink.BusElement;
%      e.Name = 'vitesse';
%      e.Dimensions = 3;
%
%   Voir aussi SIMULINK.BUS, ADD_BLOCK.
    properties
        Name = 'a'
        Complexity = 'real'
        Dimensions = 1
        DimensionsMode = 'Fixed'
        DataType = 'double'
        Min = []
        Max = []
        Unit = ''
        Description = ''
    end
end
