function h = uiaxes(parent, position)
%UIAXES Zone de tracé dans une application.
%   Le tracé se fait avec les fonctions graphiques ordinaires ; l'interface
%   affiche la figure courante dans la zone réservée.
    if nargin < 2, position = [10 10 260 180]; end
    id = matlibre_ui_creer('axes', identifiantParent(parent));
    matlibre_ui_poser(id, 'Position', position);
    h = UIComposant(id);
end
