function d = compareRuns(id1, id2, varargin)
%COMPARERUNS Compare deux runs du Simulation Data Inspector.
%   D = SIMULINK.SDI.COMPARERUNS(ID1,ID2) apparie les signaux du run ID2 à
%   ceux du run de base ID1 — par leur bloc et leur port quand les deux en
%   ont un, sinon par leur nom — et compare chaque paire comme
%   SIMULINK.SDI.COMPARESIGNALS ; un signal sans pendant est Unaligned.
%   Elle rend un Simulink.sdi.DiffRunResult. Les options 'AbsTol',
%   'RelTol', 'TimeTol', 'InterpMethod' et 'SyncMethod' valent pour tous
%   les signaux ; sans elles, chacun garde celles de son signal de base.
%
%   Exemple :
%      t = (0:0.1:1)';
%      ra = Simulink.sdi.createRun('a', 'vars', timeseries(t, t, 'Name', 'x'), ...
%                                  timeseries(2 * t, t, 'Name', 'y'));
%      rb = Simulink.sdi.createRun('b', 'vars', timeseries(t, t, 'Name', 'x'), ...
%                                  timeseries(2 * t + 1, t, 'Name', 'y'));
%      d = Simulink.sdi.compareRuns(ra, rb);
%      d.Summary.OutOfTolerance           % 1
%      Simulink.sdi.clear;
%
%   Voir aussi SIMULINK.SDI.COMPARESIGNALS, SIMULINK.SDI.DIFFRUNRESULT.
    o = matlibre_sdi_options(varargin, 'compareRuns');
    R1 = matlibre_sdi('run', id1);
    R2 = matlibre_sdi('run', id2);
    S2 = cell(1, numel(R2.Signaux));
    for k = 1:numel(R2.Signaux)
        S2{k} = matlibre_sdi('signal', R2.Signaux(k));
    end
    pris = false(1, numel(S2));
    resultats = {};
    for k = 1:numel(R1.Signaux)
        s1 = matlibre_sdi('signal', R1.Signaux(k));
        j = 0;
        for q = 1:numel(S2)
            if pris(q)
                continue
            end
            if ~isempty(s1.BlockPath) && ~isempty(S2{q}.BlockPath)
                pareil = strcmp(s1.BlockPath, S2{q}.BlockPath) && ...
                         isequal(s1.PortIndex, S2{q}.PortIndex) && strcmp(s1.Name, S2{q}.Name);
            else
                pareil = strcmp(s1.Name, S2{q}.Name);
            end
            if pareil
                j = q;
                break
            end
        end
        if j == 0
            resultats{end + 1} = seul(s1, true); %#ok<AGROW>
        else
            pris(j) = true;
            resultats{end + 1} = Simulink.sdi.DiffSignalResult( ...
                matlibre_sdi('comparer', s1, S2{j}, o)); %#ok<AGROW>
        end
    end
    for q = find(~pris)
        resultats{end + 1} = seul(S2{q}, false); %#ok<AGROW>
    end
    d = Simulink.sdi.DiffRunResult(id1, id2, resultats);
end

function r = seul(s, deBase)
    D = struct('Name', s.Name, 'Status', 'Unaligned', 'SignalID1', 0, 'SignalID2', 0, ...
               'MaxDifference', NaN, 'Sig1', [], 'Sig2', [], 'Diff', [], 'Tol', [], ...
               'AbsTol', 0, 'RelTol', 0, 'TimeTol', 0);
    if deBase
        D.SignalID1 = s.ID;
        D.Sig1 = s.Values;
    else
        D.SignalID2 = s.ID;
        D.Sig2 = s.Values;
    end
    r = Simulink.sdi.DiffSignalResult(D);
end
