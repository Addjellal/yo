classdef DiffRunResult
%DIFFRUNRESULT Le résultat de la comparaison de deux runs.
%   SIMULINK.SDI.COMPARERUNS le rend. Propriétés : RunID1 et RunID2 ;
%   Count, le nombre de signaux comparés ou laissés sans pendant ;
%   Summary, une structure qui compte chaque issue — WithinTolerance,
%   OutOfTolerance, Unaligned, Empty, EmptySynced, Unsupported... —, et
%   Match, vrai quand tous les signaux tiennent dans leur tolérance.
%   GETRESULTBYINDEX(D,K) rend le Simulink.sdi.DiffSignalResult du K-ième,
%   GETRESULTSBYNAME(D,NOM) ceux d'un nom.
%
%   Exemple :
%      a = timeseries((0:4)', 0:4, 'Name', 'x');
%      ra = Simulink.sdi.createRun('a', 'vars', a);
%      rb = Simulink.sdi.createRun('b', 'vars', a);
%      d = Simulink.sdi.compareRuns(ra, rb);
%      d.Summary.WithinTolerance          % 1
%      Simulink.sdi.clear;
%
%   Voir aussi SIMULINK.SDI.COMPARERUNS, SIMULINK.SDI.DIFFSIGNALRESULT.
    properties (SetAccess = private)
        RunID1 = 0
        RunID2 = 0
        Count = 0
        Summary = struct()
    end
    properties (Dependent)
        Match
    end
    properties (Hidden, SetAccess = private)
        Resultats = {}
    end
    methods
        function d = DiffRunResult(id1, id2, resultats)
            if nargin > 0
                d.RunID1 = id1;
                d.RunID2 = id2;
                d.Resultats = resultats;
                d.Count = numel(resultats);
                issues = {'WithinTolerance', 'OutOfTolerance', 'Unaligned', 'Empty', ...
                          'EmptySynced', 'UnitsMismatch', 'DataTypeMismatch', 'TimeMismatch', ...
                          'StartStop', 'Unsupported'};
                S = struct();
                for k = 1:numel(issues)
                    S.(issues{k}) = 0;
                end
                for k = 1:numel(resultats)
                    nom = char(resultats{k}.Status);
                    S.(nom) = S.(nom) + 1;
                end
                d.Summary = S;
            end
        end
        function v = get.Match(d)
            v = d.Summary.WithinTolerance == d.Count;
        end
        function r = getResultByIndex(d, k)
            if ~isnumeric(k) || ~isscalar(k) || k < 1 || k > d.Count || k ~= round(k)
                error('SDI:sdi:IndexOutOfRange', ...
                      'La comparaison porte %d resultat(s) : elle n''a pas de resultat %s.', ...
                      d.Count, strtrim(evalc('disp(k)')));
            end
            r = d.Resultats{k};
        end
        function r = getResultsByName(d, nom)
            r = [];
            for k = 1:d.Count
                if strcmp(d.Resultats{k}.Name, char(nom))
                    if isempty(r)
                        r = d.Resultats{k};
                    else
                        r(end + 1) = d.Resultats{k}; %#ok<AGROW>
                    end
                end
            end
        end
        function disp(d)
            fprintf('  Simulink.sdi.DiffRunResult : runs %d et %d, %d signal(aux)\n', ...
                    d.RunID1, d.RunID2, d.Count);
            for champ = fieldnames(d.Summary).'
                if d.Summary.(champ{1}) > 0
                    fprintf('    %s : %d\n', champ{1}, d.Summary.(champ{1}));
                end
            end
            fprintf('\n');
        end
    end
end
