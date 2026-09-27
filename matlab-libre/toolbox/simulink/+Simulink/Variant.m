classdef Variant
%VARIANT Une condition qui active une variante.
%   V = SIMULINK.VARIANT(CONDITION) range une condition — 'Mode == 1',
%   'Moteur == 2 && Frein' — écrite sur les variables de l'espace de
%   travail de base. Rangé sous un nom — MoteurThermique —, l'objet se
%   donne comme VariantControl à une variante d'un sous-système à
%   variantes, ou dans les VariantControls d'un Variant Source ou d'un
%   Variant Sink : la variante est active quand sa condition est vraie au
%   moment de simuler.
%
%   Exemple :
%      Mode = 1;
%      V1 = Simulink.Variant('Mode == 1');
%      V1.Condition                       % 'Mode == 1'
%
%   Voir aussi ADD_BLOCK, SIM, SIMULINK.PARAMETER.
    properties
        Condition = ''
    end
    methods
        function obj = Variant(condition)
            if nargin > 0
                obj.Condition = condition;
            end
        end
        function obj = set.Condition(obj, texte)
            if isstring(texte) && isscalar(texte)
                texte = char(texte);
            end
            if ~(ischar(texte) && (isempty(texte) || isrow(texte)))
                error('Simulink:Variants:InvalidCondition', ...
                      ['La condition d''un Simulink.Variant est un texte : ''Mode == 1'', ' ...
                       'par exemple.']);
            end
            obj.Condition = texte;
        end
    end
end
