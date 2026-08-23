function h = uidropdown(parent, items, position, valeur)
%UIDROPDOWN Liste déroulante.
%   H = UIDROPDOWN(PARENT,{'un','deux'},[X Y L H]) ; Value est le texte
%   choisi, comme dans MATLAB.
    if nargin < 2, items = {}; end
    if nargin < 3, position = [10 10 130 24]; end
    id = matlibre_ui_creer('dropdown', identifiantParent(parent));
    matlibre_ui_poser(id, 'Items', items);
    matlibre_ui_poser(id, 'Position', position);
    if nargin < 4
        if isempty(items), valeur = ''; else, valeur = items{1}; end
    end
    matlibre_ui_poser(id, 'Value', valeur);
    h = UIComposant(id);
end
