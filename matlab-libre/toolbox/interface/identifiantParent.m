function id = identifiantParent(parent)
%IDENTIFIANTPARENT Numéro du composant parent, quelle qu'en soit la forme.
%   Accepte une poignée UIComposant, un numéro, ou rien : la fenêtre
%   courante sert alors de parent.
%
%   Exemple :
%      f = uifigure();
%      identifiantParent(f) == identifiantParent(f)      % 1
    if nargin < 1 || isempty(parent)
        id = matlibre_ui_figure();
    elseif isa(parent, 'UIComposant')
        id = parent.Id;
    elseif isnumeric(parent)
        id = parent;
    else
        error('MATLAB:ui:InvalidParent', 'Invalid parent for a UI component.');
    end
end
