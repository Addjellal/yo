function varargout = matlibre_sdi(action, varargin)
%MATLIBRE_SDI Les runs et les signaux du Simulation Data Inspector.
%   Le Simulation Data Inspector range des runs : chacun porte des
%   signaux, des timeseries nommés, que l'on compare d'un run à l'autre.
%   Cette fonction en tient le registre, pour la session :
%      ID = MATLIBRE_SDI('creer',NOM)               un run vide
%      IDS = MATLIBRE_SDI('ajouter',RUN,NOMS,VALEURS)  des signaux, tirés
%                        de timeseries, Dataset, SimulationOutput,
%                        structures avec temps, matrices [t x...]
%      R = MATLIBRE_SDI('run',ID), S = MATLIBRE_SDI('signal',ID)
%      MATLIBRE_SDI('poserrun',ID,CHAMP,V), ('posersignal',ID,CHAMP,V)
%      IDS = MATLIBRE_SDI('runs'), MATLIBRE_SDI('vider'),
%      MATLIBRE_SDI('retirerrun',ID), ('retirersignal',ID)
%      D = MATLIBRE_SDI('comparer',S1,S2,OPTIONS)   une comparaison de
%                        deux signaux, la base d'abord
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      id = matlibre_sdi('creer', 'essai');
%      ts = timeseries((0:4)', 0:4, 'Name', 'x');
%      ids = matlibre_sdi('ajouter', id, {'x'}, {ts});
%      s = matlibre_sdi('signal', ids(1));
%      s.Name                             % 'x'
%      matlibre_sdi('retirerrun', id);
%
%   Voir aussi SIMULINK.SDI.CREATERUN, SIMULINK.SDI.COMPARERUNS.
    persistent runs signaux ordre prochain
    if isempty(prochain)
        runs = containers.Map('KeyType', 'double', 'ValueType', 'any');
        signaux = containers.Map('KeyType', 'double', 'ValueType', 'any');
        ordre = zeros(1, 0);
        prochain = 1;
    end
    switch action
        case 'creer'
            nom = '';
            if ~isempty(varargin)
                nom = char(varargin{1});
            end
            id = prochain;
            prochain = prochain + 1;
            if isempty(nom)
                nom = sprintf('Run %d', numel(ordre) + 1);
            end
            runs(id) = struct('ID', id, 'Name', nom, 'Description', '', 'Signaux', zeros(1, 0), ...
                              'DateCreated', datestr(now, 31), 'Model', '');
            ordre(end + 1) = id;
            varargout{1} = id;
        case 'ajouter'
            [idRun, noms, valeurs] = varargin{1:3};
            R = exigerRun(runs, idRun);
            ids = zeros(1, 0);
            for k = 1:numel(valeurs)
                trouves = extraire(noms{k}, valeurs{k});
                for j = 1:numel(trouves)
                    id = prochain;
                    prochain = prochain + 1;
                    s = trouves(j);
                    s.ID = id;
                    s.RunID = idRun;
                    signaux(id) = s;
                    ids(end + 1) = id; %#ok<AGROW>
                end
            end
            R.Signaux = [R.Signaux, ids];
            runs(idRun) = R;
            varargout{1} = ids;
        case 'run'
            varargout{1} = exigerRun(runs, varargin{1});
        case 'signal'
            varargout{1} = exigerSignal(signaux, varargin{1});
        case 'poserrun'
            [id, champ, v] = varargin{1:3};
            R = exigerRun(runs, id);
            R.(champ) = v;
            runs(id) = R;
        case 'posersignal'
            [id, champ, v] = varargin{1:3};
            S = exigerSignal(signaux, id);
            S.(champ) = v;
            signaux(id) = S;
        case 'runs'
            varargout{1} = ordre;
        case 'existe'
            varargout{1} = isKey(runs, double(varargin{1}));
        case 'vider'
            runs = containers.Map('KeyType', 'double', 'ValueType', 'any');
            signaux = containers.Map('KeyType', 'double', 'ValueType', 'any');
            ordre = zeros(1, 0);
        case 'retirerrun'
            id = varargin{1};
            R = exigerRun(runs, id);
            for s = R.Signaux
                if isKey(signaux, s)
                    remove(signaux, s);
                end
            end
            remove(runs, id);
            ordre(ordre == id) = [];
        case 'retirersignal'
            id = varargin{1};
            S = exigerSignal(signaux, id);
            remove(signaux, id);
            R = runs(S.RunID);
            R.Signaux(R.Signaux == id) = [];
            runs(S.RunID) = R;
        case 'comparer'
            [s1, s2, options] = varargin{1:3};
            varargout{1} = comparer(s1, s2, options);
        otherwise
            error('SDI:sdi:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

function R = exigerRun(runs, id)
    if ~(isnumeric(id) && isscalar(id)) || ~isKey(runs, double(id))
        error('SDI:sdi:InvalidRunID', ...
              'Le Simulation Data Inspector n''a pas de run d''identifiant %s.', ...
              strtrim(evalc('disp(id)')));
    end
    R = runs(double(id));
end

function S = exigerSignal(signaux, id)
    if ~(isnumeric(id) && isscalar(id)) || ~isKey(signaux, double(id))
        error('SDI:sdi:InvalidSignalID', ...
              'Le Simulation Data Inspector n''a pas de signal d''identifiant %s.', ...
              strtrim(evalc('disp(id)')));
    end
    S = signaux(double(id));
end

% --- les signaux d'une valeur ------------------------------------------------------

function s = signalNeuf(nom, ts, chemin, port)
    s = struct('ID', 0, 'RunID', 0, 'Name', nom, 'Values', ts, 'BlockPath', chemin, ...
               'PortIndex', port, 'AbsTol', 0, 'RelTol', 0, 'TimeTol', 0, ...
               'InterpMethod', 'linear', 'SyncMethod', 'union', 'Description', '', ...
               'Units', '');
end

function S = extraire(nom, v)
    S = signalNeuf('', [], '', 1);
    S = S([]);
    if isa(v, 'timeseries')
        if ~isempty(v.Name) && ~strcmp(v.Name, 'unnamed')
            nom = v.Name;
        end
        v.Name = nom;
        S = signalNeuf(nom, v, '', 1);
    elseif isa(v, 'Simulink.SimulationData.Dataset')
        for k = 1:numElements(v)
            e = getElement(v, k);
            S = [S, deElement(e)]; %#ok<AGROW>
        end
    elseif isa(v, 'Simulink.SimulationOutput')
        noms = who(v);
        temps = [];
        if any(strcmp(noms, 'tout'))
            temps = get(v, 'tout');
        end
        for k = 1:numel(noms)
            % le temps, et les champs que MatLibre garde pour ses anciens
            % programmes, ne sont pas des signaux
            if any(strcmp(noms{k}, {'tout', 'temps', 'signaux', 'time', 'signals', 'blockName'}))
                continue
            end
            x = get(v, noms{k});
            if (isnumeric(x) || islogical(x)) && ~isempty(temps) && size(x, 1) == numel(temps)
                for c = 1:size(x, 2)
                    S = [S, signalNeuf(sprintf('%s(:,%d)', noms{k}, c), ...
                                       timeseries(double(x(:, c)), temps(:), ...
                                                  'Name', sprintf('%s(:,%d)', noms{k}, c)), ...
                                       '', c)]; %#ok<AGROW>
                end
            elseif isa(x, 'timeseries') || isa(x, 'Simulink.SimulationData.Dataset') || ...
                   (isstruct(x) && isfield(x, 'time') && isfield(x, 'signals'))
                S = [S, extraire(noms{k}, x)]; %#ok<AGROW>
            end
        end
    elseif isstruct(v) && isfield(v, 'time') && isfield(v, 'signals')
        % une structure avec temps, comme SaveFormat 'StructureWithTime'
        for k = 1:numel(v.signals)
            sig = v.signals(k);
            libelle = sprintf('%s(%d)', nom, k);
            if isfield(sig, 'label') && ~isempty(sig.label)
                libelle = sig.label;
            elseif isfield(sig, 'blockName') && ~isempty(sig.blockName)
                libelle = sig.blockName;
            end
            chemin = '';
            if isfield(sig, 'blockName')
                chemin = sig.blockName;
            end
            S = [S, signalNeuf(libelle, timeseries(double(sig.values), v.time(:), ...
                                                  'Name', libelle), chemin, 1)]; %#ok<AGROW>
        end
    elseif isstruct(v)
        % un bus : une structure de timeseries
        for champ = fieldnames(v).'
            S = [S, extraire([nom '.' champ{1}], v.(champ{1}))]; %#ok<AGROW>
        end
    elseif (isnumeric(v) || islogical(v)) && ismatrix(v) && size(v, 2) >= 2 && size(v, 1) >= 1
        % une matrice : le temps en première colonne, un signal par colonne
        for c = 2:size(v, 2)
            libelle = nom;
            if size(v, 2) > 2
                libelle = sprintf('%s(:,%d)', nom, c - 1);
            end
            S = [S, signalNeuf(libelle, timeseries(double(v(:, c)), double(v(:, 1)), ...
                                                  'Name', libelle), '', c - 1)]; %#ok<AGROW>
        end
    else
        error('SDI:sdi:InvalidSourceType', ...
              ['La variable ''%s'' (%s) ne se range pas dans un run : le Simulation Data ' ...
               'Inspector prend des timeseries, des Simulink.SimulationData.Dataset, des ' ...
               'Simulink.SimulationOutput, des structures avec temps et des matrices dont ' ...
               'la premiere colonne est le temps.'], nom, class(v));
    end
end

function S = deElement(e)
    if isa(e, 'timeseries')
        S = extraire(e.Name, e);
        return
    end
    nom = '';
    if isprop(e, 'Name') || isfield(e, 'Name')
        nom = e.Name;
    end
    chemin = '';
    port = 1;
    if isa(e, 'Simulink.SimulationData.Signal')
        chemin = e.BlockPath;
        port = e.PortIndex;
        if isempty(nom)
            nom = e.PropagatedName;
        end
    end
    valeurs = e.Values;
    if isa(valeurs, 'timeseries')
        valeurs.Name = nom;
        S = signalNeuf(nom, valeurs, char(chemin), port);
    else
        S = extraire(nom, valeurs);
    end
end

% --- la comparaison --------------------------------------------------------------

function D = comparer(s1, s2, o)
    D = struct('Name', s1.Name, 'Status', 'WithinTolerance', 'SignalID1', s1.ID, ...
               'SignalID2', s2.ID, 'MaxDifference', NaN, 'Sig1', [], 'Sig2', [], ...
               'Diff', [], 'Tol', [], 'AbsTol', 0, 'RelTol', 0, 'TimeTol', 0);
    absTol = choisir(o, 'AbsTol', s1.AbsTol);
    relTol = choisir(o, 'RelTol', s1.RelTol);
    tempsTol = choisir(o, 'TimeTol', s1.TimeTol);
    methode = choisir(o, 'InterpMethod', s1.InterpMethod);
    synchro = choisir(o, 'SyncMethod', s1.SyncMethod);
    D.AbsTol = absTol;
    D.RelTol = relTol;
    D.TimeTol = tempsTol;
    a = s1.Values;
    b = s2.Values;
    if isempty(a) || isempty(b) || a.Length == 0 || b.Length == 0
        D.Status = 'Empty';
        return
    end
    [ta, va] = colonnes(a);
    [tb, vb] = colonnes(b);
    if size(va, 2) ~= size(vb, 2)
        D.Status = 'Unsupported';
        return
    end
    debut = max(ta(1), tb(1));
    fin = min(ta(end), tb(end));
    if debut > fin
        D.Status = 'EmptySynced';
        return
    end
    if strcmp(synchro, 'intersection')
        t = intersect(ta, tb);
    else
        t = union(ta, tb);
    end
    t = t(t >= debut & t <= fin);
    if isempty(t)
        D.Status = 'EmptySynced';
        return
    end
    xa = interpoler(ta, va, t, methode);
    xb = interpoler(tb, vb, t, methode);
    tol = max(absTol, relTol * abs(xa));
    if tempsTol > 0
        % une tolérance en temps : la bande que tient la base sur
        % [t - TimeTol, t + TimeTol]
        haut = xa;
        bas = xa;
        for k = 1:numel(t)
            fenetre = abs(t - t(k)) <= tempsTol;
            haut(k, :) = max(xa(fenetre, :), [], 1);
            bas(k, :) = min(xa(fenetre, :), [], 1);
        end
        hors = xb > haut + tol | xb < bas - tol;
    else
        hors = abs(xb - xa) > tol;
    end
    ecart = xb - xa;
    D.MaxDifference = max(abs(ecart(:)));
    if any(hors(:))
        D.Status = 'OutOfTolerance';
    end
    D.Sig1 = timeseries(xa, t, 'Name', s1.Name);
    D.Sig2 = timeseries(xb, t, 'Name', s2.Name);
    D.Diff = timeseries(ecart, t, 'Name', s1.Name);
    D.Tol = timeseries(tol, t, 'Name', s1.Name);
end

function v = choisir(o, nom, defaut)
    v = defaut;
    if isfield(o, nom) && ~isempty(o.(nom))
        v = o.(nom);
    end
end

function [t, v] = colonnes(ts)
    t = double(ts.Time(:));
    v = double(ts.Data);
    if ~ts.IsTimeFirst || (ndims(v) == 3)
        v = reshape(v, [], numel(t)).';
    end
    if size(v, 1) ~= numel(t)
        v = reshape(v, numel(t), []);
    end
    % des instants doublés — un passage par zéro — : la dernière valeur
    [t, dernier] = unique(t, 'last');
    v = v(dernier, :);
end

function x = interpoler(ta, va, t, methode)
    if numel(ta) == 1
        x = repmat(va, numel(t), 1);
        return
    end
    if strcmp(methode, 'zoh')
        x = interp1(ta, va, t, 'previous');
        x(t >= ta(end), :) = repmat(va(end, :), nnz(t >= ta(end)), 1);
    else
        x = interp1(ta, va, t, 'linear');
    end
    if isvector(x) && size(va, 2) == 1
        x = x(:);
    end
end
