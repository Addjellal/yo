classdef LookupTable < handle
%LOOKUPTABLE Une table d'interpolation : ses valeurs et ses points de rupture.
%   LUT = SIMULINK.LOOKUPTABLE ; LUT.Table.Value porte les valeurs,
%   LUT.Breakpoints(K) les points de rupture de la dimension K. Un bloc
%   n-D Lookup Table le désigne par son nom (DataSpecification 'Lookup
%   table object', LookupTableObject), un bloc Interpolation Using
%   Prelookup aussi (TableSpecification 'Lookup table object').
%
%   BreakpointsSpecification dit comment sont donnés les points :
%      'Explicit values'  des Simulink.lookuptable.Breakpoint, par Value ;
%      'Even spacing'     des Simulink.lookuptable.Evenspacing, par
%                         FirstPoint et Spacing, leur nombre étant celui
%                         des éléments de la table sur la dimension ;
%      'Reference'        les noms de Simulink.Breakpoint, une cellule de
%                         textes, lus là où le bloc lit ses variables.
%   Changer la spécification remplace les points par ceux de la nouvelle,
%   un par dimension.
%
%   C'est un objet poignée, comme dans Simulink ; COPY en fait un autre.
%
%   Exemple :
%      lut = Simulink.LookupTable;
%      lut.Table.Value = [1 2 3; 4 5 6];
%      lut.Breakpoints(1).Value = [0 1];
%      lut.Breakpoints(2).Value = [10 20 30];
%      numel(lut.Breakpoints)             % 2
%      lut.BreakpointsSpecification = 'Even spacing';
%      class(lut.Breakpoints)             % 'Simulink.lookuptable.Evenspacing'
%
%   Voir aussi SIMULINK.BREAKPOINT, SIMULINK.LOOKUPTABLE.TABLE.
    properties
        Table
        Breakpoints
        BreakpointsSpecification = 'Explicit values'
        StructTypeInfo = struct('Name', '', 'DataScope', 'Auto', 'HeaderFileName', '')
        SupportTunableSize = false
        Description = ''
        CoderInfo = []
    end
    methods
        function lut = LookupTable()
            lut.Table = Simulink.lookuptable.Table;
            lut.Breakpoints = Simulink.lookuptable.Breakpoint;
            lut.CoderInfo = Simulink.CoderInfo;
        end
        function set.Table(lut, v)
            if ~isa(v, 'Simulink.lookuptable.Table') || numel(v) ~= 1
                error('Simulink:Data:LookupTableInvalidValue', ...
                      'Table porte un Simulink.lookuptable.Table ; pas %s.', class(v));
            end
            lut.Table = v;
        end
        function set.Breakpoints(lut, v)
            switch lut.BreakpointsSpecification
                case 'Explicit values'
                    attendu = 'Simulink.lookuptable.Breakpoint';
                    bon = isa(v, attendu);
                case 'Even spacing'
                    attendu = 'Simulink.lookuptable.Evenspacing';
                    bon = isa(v, attendu);
                otherwise
                    attendu = 'une cellule de noms de Simulink.Breakpoint';
                    if ischar(v)
                        v = {v};
                    end
                    bon = iscellstr(v);
            end
            if ~bon
                error('Simulink:Data:LookupTableInvalidBreakpoints', ...
                      ['Avec BreakpointsSpecification ''%s'', Breakpoints porte %s ; ' ...
                       'pas %s.'], lut.BreakpointsSpecification, attendu, class(v));
            end
            if numel(v) > 30
                error('Simulink:Data:LookupTableInvalidBreakpoints', ...
                      'Une table a au plus trente dimensions.');
            end
            lut.Breakpoints = v(:).';
        end
        function set.BreakpointsSpecification(lut, v)
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            choix = {'Explicit values', 'Even spacing', 'Reference'};
            k = [];
            if ischar(v)
                k = find(strcmpi(v, choix), 1);
            end
            if isempty(k)
                error('Simulink:Data:LookupTableInvalidSpecification', ...
                      ['BreakpointsSpecification vaut ''Explicit values'', ''Even spacing'' ' ...
                       'ou ''Reference''.']);
            end
            v = choix{k};
            if strcmp(v, lut.BreakpointsSpecification)
                return
            end
            % les points prennent la forme de la nouvelle spécification,
            % autant qu'il y avait de dimensions
            n = max(1, numel(lut.Breakpoints));
            lut.BreakpointsSpecification = v;
            switch v
                case 'Explicit values'
                    neufs = repmat(Simulink.lookuptable.Breakpoint, 1, n);
                case 'Even spacing'
                    neufs = repmat(Simulink.lookuptable.Evenspacing, 1, n);
                otherwise
                    neufs = repmat({''}, 1, n);
            end
            lut.Breakpoints = neufs;
        end
        function c = copy(lut)
            c = Simulink.LookupTable;
            c.Table = lut.Table;
            c.BreakpointsSpecification = lut.BreakpointsSpecification;
            c.Breakpoints = lut.Breakpoints;
            c.StructTypeInfo = lut.StructTypeInfo;
            c.SupportTunableSize = lut.SupportTunableSize;
            c.Description = lut.Description;
        end
        function disp(lut)
            t = lut.Table;
            fprintf('  Simulink.LookupTable : table %s, %d dimension(s), %s\n\n', ...
                    mat2str(size(t.Value)), numel(lut.Breakpoints), lut.BreakpointsSpecification);
        end
    end
end
