function h = uislider(parent, varargin)
%UISLIDER Curseur.
%   H = UISLIDER(PARENT,'Limits',[MIN MAX],'Value',V) pose un curseur.
%   H = UISLIDER(PARENT,LIMITES,VALEUR,POSITION) est la forme courte.
%
%   Un curseur borne sa valeur : lui en donner une hors des limites lève
%   une erreur au lieu de l'accepter. C'est ce qui le distingue d'une
%   simple variable, et ce qui rend inutile de vérifier après coup.
%
%   Exemples :
%      f = uifigure;
%      s = uislider(f, 'Limits', [0 10], 'Value', 3);
%      s.Value = 7;
%
%   Voir aussi UIFIGURE, UIEDITFIELD, UICHECKBOX.
    id = matlibre_ui_creer('slider', identifiantParent(parent));
    matlibre_ui_poser(id, 'Limits', [0 1]);
    matlibre_ui_poser(id, 'Value', 0);
    matlibre_ui_poser(id, 'Position', [10 10 150 3]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Limits', varargin{1});
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
