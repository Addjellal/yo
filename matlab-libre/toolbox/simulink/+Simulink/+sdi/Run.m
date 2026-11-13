classdef Run < handle
%RUN Un run du Simulation Data Inspector : des signaux nommés.
%   RUN = SIMULINK.SDI.GETRUN(ID) le rend ; SIMULINK.SDI.RUN.CREATE(NOM,
%   'vars',V1,V2,...) en crée un, SIMULINK.SDI.RUN.GETLATEST rend le
%   dernier créé.
%   Propriétés : ID, en lecture seule ; Name, Description, Model ;
%   SignalCount, RunIndex (son rang parmi les runs) et DateCreated.
%   Méthodes : GETSIGNALBYINDEX(RUN,K), GETSIGNALIDBYINDEX, GETALLSIGNALS,
%   GETALLSIGNALIDS, GETSIGNALSBYNAME(RUN,NOM), GETSIGNALIDSBYNAME,
%   ADD(RUN,'vars',V1,...) qui y ajoute des signaux, EXPORT(RUN) qui les
%   rend dans un Simulink.SimulationData.Dataset.
%
%   Exemple :
%      run = Simulink.sdi.Run.create('runEssai', 'vars', timeseries((1:3)', 0:2, 'Name', 'x'));
%      run.SignalCount                    % 1
%      add(run, 'vars', timeseries((4:6)', 0:2, 'Name', 'y'));
%      getSignalByIndex(run, 2).Name      % 'y'
%      Simulink.sdi.deleteRun(run.ID);
%
%   Voir aussi SIMULINK.SDI.CREATERUN, SIMULINK.SDI.SIGNAL, SIMULINK.SDI.COMPARERUNS.
    properties (SetAccess = private)
        ID = 0
    end
    properties (Dependent)
        Name
        Description
        Model
    end
    properties (Dependent, SetAccess = private)
        SignalCount
        RunIndex
        DateCreated
    end
    methods
        function r = Run(id)
            if nargin > 0
                matlibre_sdi('run', id);
                r.ID = id;
            end
        end
        function v = get.Name(r), v = lire(r, 'Name'); end
        function v = get.Description(r), v = lire(r, 'Description'); end
        function v = get.Model(r), v = lire(r, 'Model'); end
        function v = get.DateCreated(r), v = lire(r, 'DateCreated'); end
        function v = get.SignalCount(r), v = numel(lire(r, 'Signaux')); end
        function v = get.RunIndex(r), v = find(matlibre_sdi('runs') == r.ID, 1); end
        function set.Name(r, v), matlibre_sdi('poserrun', r.ID, 'Name', texte('Name', v)); end
        function set.Description(r, v)
            matlibre_sdi('poserrun', r.ID, 'Description', texte('Description', v));
        end
        function set.Model(r, v), matlibre_sdi('poserrun', r.ID, 'Model', texte('Model', v)); end
        function id = getSignalIDByIndex(r, k)
            ids = lire(r, 'Signaux');
            if ~isnumeric(k) || ~isscalar(k) || k < 1 || k > numel(ids) || k ~= round(k)
                error('SDI:sdi:IndexOutOfRange', ...
                      'Le run ''%s'' porte %d signal(aux) : il n''a pas de signal %s.', ...
                      r.Name, numel(ids), strtrim(evalc('disp(k)')));
            end
            id = ids(k);
        end
        function s = getSignalByIndex(r, k)
            s = Simulink.sdi.Signal(getSignalIDByIndex(r, k));
        end
        function ids = getAllSignalIDs(r)
            ids = lire(r, 'Signaux');
            ids = ids(:);
        end
        function s = getAllSignals(r)
            s = signaux(getAllSignalIDs(r));
        end
        function ids = getSignalIDsByName(r, nom)
            ids = zeros(0, 1);
            for id = lire(r, 'Signaux')
                S = matlibre_sdi('signal', id);
                if strcmp(S.Name, char(nom))
                    ids(end + 1, 1) = id; %#ok<AGROW>
                end
            end
        end
        function s = getSignalsByName(r, nom)
            s = signaux(getSignalIDsByName(r, nom));
        end
        function ids = add(r, source, varargin)
            [noms, valeurs] = matlibre_sdi_sources(source, varargin, inputname(3));
            ids = matlibre_sdi('ajouter', r.ID, noms, valeurs);
            ids = ids(:);
        end
        function ds = export(r)
            ds = Simulink.SimulationData.Dataset(r.Name);
            for id = lire(r, 'Signaux')
                S = matlibre_sdi('signal', id);
                ds = addElement(ds, S.Values, S.Name);
            end
        end
        function disp(r)
            for k = 1:numel(r)
                x = r(k);
                fprintf('  Simulink.sdi.Run %d ''%s'' : %d signal(aux)\n', x.ID, x.Name, ...
                        x.SignalCount);
            end
            fprintf('\n');
        end
    end
    methods (Static)
        function r = create(nom, varargin)
            if nargin < 1
                nom = '';
            end
            id = matlibre_sdi('creer', nom);
            r = Simulink.sdi.Run(id);
            if ~isempty(varargin)
                [noms, valeurs] = matlibre_sdi_sources(varargin{1}, varargin(2:end), '');
                matlibre_sdi('ajouter', id, noms, valeurs);
            end
        end
        function r = getLatest()
            ids = matlibre_sdi('runs');
            if isempty(ids)
                error('SDI:sdi:NoRuns', 'Le Simulation Data Inspector n''a pas de run.');
            end
            r = Simulink.sdi.Run(ids(end));
        end
    end
end

function v = lire(r, champ)
    R = matlibre_sdi('run', r.ID);
    v = R.(champ);
end

function s = signaux(ids)
    s = [];
    liste = cell(1, numel(ids));
    for k = 1:numel(ids)
        liste{k} = Simulink.sdi.Signal(ids(k));
    end
    if ~isempty(liste)
        s = [liste{:}];
    end
end

function v = texte(nom, v)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v)
        error('SDI:sdi:InvalidValue', '%s est un texte.', nom);
    end
end
