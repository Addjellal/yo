classdef Breakpoint < handle
%BREAKPOINT Un jeu de points de rupture, partagé entre des tables.
%   BP = SIMULINK.BREAKPOINT ; BP.Breakpoints.Value porte les points de
%   rupture, un Simulink.lookuptable.Breakpoint. Un bloc Prelookup le
%   désigne par son nom (BreakpointsSpecification 'Breakpoint object',
%   BreakpointObject), un Simulink.LookupTable aussi (BreakpointsSpecification
%   'Reference') : changer les points ici les change partout.
%
%   C'est un objet poignée, comme dans Simulink ; COPY en fait un autre.
%
%   Exemple :
%      bp = Simulink.Breakpoint;
%      bp.Breakpoints.Value = [0 10 20];
%      autre = copy(bp);
%      autre.Breakpoints.Value = [0 1];
%      bp.Breakpoints.Value               % [0 10 20]
%
%   Voir aussi SIMULINK.LOOKUPTABLE, SIMULINK.LOOKUPTABLE.BREAKPOINT.
    properties
        Breakpoints
        SupportTunableSize = false
        Description = ''
        CoderInfo = []
    end
    methods
        function bp = Breakpoint()
            bp.Breakpoints = Simulink.lookuptable.Breakpoint;
            bp.CoderInfo = Simulink.CoderInfo;
        end
        function set.Breakpoints(bp, v)
            if ~isa(v, 'Simulink.lookuptable.Breakpoint') || numel(v) ~= 1
                error('Simulink:Data:BreakpointInvalidValue', ...
                      ['Breakpoints porte un Simulink.lookuptable.Breakpoint, un seul ; ' ...
                       'pas %s.'], class(v));
            end
            bp.Breakpoints = v;
        end
        function c = copy(bp)
            c = Simulink.Breakpoint;
            c.Breakpoints = bp.Breakpoints;
            c.SupportTunableSize = bp.SupportTunableSize;
            c.Description = bp.Description;
        end
        function disp(bp)
            b = bp.Breakpoints;
            fprintf('  Simulink.Breakpoint : %d point(s) de rupture %s\n\n', numel(b.Value), ...
                    mat2str(b.Value(:).', 6));
        end
    end
end
