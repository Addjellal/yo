classdef Evenspacing
%EVENSPACING Des points de rupture régulièrement espacés.
%   E = SIMULINK.LOOKUPTABLE.EVENSPACING ; les points valent FirstPoint,
%   FirstPoint + Spacing, ..., autant que la table a d'éléments sur cette
%   dimension. Spacing est strictement positif. DataType, Unit,
%   FirstPointName, SpacingName et Description les décrivent.
%
%   Exemple :
%      e = Simulink.lookuptable.Evenspacing;
%      e.FirstPoint = -1;
%      e.Spacing = 0.5;
%
%   Voir aussi SIMULINK.LOOKUPTABLE, SIMULINK.LOOKUPTABLE.BREAKPOINT.
    properties
        FirstPoint = 0
        Spacing = 1
        DataType = 'auto'
        Unit = ''
        FirstPointName = 'FirstPoint'
        SpacingName = 'Spacing'
        Description = ''
    end
    methods
        function e = set.FirstPoint(e, v)
            if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v)
                error('Simulink:Data:EvenSpacingInvalidValue', ...
                      'FirstPoint est un nombre reel fini.');
            end
            e.FirstPoint = v;
        end
        function e = set.Spacing(e, v)
            if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v <= 0
                error('Simulink:Data:EvenSpacingInvalidValue', ...
                      'Spacing est un nombre reel fini, strictement positif.');
            end
            e.Spacing = v;
        end
    end
end
