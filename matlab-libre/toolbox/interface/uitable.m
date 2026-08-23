function h = uitable(parent, donnees, position)
%UITABLE Table de valeurs.
    if nargin < 2, donnees = []; end
    if nargin < 3, position = [10 10 240 140]; end
    id = matlibre_ui_creer('table', identifiantParent(parent));
    matlibre_ui_poser(id, 'Value', donnees);
    matlibre_ui_poser(id, 'Position', position);
    h = UIComposant(id);
end
