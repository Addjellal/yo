function h = uicheckbox(parent, varargin)
%UICHECKBOX Case à cocher.
%   H = UICHECKBOX(PARENT,'Text',TEXTE,'Value',V) pose une case.
%   H = UICHECKBOX(PARENT,TEXTE,VALEUR,POSITION) est la forme courte.
%
%   Sa valeur est un booléen : vraie quand la case est cochée.
%
%   Exemples :
%      f = uifigure;
%      c = uicheckbox(f, 'Text', 'Actif', 'Value', true);
%      c.Value
%
%   Voir aussi UIFIGURE, UIDROPDOWN, UISLIDER.
    id = matlibre_ui_creer('checkbox', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', '');
    matlibre_ui_poser(id, 'Value', false);
    matlibre_ui_poser(id, 'Position', [10 10 120 22]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Text', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            matlibre_ui_poser(id, 'Value', varargin{2});
        end
        if numel(varargin) >= 3 && ~isempty(varargin{3})
            matlibre_ui_poser(id, 'Position', varargin{3});
        end
    end
    h = UIComposant(id);
end
