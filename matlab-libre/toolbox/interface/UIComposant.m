classdef UIComposant < handle
%UICOMPOSANT Poignée vers un composant d'interface.
%   Un composant vit dans le registre de l'interpréteur ; cet objet n'en
%   porte que le numéro. La sémantique est donc celle de MATLAB : deux
%   copies de la poignée désignent le même bouton, et modifier l'une se
%   voit dans l'autre.
%
%   Propriétés lisibles et modifiables : Text, Name, Title, Value,
%   Position, Items, Limits, Enable, Visible, Callback,
%   ButtonPushedFcn, ValueChangedFcn, Data, ColumnName. Type, Parent et
%   Children sont en lecture seule.
%
%   Name, Title et Text désignent le même texte : c'est le nom qu'en
%   donne MATLAB selon le composant — Name pour une fenêtre, Title pour
%   un panneau, Text pour le reste.
%
%   Poser une valeur hors des limites d'un curseur, ou hors des éléments
%   d'une liste, lève une erreur : un composant borné n'accepte pas ce
%   qu'il ne peut pas montrer.
%
%   Exemple :
%      f = uifigure('Essai', [300 200]);
%      b = uibutton(f, 'Cliquer', [20 20 100 30]);
%      b.Text = 'Encore';
%      b.Callback = @(source, evenement) disp('clic');
%
%   Voir aussi UIFIGURE, UIBUTTON, UILABEL, UISLIDER, UIDROPDOWN.
    properties
        Id = 0
    end
    properties (Dependent)
        Type
        Parent
        Children
        Text
        Name
        Title
        Value
        Position
        Items
        Limits
        Enable
        Visible
        Callback
        ButtonPushedFcn
        ValueChangedFcn
        Data
        ColumnName
    end
    methods
        function h = UIComposant(id)
            if nargin > 0
                h.Id = id;
            end
        end

        function v = get.Type(h),     v = matlibre_ui_lire(h.Id, 'Type'); end
        function v = get.Parent(h)
            % Le parent est rendu sous forme de poignée, comme dans
            % MATLAB : on peut donc l'interroger à son tour. Une fenêtre,
            % qui n'a pas de parent, rend un tableau vide.
            numero = matlibre_ui_lire(h.Id, 'Parent');
            if isempty(numero) || numero == 0
                v = UIComposant.empty(1, 0);
            else
                v = UIComposant(numero);
            end
        end
        function v = get.Text(h),     v = matlibre_ui_lire(h.Id, 'Text'); end
        function v = get.Value(h),    v = matlibre_ui_lire(h.Id, 'Value'); end
        function v = get.Position(h), v = matlibre_ui_lire(h.Id, 'Position'); end
        function v = get.Items(h),    v = matlibre_ui_lire(h.Id, 'Items'); end
        function v = get.Limits(h),   v = matlibre_ui_lire(h.Id, 'Limits'); end
        function v = get.Enable(h),   v = matlibre_ui_lire(h.Id, 'Enable'); end
        function v = get.Visible(h),  v = matlibre_ui_lire(h.Id, 'Visible'); end
        function v = get.Callback(h), v = matlibre_ui_lire(h.Id, 'Callback'); end
        function v = get.Name(h),     v = matlibre_ui_lire(h.Id, 'Text'); end
        function v = get.Title(h),    v = matlibre_ui_lire(h.Id, 'Text'); end
        function v = get.ButtonPushedFcn(h), v = matlibre_ui_lire(h.Id, 'Callback'); end
        function v = get.ValueChangedFcn(h), v = matlibre_ui_lire(h.Id, 'Callback'); end
        function v = get.Data(h),       v = matlibre_ui_lire(h.Id, 'Data'); end
        function v = get.ColumnName(h), v = matlibre_ui_lire(h.Id, 'ColumnName'); end
        function v = get.Children(h)
            numeros = matlibre_ui_enfants(h.Id);
            v = UIComposant.empty(1, 0);
            for k = 1:numel(numeros)
                v(k) = UIComposant(numeros(k));   %#ok<AGROW>
            end
        end

        function set.Text(h, v),     matlibre_ui_poser(h.Id, 'Text', v); end
        function set.Value(h, v)
            % Un curseur borne sa valeur, une liste n'accepte que ses
            % éléments : le composant refuse ce qu'il ne peut pas montrer,
            % plutôt que de le stocker en silence.
            genre = matlibre_ui_lire(h.Id, 'Type');
            if strcmp(genre, 'slider')
                bornes = matlibre_ui_lire(h.Id, 'Limits');
                if ~isempty(bornes) && isnumeric(v) && isscalar(v) && ...
                        (v < bornes(1) || v > bornes(2))
                    error('MATLAB:ui:HorsLimites', ...
                          'La valeur %g sort des limites [%g %g].', ...
                          v, bornes(1), bornes(2));
                end
            elseif strcmp(genre, 'dropdown')
                items = matlibre_ui_lire(h.Id, 'Items');
                if ~isempty(items) && (ischar(v) || isstring(v)) && ...
                        ~any(strcmp(char(v), items))
                    error('MATLAB:ui:HorsListe', ...
                          '« %s » ne fait pas partie des éléments de la liste.', ...
                          char(v));
                end
            end
            matlibre_ui_poser(h.Id, 'Value', v);
        end
        function set.Position(h, v), matlibre_ui_poser(h.Id, 'Position', v); end
        function set.Items(h, v),    matlibre_ui_poser(h.Id, 'Items', v); end
        function set.Limits(h, v),   matlibre_ui_poser(h.Id, 'Limits', v); end
        function set.Enable(h, v),   matlibre_ui_poser(h.Id, 'Enable', v); end
        function set.Visible(h, v),  matlibre_ui_poser(h.Id, 'Visible', v); end
        function set.Callback(h, v), matlibre_ui_poser(h.Id, 'Callback', v); end
        function set.Name(h, v),     matlibre_ui_poser(h.Id, 'Text', v); end
        function set.Title(h, v),    matlibre_ui_poser(h.Id, 'Text', v); end
        function set.ButtonPushedFcn(h, v), matlibre_ui_poser(h.Id, 'Callback', v); end
        function set.ValueChangedFcn(h, v), matlibre_ui_poser(h.Id, 'Callback', v); end
        function set.Data(h, v),       matlibre_ui_poser(h.Id, 'Data', v); end
        function set.ColumnName(h, v), matlibre_ui_poser(h.Id, 'ColumnName', v); end

        function delete(h)
            matlibre_ui_supprimer(h.Id);
        end

        function declencher(h, valeur)
            %DECLENCHER Appelle le rappel du composant, comme le ferait un clic.
            if nargin > 1
                matlibre_ui_declencher(h.Id, valeur);
            else
                matlibre_ui_declencher(h.Id);
            end
        end

        function r = eq(a, b)
        %EQ Deux poignées désignent-elles le même composant ?
            if isa(a, 'UIComposant') && isa(b, 'UIComposant')
                r = a.Id == b.Id;
            else
                r = false;
            end
        end

        function r = isequal(a, b)
            r = eq(a, b);
        end

        function disp(h)
            fprintf('  %s (#%d) « %s »\n', matlibre_ui_lire(h.Id, 'Type'), h.Id, ...
                    matlibre_ui_lire(h.Id, 'Text'));
        end
    end
end
