function h = uislider(parent, limites, valeur, position)
%UISLIDER Curseur.
%   H = UISLIDER(PARENT,[MIN MAX],VALEUR,[X Y L H]).
    if nargin < 2, limites = [0 100]; end
    if nargin < 3, valeur = limites(1); end
    if nargin < 4, position = [10 10 150 30]; end
    id = matlibre_ui_creer('slider', identifiantParent(parent));
    matlibre_ui_poser(id, 'Limits', limites);
    matlibre_ui_poser(id, 'Value', valeur);
    matlibre_ui_poser(id, 'Position', position);
    h = UIComposant(id);
end
