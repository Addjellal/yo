function h = uitable(parent, varargin)
%UITABLE Tableau de données.
%   H = UITABLE(PARENT,'Data',D,'ColumnName',N) pose un tableau.
%   H = UITABLE(PARENT,DONNEES,POSITION) est la forme courte.
%
%   Les données se remplacent d'un bloc : écrire dans H.Data change tout
%   le tableau, ce qui évite d'avoir à suivre chaque case.
%
%   Exemples :
%      f = uifigure;
%      t = uitable(f, 'Data', magic(4), 'ColumnName', {'a','b','c','d'});
%      t.Data(1, 1)
%
%   Voir aussi UIFIGURE, UIPANEL, UIAXES.
    id = matlibre_ui_creer('table', identifiantParent(parent));
    matlibre_ui_poser(id, 'Data', []);
    matlibre_ui_poser(id, 'Position', [10 10 300 120]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Data', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            matlibre_ui_poser(id, 'Position', varargin{2});
        end
    end
    h = UIComposant(id);
end
