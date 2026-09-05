function h = uidropdown(parent, varargin)
%UIDROPDOWN Liste déroulante.
%   H = UIDROPDOWN(PARENT,'Items',LISTE,'Value',V) pose une liste.
%   H = UIDROPDOWN(PARENT,ITEMS,POSITION,VALEUR) est la forme courte.
%
%   La valeur d'une liste est l'un de ses éléments : lui en donner un
%   autre lève une erreur. C'est ce qui garantit qu'une application ne se
%   retrouve jamais devant un choix qu'elle n'a pas prévu.
%
%   Exemples :
%      f = uifigure;
%      d = uidropdown(f, 'Items', {'sinus', 'carre'}, 'Value', 'carre');
%      d.Value
%
%   Voir aussi UIFIGURE, UICHECKBOX, UISLIDER.
    id = matlibre_ui_creer('dropdown', identifiantParent(parent));
    matlibre_ui_poser(id, 'Items', {});
    matlibre_ui_poser(id, 'Position', [10 10 120 22]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Items', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            matlibre_ui_poser(id, 'Position', varargin{2});
        end
        if numel(varargin) >= 3 && ~isempty(varargin{3})
            matlibre_ui_poser(id, 'Value', varargin{3});
        end
    end
    % Sans choix explicite, c'est le premier element qui vaut.
    items = matlibre_ui_lire(id, 'Items');
    valeur = matlibre_ui_lire(id, 'Value');
    if isempty(valeur) && ~isempty(items)
        matlibre_ui_poser(id, 'Value', items{1});
    end
    h = UIComposant(id);
end
