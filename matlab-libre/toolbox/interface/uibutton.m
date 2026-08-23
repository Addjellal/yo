function b = uibutton(parent, texte, position, rappel)
%UIBUTTON Bouton poussoir.
%   B = UIBUTTON(PARENT,TEXTE,[X Y L H]) pose un bouton.
%   B = UIBUTTON(...,RAPPEL) lui donne son rappel, appelé avec (source,
%   evenement) comme dans MATLAB.
    if nargin < 2, texte = 'Bouton'; end
    if nargin < 3, position = [10 10 100 26]; end
    id = matlibre_ui_creer('button', identifiantParent(parent));
    matlibre_ui_poser(id, 'Text', texte);
    matlibre_ui_poser(id, 'Position', position);
    if nargin >= 4, matlibre_ui_poser(id, 'Callback', rappel); end
    b = UIComposant(id);
end
