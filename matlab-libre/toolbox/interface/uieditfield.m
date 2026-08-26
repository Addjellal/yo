function h = uieditfield(parent, valeur, position, genre)
%UIEDITFIELD Champ de saisie, textuel ou numérique.
%   H = UIEDITFIELD(PARENT,VALEUR,[X Y L H]) crée un champ de texte.
%   H = UIEDITFIELD(...,'numeric') crée un champ numérique : Value est
%   alors un nombre.
    if nargin < 2, valeur = ''; end
    if nargin < 3, position = [10 10 140 24]; end
    if nargin < 4, genre = 'text'; end
    id = matlibre_ui_creer(['edit_' genre], identifiantParent(parent));
    matlibre_ui_poser(id, 'Position', position);
    if strcmpi(genre, 'numeric')
        if ischar(valeur) || isstring(valeur)
            valeur = str2double(valeur);
            if isnan(valeur), valeur = 0; end
        end
        matlibre_ui_poser(id, 'Value', valeur);
        matlibre_ui_poser(id, 'Text', num2str(valeur));
    else
        matlibre_ui_poser(id, 'Value', valeur);
        matlibre_ui_poser(id, 'Text', valeur);
    end
    h = UIComposant(id);
end
