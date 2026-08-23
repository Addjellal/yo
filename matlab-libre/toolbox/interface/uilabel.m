function h = uilabel(parent, texte, position)
%UILABEL Étiquette de texte.
    if nargin < 2, texte = ''; end
    if nargin < 3, position = [10 10 100 22]; end
    id = matlibre_ui_creer('label', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', texte);
    matlibre_ui_poser(id, 'Position', position);
    h = UIComposant(id);
end
