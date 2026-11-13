classdef Signal < handle
%SIGNAL Un signal d'un run du Simulation Data Inspector.
%   S = SIMULINK.SDI.GETSIGNAL(ID), ou GETSIGNALBYINDEX(RUN,K), le rend.
%   Propriétés : ID et RunID, en lecture seule ; Name ; Values, ses
%   valeurs, un timeseries ; BlockPath, PortIndex ; AbsTol, RelTol et
%   TimeTol, les tolérances qui valent quand il sert de base à une
%   comparaison ; InterpMethod, 'linear' ou 'zoh' ; SyncMethod, 'union'
%   ou 'intersection' ; Description, Units.
%
%   Exemple :
%      id = Simulink.sdi.createRun('signalEssai', 'vars', timeseries((1:3)', 0:2, 'Name', 'x'));
%      run = Simulink.sdi.getRun(id);
%      s = getSignalByIndex(run, 1);
%      s.AbsTol = 0.1;
%      s.Values.Data(end)                 % 3
%      Simulink.sdi.deleteRun(id);
%
%   Voir aussi SIMULINK.SDI.RUN, SIMULINK.SDI.COMPARESIGNALS.
    properties (SetAccess = private)
        ID = 0
    end
    properties (Dependent)
        Name
        AbsTol
        RelTol
        TimeTol
        InterpMethod
        SyncMethod
        Description
        Units
    end
    properties (Dependent, SetAccess = private)
        RunID
        Values
        BlockPath
        PortIndex
    end
    methods
        function s = Signal(id)
            if nargin > 0
                matlibre_sdi('signal', id);
                s.ID = id;
            end
        end
        function v = get.Name(s), v = lire(s, 'Name'); end
        function v = get.AbsTol(s), v = lire(s, 'AbsTol'); end
        function v = get.RelTol(s), v = lire(s, 'RelTol'); end
        function v = get.TimeTol(s), v = lire(s, 'TimeTol'); end
        function v = get.InterpMethod(s), v = lire(s, 'InterpMethod'); end
        function v = get.SyncMethod(s), v = lire(s, 'SyncMethod'); end
        function v = get.Description(s), v = lire(s, 'Description'); end
        function v = get.Units(s), v = lire(s, 'Units'); end
        function v = get.RunID(s), v = lire(s, 'RunID'); end
        function v = get.Values(s), v = lire(s, 'Values'); end
        function v = get.BlockPath(s), v = lire(s, 'BlockPath'); end
        function v = get.PortIndex(s), v = lire(s, 'PortIndex'); end
        function set.Name(s, v), poser(s, 'Name', texte('Name', v)); end
        function set.Description(s, v), poser(s, 'Description', texte('Description', v)); end
        function set.Units(s, v), poser(s, 'Units', texte('Units', v)); end
        function set.AbsTol(s, v), poser(s, 'AbsTol', tolerance('AbsTol', v)); end
        function set.RelTol(s, v), poser(s, 'RelTol', tolerance('RelTol', v)); end
        function set.TimeTol(s, v), poser(s, 'TimeTol', tolerance('TimeTol', v)); end
        function set.InterpMethod(s, v)
            poser(s, 'InterpMethod', choix('InterpMethod', v, {'linear', 'zoh'}));
        end
        function set.SyncMethod(s, v)
            poser(s, 'SyncMethod', choix('SyncMethod', v, {'union', 'intersection'}));
        end
        function ts = export(s)
            ts = s.Values;
        end
        function disp(s)
            for k = 1:numel(s)
                x = s(k);
                fprintf('  Simulink.sdi.Signal %d ''%s'' du run %d, %d instants\n', x.ID, ...
                        x.Name, x.RunID, x.Values.Length);
            end
            fprintf('\n');
        end
    end
end

function v = lire(s, champ)
    S = matlibre_sdi('signal', s.ID);
    v = S.(champ);
end

function poser(s, champ, v)
    matlibre_sdi('posersignal', s.ID, champ, v);
end

function v = texte(nom, v)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v)
        error('SDI:sdi:InvalidValue', '%s est un texte.', nom);
    end
end

function v = tolerance(nom, v)
    if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~(v >= 0) || ~isfinite(v)
        error('SDI:sdi:InvalidTolerance', '%s est un nombre reel positif ou nul, fini.', nom);
    end
    v = double(v);
end

function v = choix(nom, v, admis)
    k = [];
    if ischar(v) || (isstring(v) && isscalar(v))
        k = find(strcmpi(char(v), admis), 1);
    end
    if isempty(k)
        error('SDI:sdi:InvalidValue', '%s vaut %s.', nom, strjoin(admis, ' ou '));
    end
    v = admis{k};
end
