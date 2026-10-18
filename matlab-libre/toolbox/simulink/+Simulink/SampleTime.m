classdef SampleTime
%SIMULINK.SAMPLETIME Une période d'échantillonnage d'un modèle compilé.
%   SIMULINK.BLOCKDIAGRAM.GETSAMPLETIMES(MODELE) en rend un tableau, une
%   par période du modèle : Value, [période décalage] ; Description,
%   'Discrete 1', 'Continuous', 'Fixed in Minor Step', 'Constant' ;
%   Annotation, D1, Cont, FiM, Inf, comme la légende des périodes de
%   Simulink ; OwnerBlock, vide pour une période du modèle.
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.GETSAMPLETIMES, GET_PARAM.
    properties
        Value = [0 0]
        Description = ''
        ColorRGBValue = []
        Annotation = ''
        OwnerBlock = ''
        ComponentSampleTimes = []
    end
    methods
        function obj = SampleTime(valeur, description, annotation)
            if nargin >= 1
                obj.Value = valeur;
            end
            if nargin >= 2
                obj.Description = description;
            end
            if nargin >= 3
                obj.Annotation = annotation;
            end
        end
    end
end
