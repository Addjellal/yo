function h = uibutton(parent, varargin)
%UIBUTTON Bouton qui déclenche une action.
%   H = UIBUTTON(PARENT,'Text',TEXTE,'ButtonPushedFcn',F) pose un bouton
%   et son rappel.
%   H = UIBUTTON(PARENT,TEXTE,POSITION,RAPPEL) est la forme courte.
%
%   Le rappel reçoit deux arguments, la source et l'événement, comme dans
%   MATLAB : c'est ce qui permet à une même fonction de servir plusieurs
%   boutons, en lisant la source pour savoir lequel a été pressé.
%
%   Exemples :
%      f = uifigure;
%      b = uibutton(f, 'Text', 'Appliquer', 'Position', [20 20 100 30], ...
%                   'ButtonPushedFcn', @(s, e) disp('clic'));
%      declencher(b);
%
%   Voir aussi UIFIGURE, UILABEL, UISLIDER, UICHECKBOX.
    id = matlibre_ui_creer('button', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', 'Bouton');
    matlibre_ui_poser(id, 'Position', [10 10 100 30]);
    matlibre_ui_poser(id, 'Callback', []);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Text', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            matlibre_ui_poser(id, 'Position', varargin{2});
        end
        if numel(varargin) >= 3 && ~isempty(varargin{3})
            matlibre_ui_poser(id, 'Callback', varargin{3});
        end
    end
    h = UIComposant(id);
end
