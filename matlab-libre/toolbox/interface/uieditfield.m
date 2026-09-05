function h = uieditfield(parent, varargin)
%UIEDITFIELD Champ de saisie.
%   H = UIEDITFIELD(PARENT,GENRE,'Value',V) où GENRE vaut 'text' ou
%   'numeric'.
%   H = UIEDITFIELD(PARENT,VALEUR,POSITION,GENRE) est la forme courte.
%
%   Un champ numérique n'accepte que des nombres : le genre décide, et
%   un texte donné à un champ numérique est converti. Un texte qui ne
%   désigne aucun nombre est refusé.
%
%   Exemples :
%      f = uifigure;
%      e = uieditfield(f, 'numeric', 'Value', 1.5);
%      e.Value
%
%   Voir aussi UIFIGURE, UISLIDER, UILABEL.
    id = matlibre_ui_creer('editfield', identifiantParent(parent));
    matlibre_ui_poser(id, 'Position', [10 10 100 22]);
    matlibre_ui_poser(id, 'Genre', 'text');
    matlibre_ui_poser(id, 'Value', '');
    reste = varargin;
    % « uieditfield(f, 'numeric', ...) » : le genre peut precéder les
    % couples nom-valeur, comme dans MATLAB.
    if ~isempty(reste) && (ischar(reste{1}) || isstring(reste{1})) && ...
            any(strcmpi(char(reste{1}), {'text', 'numeric'}))
        matlibre_ui_poser(id, 'Genre', lower(char(reste{1})));
        if strcmpi(char(reste{1}), 'numeric')
            matlibre_ui_poser(id, 'Value', 0);
        end
        reste = reste(2:end);
    end
    valeur = [];
    aValeur = false;
    if matlibre_ui_nomme(reste)
        matlibre_ui_appliquer(id, reste);
    else
        % Le genre arrive en quatrième position dans la forme courte : on
        % le pose avant la valeur, sans quoi un champ numérique garderait
        % le texte qu'on lui a donné au lieu du nombre qu'il désigne.
        if numel(reste) >= 3 && ~isempty(reste{3})
            matlibre_ui_poser(id, 'Genre', lower(char(reste{3})));
        end
        if numel(reste) >= 2 && ~isempty(reste{2})
            matlibre_ui_poser(id, 'Position', reste{2});
        end
        if numel(reste) >= 1 && ~isempty(reste{1})
            valeur = reste{1};
            aValeur = true;
        end
    end
    if ~aValeur
        valeur = matlibre_ui_lire(id, 'Value');
        aValeur = ~isempty(valeur);
    end
    if aValeur
        matlibre_ui_poser(id, 'Value', ...
                          convertir(valeur, matlibre_ui_lire(id, 'Genre')));
    end
    h = UIComposant(id);
end

function valeur = convertir(valeur, genre)
%CONVERTIR La valeur, ramenée au genre du champ.
    if strcmp(genre, 'numeric')
        if ischar(valeur) || isstring(valeur)
            nombre = str2double(char(valeur));
            if isnan(nombre)
                error('MATLAB:ui:NonNumerique', ...
                      '« %s » ne désigne pas un nombre.', char(valeur));
            end
            valeur = nombre;
        else
            valeur = double(valeur);
        end
    elseif isnumeric(valeur)
        valeur = num2str(valeur);
    end
end
