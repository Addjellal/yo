function estNomme = matlibre_ui_nomme(arguments)
%MATLIBRE_UI_NOMME Les arguments sont-ils des couples nom-valeur ?
%   Un constructeur d'interface accepte deux écritures : la forme
%   positionnelle de MatLibre, plus courte, et la forme nom-valeur de
%   MATLAB. On les distingue au premier argument : un nom de propriété
%   connu ouvre la seconde.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi MATLIBRE_UI_APPLIQUER.
    estNomme = false;
    if isempty(arguments)
        return
    end
    premier = arguments{1};
    if ~(ischar(premier) || isstring(premier)) || ~isscalar(string(premier))
        return
    end
    connus = {'Text', 'Title', 'Name', 'Label', 'Position', 'Value', ...
              'Items', 'Limits', 'Enable', 'Visible', 'Callback', ...
              'ButtonPushedFcn', 'ValueChangedFcn', 'Data', 'ColumnName', ...
              'ColumnWidth', 'RowName', 'FontSize', 'FontWeight', ...
              'BackgroundColor', 'ForegroundColor', 'Tooltip', 'Tag', ...
              'HorizontalAlignment', 'Editable', 'Multiselect'};
    estNomme = any(strcmpi(char(premier), connus));
end
