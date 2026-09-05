function h = uilabel(parent, varargin)
%UILABEL Étiquette de texte.
%   H = UILABEL(PARENT,'Text',TEXTE,'Position',P) pose une étiquette.
%   H = UILABEL(PARENT,TEXTE,POSITION) est la forme courte.
%
%   Une étiquette ne réagit à rien : elle nomme ce qui est à côté. C'est
%   le seul composant qui n'a ni valeur ni rappel.
%
%   Exemples :
%      f = uifigure;
%      uilabel(f, 'Text', 'Amplitude', 'Position', [20 100 100 22]);
%      uilabel(f, 'Amplitude', [20 100 100 22]);
%
%   Voir aussi UIFIGURE, UIBUTTON, UIEDITFIELD.
    id = matlibre_ui_creer('label', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', '');
    matlibre_ui_poser(id, 'Position', [10 10 100 22]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Text', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            matlibre_ui_poser(id, 'Position', varargin{2});
        end
    end
    h = UIComposant(id);
end
