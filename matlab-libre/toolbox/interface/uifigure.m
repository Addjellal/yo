function f = uifigure(titre, taille)
%UIFIGURE Fenêtre d'application.
%   F = UIFIGURE(TITRE,[LARGEUR HAUTEUR]) crée la fenêtre et rend sa
%   poignée. Les composants s'y posent ensuite avec UIBUTTON, UILABEL…
%
%   Exemple :
%      f = uifigure('Convertisseur', [320 200]);
    if nargin < 1, titre = 'Figure'; end
    if nargin < 2, taille = [560 420]; end
    id = matlibre_ui_creer('figure', 0);
    matlibre_ui_poser(id, 'Text', titre);
    matlibre_ui_poser(id, 'Position', [0 0 taille(1) taille(2)]);
    f = UIComposant(id);
end
