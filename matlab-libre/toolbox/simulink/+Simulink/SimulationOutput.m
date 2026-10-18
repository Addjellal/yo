classdef SimulationOutput
%SIMULINK.SIMULATIONOUTPUT Le résultat d'une simulation.
%   OUT = SIM(MODELE) rend un SIMULINK.SIMULATIONOUTPUT : les variables que
%   la simulation relève — tout, xout, yout, logsout, xFinal... sous les
%   noms que règle le modèle —, ses métadonnées et son message d'erreur.
%   PARSIM et SIM d'un tableau de SIMULINK.SIMULATIONINPUT en rendent un
%   tableau, un par simulation.
%
%   Chaque variable se lit par son nom, OUT.yout, ou par OUT.get('yout') ;
%   OUT.who rend leurs noms. OUT.SimulationMetadata porte le modèle, ses
%   instants et son solveur (ModelInfo), la façon dont la simulation s'est
%   arrêtée (ExecutionInfo), sa durée (TimingInfo), et UserString et
%   UserData, que SETUSERSTRING et SETUSERDATA posent. OUT.ErrorMessage
%   est vide si la simulation a abouti.
%
%   Méthodes : GET, FIND (ancien nom de GET), WHO, GETSIMULATIONMETADATA,
%   SETUSERSTRING, SETUSERDATA ; ISFIELD dit si une variable est relevée,
%   FIELDNAMES rend les variables suivies de ErrorMessage et de
%   SimulationMetadata, STRUCT le tout en structure.
%
%   Exemple :
%      m = new_system('so');
%      m = add_block(m, 'constant', 'c', 'Value', 3);
%      m = add_block(m, 'outport', 'y');
%      m = add_line(m, 'c', 'y');
%      out = sim(m, 'StopTime', 1);
%      out.yout(end)                              % 3
%      out.who                                    % {'tout'; 'yout'}
%      out.SimulationMetadata.ModelInfo.ModelName % 'so'
%
%   Voir aussi SIM, PARSIM, SIMULINK.SIMULATIONINPUT.
    properties (SetAccess = private)
        SimulationMetadata = struct()
        ErrorMessage = ''
    end
    properties (Access = private)
        Donnees = struct()
    end
    methods
        function obj = SimulationOutput(donnees)
            if nargin == 0
                return
            end
            if isa(donnees, 'Simulink.SimulationOutput')
                obj = donnees;
                return
            end
            if ~isstruct(donnees) || numel(donnees) ~= 1
                error('Simulink:Simulation:InvalidSimulationOutput', ...
                      'Un SimulationOutput se fait d''une structure de variables.');
            end
            if isfield(donnees, 'ErrorMessage')
                obj.ErrorMessage = donnees.ErrorMessage;
                donnees = rmfield(donnees, 'ErrorMessage');
            end
            if isfield(donnees, 'SimulationMetadata')
                obj.SimulationMetadata = donnees.SimulationMetadata;
                donnees = rmfield(donnees, 'SimulationMetadata');
            end
            obj.Donnees = donnees;
        end

        function v = get(obj, nom)
            nom = char(nom);
            if ~isfield(obj.Donnees, nom)
                error('Simulink:Simulation:UnknownVariable', ...
                      ['La simulation n''a pas releve de variable ''%s'' ; elle releve : ' ...
                       '%s.'], nom, strjoin(fieldnames(obj.Donnees).', ', '));
            end
            v = obj.Donnees.(nom);
        end

        function v = find(obj, nom)
            v = get(obj, nom);
        end

        function noms = who(obj)
            noms = fieldnames(obj.Donnees);
        end

        function oui = isfield(obj, noms)
            oui = isfield(obj.Donnees, noms);
        end

        function noms = fieldnames(obj)
            noms = [fieldnames(obj.Donnees); {'ErrorMessage'; 'SimulationMetadata'}];
        end

        % Combien de valeurs rend « out.a.b » là où une liste est attendue
        % — « {out.signals.label} » : autant que la même chaîne lue sur
        % les variables, comme sur une structure.
        function n = numArgumentsFromSubscript(obj, s, contexte) %#ok<INUSD>
            n = 1;
            if strcmp(s(1).type, '()')
                obj = builtin('subsref', obj, s(1));
                s = s(2:end);
            end
            if numel(s) < 2 || numel(obj) ~= 1 || ~strcmp(s(1).type, '.') || ...
               ~isfield(obj.Donnees, s(1).subs)
                return
            end
            v = obj.Donnees.(s(1).subs);
            try
                for k = 2:numel(s) - 1
                    if ~isstruct(v) && ~iscell(v) && ~isnumeric(v) && ~islogical(v)
                        return
                    end
                    v = subsref(v, s(k));
                end
            catch
                return   % la lecture elle-même dira ce qui ne va pas
            end
            dernier = s(end);
            if strcmp(dernier.type, '.') && isstruct(v)
                n = numel(v);
            elseif strcmp(dernier.type, '{}') && iscell(v)
                n = numel(subsref(v, struct('type', '()', 'subs', {dernier.subs})));
            end
        end

        function s = struct(obj)
            s = obj.Donnees;
            s.ErrorMessage = obj.ErrorMessage;
            s.SimulationMetadata = obj.SimulationMetadata;
        end

        function m = getSimulationMetadata(obj)
            m = obj.SimulationMetadata;
        end

        function obj = setUserString(obj, texte)
            obj.SimulationMetadata.UserString = char(texte);
        end

        function obj = setUserData(obj, donnee)
            obj.SimulationMetadata.UserData = donnee;
        end

        function varargout = subsref(obj, s)
            switch s(1).type
                case '()'
                    v = builtin('subsref', obj, s(1));
                    reste = s(2:end);
                case '.'
                    if numel(obj) ~= 1
                        error('Simulink:Simulation:ArrayIndexing', ...
                              ['Un tableau de SimulationOutput se lit element par element : ' ...
                               'out(k).%s.'], s(1).subs);
                    end
                    nom = s(1).subs;
                    reste = s(2:end);
                    switch nom
                        case {'SimulationMetadata', 'ErrorMessage'}
                            v = obj.(nom);
                        case {'get', 'find', 'who', 'isfield', 'fieldnames', 'struct', ...
                              'getSimulationMetadata', 'setUserString', 'setUserData'}
                            arguments = {};
                            if ~isempty(reste) && strcmp(reste(1).type, '()')
                                arguments = reste(1).subs;
                                reste = reste(2:end);
                            end
                            v = feval(nom, obj, arguments{:});
                        otherwise
                            if ~isfield(obj.Donnees, nom)
                                error('MATLAB:noSuchMethodOrField', ...
                                      ['Unrecognized method, property, or field ''%s'' for ' ...
                                       'class ''Simulink.SimulationOutput''.'], nom);
                            end
                            v = obj.Donnees.(nom);
                    end
                otherwise
                    error('MATLAB:cellRefFromNonCell', ...
                          'Brace indexing is not supported for variables of this type.');
            end
            if isempty(reste)
                varargout{1} = v;
            else
                [varargout{1:max(1, nargout)}] = subsref(v, reste);
            end
        end

        function disp(obj)
            if numel(obj) ~= 1
                fprintf('  %s Simulink.SimulationOutput array\n\n', ...
                        strjoin(arrayfun(@num2str, size(obj), 'UniformOutput', false), 'x'));
                return
            end
            noms = fieldnames(obj.Donnees);
            largeur = max([cellfun(@numel, noms); numel('SimulationMetadata')]) + 4;
            fprintf('  Simulink.SimulationOutput:\n');
            for k = 1:numel(noms)
                fprintf('%*s: %s\n', largeur, noms{k}, resume(obj.Donnees.(noms{k})));
            end
            fprintf('\n%*s: %s\n', largeur, 'SimulationMetadata', resume(obj.SimulationMetadata));
            fprintf('%*s: %s\n\n', largeur, 'ErrorMessage', resume(obj.ErrorMessage));
        end
    end
end

% Une valeur en quelques signes, comme MATLAB la montre dans une structure.
function t = resume(v)
    taille = strjoin(arrayfun(@num2str, size(v), 'UniformOutput', false), 'x');
    if ischar(v) && size(v, 1) == 1 && numel(v) <= 40 && ~isempty(v)
        t = ['''' v ''''];
    elseif (isnumeric(v) || islogical(v)) && isscalar(v)
        t = num2str(v);
    else
        t = sprintf('[%s %s]', taille, class(v));
    end
end
