classdef DiffSignalResult
%DIFFSIGNALRESULT Le résultat de la comparaison de deux signaux.
%   SIMULINK.SDI.COMPARESIGNALS le rend, GETRESULTBYINDEX d'un
%   Simulink.sdi.DiffRunResult aussi. Propriétés : Name ; Status, un
%   Simulink.sdi.ComparisonSignalStatus ; Match, vrai quand l'écart tient
%   dans la tolérance ; MaxDifference, le plus grand écart ; SignalID1 et
%   SignalID2 ; Sig1 et Sig2, les deux signaux sur les instants communs,
%   Diff leur écart, Tol la tolérance, des timeseries ; AbsTol, RelTol,
%   TimeTol, les tolérances appliquées.
%
%   Exemple :
%      a = timeseries((0:4)', 0:4, 'Name', 'x');
%      b = timeseries((0:4)' + 0.05, 0:4, 'Name', 'x');
%      [~, ~, ia] = Simulink.sdi.createRun('a', 'vars', a);
%      [~, ~, ib] = Simulink.sdi.createRun('b', 'vars', b);
%      d = Simulink.sdi.compareSignals(ia, ib, 'AbsTol', 0.1);
%      d.Match                            % true
%      Simulink.sdi.clear;
%
%   Voir aussi SIMULINK.SDI.COMPARESIGNALS, SIMULINK.SDI.DIFFRUNRESULT.
    properties (SetAccess = private)
        Name = ''
        Status = Simulink.sdi.ComparisonSignalStatus.Empty
        MaxDifference = NaN
        SignalID1 = 0
        SignalID2 = 0
        Sig1 = []
        Sig2 = []
        Diff = []
        Tol = []
        AbsTol = 0
        RelTol = 0
        TimeTol = 0
    end
    properties (Dependent)
        Match
    end
    methods
        function d = DiffSignalResult(D)
            if nargin > 0
                for champ = {'Name', 'MaxDifference', 'SignalID1', 'SignalID2', 'Sig1', ...
                             'Sig2', 'Diff', 'Tol', 'AbsTol', 'RelTol', 'TimeTol'}
                    d.(champ{1}) = D.(champ{1});
                end
                d.Status = Simulink.sdi.ComparisonSignalStatus(D.Status);
            end
        end
        function v = get.Match(d)
            v = d.Status == Simulink.sdi.ComparisonSignalStatus.WithinTolerance;
        end
        function disp(d)
            for k = 1:numel(d)
                x = d(k);
                fprintf('  ''%s'' : %s, ecart maximal %g\n', x.Name, char(x.Status), ...
                        x.MaxDifference);
            end
            fprintf('\n');
        end
    end
end
