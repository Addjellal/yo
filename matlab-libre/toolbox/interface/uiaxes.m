function h = uiaxes(parent, varargin)
%UIAXES Axes de tracé dans une fenêtre d'application.
%   H = UIAXES(PARENT,'Position',P) pose des axes.
%   H = UIAXES(PARENT,POSITION) est la forme courte.
%
%   Ce composant réserve la place des axes dans la fenêtre et la décrit
%   au registre d'interface. Le tracé lui-même passe par le moteur
%   graphique, qui est un système distinct dans MatLibre : PLOT dessine
%   donc dans la figure graphique courante, non dans ce composant. La
%   place est réservée, le dessin ne s'y rend pas encore.
%
%   Exemples :
%      f = uifigure;
%      a = uiaxes(f, 'Position', [20 20 300 200]);
%      a.Position
%
%   Voir aussi UIFIGURE, UIPANEL, PLOT.
    id = matlibre_ui_creer('axes', identifiantParent(parent));
    matlibre_ui_poser(id, 'Position', [10 10 300 200]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Position', varargin{1});
        end
    end
    h = UIComposant(id);
end
