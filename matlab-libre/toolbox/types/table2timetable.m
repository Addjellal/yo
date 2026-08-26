function tt = table2timetable(t, varargin)
%TABLE2TIMETABLE Convertit une table en timetable.
%   TT = TABLE2TIMETABLE(T) utilise la première variable datetime ou
%   duration comme axe de temps. TABLE2TIMETABLE(T,'RowTimes',T0) impose
%   un autre vecteur d'instants.
    temps = [];
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'RowTimes'), temps = varargin{k + 1}; end
    end
    noms = t.Properties.VariableNames;
    garde = true(1, numel(noms));
    if isempty(temps)
        for k = 1:numel(noms)
            v = t.(noms{k});
            if isa(v, 'datetime') || isa(v, 'duration')
                temps = v; garde(k) = false; break
            end
        end
    elseif ischar(temps) || isstring(temps)
        k = find(strcmp(char(temps), noms), 1);
        temps = t.(noms{k}); garde(k) = false;
    end
    if isempty(temps)
        error('MATLAB:table2timetable:NoTimeVariable', ...
              'The table has no datetime or duration variable to use as row times.');
    end
    colonnes = {};
    restants = {};
    for k = 1:numel(noms)
        if garde(k)
            colonnes{end + 1} = t.(noms{k}); %#ok<AGROW>
            restants{end + 1} = noms{k};     %#ok<AGROW>
        end
    end
    tt = timetable(temps, colonnes{:}, 'VariableNames', restants);
end
