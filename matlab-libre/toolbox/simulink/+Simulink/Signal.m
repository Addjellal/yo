classdef Signal < handle
%SIGNAL Un signal nommé : son type, ses dimensions, sa valeur initiale.
%   S = SIMULINK.SIGNAL crée un objet signal. Rangé dans l'espace de
%   travail de base sous un nom — A —, il définit la mémoire partagée
%   globale de ce nom : les blocs Data Store Read et Data Store Write qui
%   désignent A la lisent et l'écrivent sans qu'un bloc Data Store Memory
%   soit posé, où qu'ils soient dans le modèle. Ses propriétés :
%      InitialValue   l'expression de la valeur initiale, '' pour 0
%      Dimensions     -1 (celles de la valeur initiale), ou un nombre, ou
%                     [lignes colonnes] : la valeur initiale scalaire y
%                     est étendue
%      DataType       'auto', ou un type numérique : la valeur initiale y
%                     est convertie
%      Min, Max, Unit, Description, SampleTime (-1), Complexity
%                     ('auto'), DimensionsMode ('auto'), CoderInfo
%   Un Data Store Memory du même nom, visible depuis le bloc, l'emporte
%   sur l'objet.
%
%   C'est un objet poignée : T = COPY(S) en fait un autre.
%
%   Exemple :
%      A = Simulink.Signal;
%      A.InitialValue = '5';
%      A.Dimensions = 1;
%      A.DataType                         % 'auto'
%
%   Voir aussi SIMULINK.PARAMETER, ADD_BLOCK, SIM.
    properties
        CoderInfo = []
        Description = ''
        DataType = 'auto'
        Min = []
        Max = []
        Unit = ''
        Dimensions = -1
        DimensionsMode = 'auto'
        Complexity = 'auto'
        SampleTime = -1
        InitialValue = ''
    end
    methods
        function obj = Signal()
            obj.CoderInfo = Simulink.CoderInfo;
        end
        function set.DataType(obj, t)
            if isstring(t) && isscalar(t)
                t = char(t);
            end
            if ~ischar(t) || ~(any(strcmp(strtrim(t), matlibre_sl_parametre('types'))) || ...
                               ~isempty(regexp(strtrim(t), '^(Bus|Enum):\s*[A-Za-z]\w*$', 'once')))
                error('Simulink:Data:InvalidDataType', ...
                      ['Le DataType d''un Simulink.Signal est ''auto'', un type ' ...
                       'numerique (''double'', ''int8''…), ''boolean'', ''Bus: X'' ou ' ...
                       '''Enum: X''.']);
            end
            obj.DataType = strtrim(t);
        end
        function set.Dimensions(obj, d)
            if ~(isnumeric(d) && isreal(d) && ~isempty(d) && numel(d) <= 2 && ...
                 all(d == round(d)) && (isequal(d, -1) || all(d >= 1)))
                error('Simulink:Data:InvalidDimensions', ...
                      ['Les Dimensions d''un Simulink.Signal valent -1 (heritees), un ' ...
                       'nombre d''elements, ou [lignes colonnes].']);
            end
            obj.Dimensions = double(d);
        end
        function set.InitialValue(obj, v)
            if isnumeric(v) || islogical(v)
                v = mat2str(double(v));
            end
            obj.InitialValue = matlibre_sl_parametre('texte', v, 'InitialValue');
        end
        function set.Complexity(obj, c)
            obj.Complexity = matlibre_sl_parametre('choix', c, 'Complexity', ...
                                                   {'auto', 'real', 'complex'});
        end
        function set.DimensionsMode(obj, m)
            obj.DimensionsMode = matlibre_sl_parametre('choix', m, 'DimensionsMode', ...
                                                       {'auto', 'Fixed', 'Variable'});
        end
        function set.SampleTime(obj, t)
            if ~(isnumeric(t) && isreal(t) && ~isempty(t) && numel(t) <= 2)
                error('Simulink:Data:InvalidSampleTime', ...
                      ['Le SampleTime d''un Simulink.Signal vaut -1 (herite), une ' ...
                       'periode, ou [periode decalage].']);
            end
            obj.SampleTime = double(t);
        end
        function set.Min(obj, v)
            obj.Min = matlibre_sl_parametre('borne', v, 'Min');
        end
        function set.Max(obj, v)
            obj.Max = matlibre_sl_parametre('borne', v, 'Max');
        end
        function set.Unit(obj, u)
            obj.Unit = matlibre_sl_parametre('texte', u, 'Unit');
        end
        function set.Description(obj, d)
            obj.Description = matlibre_sl_parametre('texte', d, 'Description');
        end
        function c = copy(obj)
            c = Simulink.Signal;
            for nom = {'CoderInfo', 'Description', 'DataType', 'Min', 'Max', 'Unit', ...
                       'Dimensions', 'DimensionsMode', 'Complexity', 'SampleTime', ...
                       'InitialValue'}
                c.(nom{1}) = obj.(nom{1});
            end
        end
        function disp(obj)
            matlibre_sl_proprietes(obj, {'CoderInfo', 'Description', 'DataType', 'Min', ...
                                         'Max', 'Unit', 'Dimensions', 'DimensionsMode', ...
                                         'Complexity', 'SampleTime', 'InitialValue'});
        end
    end
end
