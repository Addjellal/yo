function h = uipanel(parent, titre, position)
%UIPANEL Panneau, qui regroupe d'autres composants.
    if nargin < 2, titre = ''; end
    if nargin < 3, position = [10 10 200 140]; end
    id = matlibre_ui_creer('panel', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', titre);
    matlibre_ui_poser(id, 'Position', position);
    h = UIComposant(id);
end
