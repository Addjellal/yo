function h = uicheckbox(parent, texte, valeur, position)
%UICHECKBOX Case à cocher.
    if nargin < 2, texte = 'Option'; end
    if nargin < 3, valeur = false; end
    if nargin < 4, position = [10 10 130 22]; end
    id = matlibre_ui_creer('checkbox', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', texte);
    matlibre_ui_poser(id, 'Value', logical(valeur));
    matlibre_ui_poser(id, 'Position', position);
    h = UIComposant(id);
end
