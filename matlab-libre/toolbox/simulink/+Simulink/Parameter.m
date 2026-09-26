classdef Parameter < handle
%PARAMETER Un paramètre de modèle : une valeur, son type et ses bornes.
%   P = SIMULINK.PARAMETER crée un paramètre sans valeur ;
%   P = SIMULINK.PARAMETER(V) lui donne la valeur V.
%
%   Rangé dans l'espace de travail de base sous un nom — K —, il se lit
%   dans les paramètres des blocs comme une variable : un gain réglé sur
%   'K', ou sur '2*K', prend la valeur de K au moment où l'on simule.
%   Ce qu'il ajoute à une simple variable :
%      DataType   'auto' (le type de la valeur), ou 'double', 'single',
%                 'int8' … 'uint32', 'int64', 'uint64', 'boolean' : la
%                 valeur est convertie dans ce type avant d'être lue — une
%                 constante réglée sur K sort alors un signal de ce type.
%                 'Bus: X' et 'Enum: X' laissent la valeur telle quelle ;
%                 les types à virgule fixe (fixdt) sont refusés, MatLibre
%                 ne les ayant pas.
%      Min, Max   les bornes de la valeur, vides par défaut : une valeur
%                 qui en sort arrête la compilation par une erreur
%                 Simulink:Data:ParameterOutOfRange qui nomme le bloc.
%      Unit, Description   du texte, pour le lecteur.
%   Dimensions et Complexity se lisent sur la valeur.
%
%   C'est un objet poignée, comme dans Simulink : Q = P désigne le même
%   paramètre, et Q = COPY(P) en fait un autre.
%
%   Exemple :
%      K = Simulink.Parameter(3);
%      K.DataType = 'int8';
%      K.Min = 0;
%      K.Max = 10;
%      K.Dimensions                       % 1 1
%      L = copy(K);
%      L.Value = 4;
%      K.Value                            % 3 : la copie est un autre objet
%
%   Voir aussi SIMULINK.SIGNAL, SIMULINK.SIMULATIONINPUT, SIM.
    properties
        Value = []
        CoderInfo = []
        Description = ''
        DataType = 'auto'
        Min = []
        Max = []
        Unit = ''
    end
    properties (Dependent)
        Complexity
        Dimensions
    end
    methods
        function obj = Parameter(valeur)
            obj.CoderInfo = Simulink.CoderInfo;
            if nargin > 0
                obj.Value = valeur;
            end
        end
        function set.Value(obj, v)
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            if ~(isnumeric(v) || islogical(v) || isstruct(v) || ischar(v) || isobject(v))
                error('Simulink:Data:InvalidParameterValue', ...
                      ['La valeur d''un Simulink.Parameter est un nombre, un tableau, un ' ...
                       'booleen ou une structure ; pas un %s.'], class(v));
            end
            obj.Value = v;
        end
        function set.DataType(obj, t)
            if isstring(t) && isscalar(t)
                t = char(t);
            end
            if ~ischar(t) || isempty(strtrim(t))
                error('Simulink:Data:InvalidDataType', ...
                      ['Le DataType d''un Simulink.Parameter est un nom de type : ''auto'', ' ...
                       '''double'', ''int8'', ''boolean'', ''Bus: X''…']);
            end
            t = strtrim(t);
            valide = any(strcmp(t, matlibre_sl_parametre('types'))) || ...
                     ~isempty(regexp(t, '^(Bus|Enum):\s*[A-Za-z]\w*$', 'once')) || ...
                     ~isempty(regexp(t, '^fixdt\(.*\)$', 'once')) || isvarname(t);
            if ~valide
                error('Simulink:Data:InvalidDataType', ...
                      ['''%s'' n''est pas un type : on attend ''auto'', ''double'', ' ...
                       '''single'', ''int8''…''uint64'', ''boolean'', ''Bus: X'' ou ' ...
                       '''Enum: X''.'], t);
            end
            obj.DataType = t;
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
        function d = get.Dimensions(obj)
            d = size(obj.Value);
        end
        function c = get.Complexity(obj)
            c = 'real';
            if isnumeric(obj.Value) && ~isreal(obj.Value)
                c = 'complex';
            end
        end
        function c = copy(obj)
            c = Simulink.Parameter;
            c.Value = obj.Value;
            c.CoderInfo = obj.CoderInfo;
            c.Description = obj.Description;
            c.DataType = obj.DataType;
            c.Min = obj.Min;
            c.Max = obj.Max;
            c.Unit = obj.Unit;
        end
        function disp(obj)
            matlibre_sl_proprietes(obj, {'Value', 'CoderInfo', 'Description', 'DataType', ...
                                         'Min', 'Max', 'Unit', 'Complexity', 'Dimensions'});
        end
    end
end
