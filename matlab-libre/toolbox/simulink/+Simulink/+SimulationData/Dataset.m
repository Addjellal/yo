classdef Dataset
%DATASET Un ensemble de signaux journalisés, comme SIM les rend.
%   Quand SaveFormat vaut 'Dataset', la sortie de SIM porte dans yout un
%   Dataset : un élément par sortie du modèle, dans l'ordre de leur
%   paramètre Port, chacun un SIMULINK.SIMULATIONDATA.SIGNAL dont Values
%   est une TIMESERIES.
%
%   DS{I} et GET(DS,I) rendent le I-ème élément ; GET(DS,NOM) et
%   GETELEMENT(DS,NOM) celui qui porte ce nom ; NUMELEMENTS(DS) leur
%   nombre ; GETELEMENTNAMES(DS) leurs noms. ADDELEMENT(DS,S) en ajoute un.
%
%   Exemple :
%      ds = Simulink.SimulationData.Dataset;
%      s = Simulink.SimulationData.Signal;
%      s.Name = 'y';
%      s.Values = timeseries([1; 2], [0 1]);
%      ds = addElement(ds, s);
%      ds{1}.Values.Data                 % [1; 2]
%
%   Voir aussi SIMULINK.SIMULATIONDATA.SIGNAL, TIMESERIES, SIM.
    properties
        Name = ''
        Elements = {}
    end
    methods
        function ds = Dataset(nom)
            if nargin > 0
                ds.Name = char(nom);
            end
        end
        function n = numElements(ds)
            n = numel(ds.Elements);
        end
        function noms = getElementNames(ds)
            noms = cellfun(@(e) e.Name, ds.Elements, 'UniformOutput', false);
            noms = noms(:);
        end
        function e = getElement(ds, cle)
            e = get(ds, cle);
        end
        function e = get(ds, cle)
            if ischar(cle) || isstring(cle)
                rang = find(strcmp(getElementNames(ds), char(cle)));
                if isempty(rang)
                    error('Simulink:SimulationData:DatasetElementNotFound', ...
                          'Le Dataset ne porte pas d''element nomme ''%s''.', char(cle));
                end
                if numel(rang) == 1
                    e = ds.Elements{rang};
                else
                    e = ds.Elements(rang);   % plusieurs du même nom
                end
                return
            end
            if ~(isnumeric(cle) && isscalar(cle) && cle >= 1 && cle <= numel(ds.Elements) && ...
                 cle == round(cle))
                error('Simulink:SimulationData:DatasetIndexOutOfRange', ...
                      'Le Dataset a %d element(s) : pas d''element %s.', numel(ds.Elements), ...
                      mat2str(cle));
            end
            e = ds.Elements{cle};
        end
        function ds = addElement(ds, element, nom)
            if nargin > 2
                element.Name = char(nom);
            end
            ds.Elements{end + 1} = element;
        end
        function varargout = subsref(ds, s)
            switch s(1).type
                case '{}'
                    r = get(ds, s(1).subs{1});
                case '.'
                    if any(strcmp(s(1).subs, {'numElements', 'getElementNames', 'getElement', ...
                                               'get', 'addElement'}))
                        arguments_ = {};
                        suite = s(2:end);
                        if ~isempty(suite) && strcmp(suite(1).type, '()')
                            arguments_ = suite(1).subs;
                            suite = suite(2:end);
                        end
                        r = feval(s(1).subs, ds, arguments_{:});
                        s = [s(1), suite];
                    else
                        r = ds.(s(1).subs);
                    end
                otherwise
                    r = ds;
            end
            if numel(s) > 1
                [varargout{1:nargout}] = subsref(r, s(2:end));
            else
                varargout{1} = r;
            end
        end
        function n = numel(ds, varargin) %#ok<INUSD>
            n = 1;
        end
        function disp(ds)
            fprintf('  Simulink.SimulationData.Dataset ''%s'' with %d element(s)\n\n', ds.Name, ...
                    numel(ds.Elements));
            for k = 1:numel(ds.Elements)
                fprintf('    %d  [1x1 Signal]  %s  %s\n', k, ds.Elements{k}.Name, ...
                        ds.Elements{k}.BlockPath);
            end
            fprintf('\n');
        end
    end
end
