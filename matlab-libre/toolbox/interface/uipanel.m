function h = uipanel(parent, varargin)
%UIPANEL Panneau qui groupe des composants.
%   H = UIPANEL(PARENT,'Title',TITRE,'Position',P) pose un panneau.
%   H = UIPANEL(PARENT,TITRE,POSITION) est la forme courte.
%
%   Un panneau devient le parent de ce qu'on y pose : le déplacer déplace
%   tout son contenu, et le fermer l'emporte.
%
%   Exemples :
%      f = uifigure;
%      p = uipanel(f, 'Title', 'Options', 'Position', [20 20 200 150]);
%      uicheckbox(p, 'Text', 'Journaliser');
%      numel(p.Children)
%
%   Voir aussi UIFIGURE, UITABLE, UIAXES.
    id = matlibre_ui_creer('panel', identifiantParent(parent));
    matlibre_ui_poser(id, 'Title', '');
    matlibre_ui_poser(id, 'Position', [10 10 200 150]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Title', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            matlibre_ui_poser(id, 'Position', varargin{2});
        end
    end
    h = UIComposant(id);
end
