classdef UIComposant < handle
%UICOMPOSANT Poignée vers un composant d'interface.
%   Un composant vit dans le registre de l'interpréteur ; cet objet n'en
%   porte que le numéro. La sémantique est donc celle de MATLAB : deux
%   copies de la poignée désignent le même bouton, et modifier l'une se
%   voit dans l'autre.
%
%   Propriétés lisibles et modifiables : Text, Value, Position, Items,
%   Limits, Enable, Visible, Callback. Type et Parent sont en lecture
%   seule.
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
        Text
        Value
        Position
        Items
        Limits
        Enable
        Visible
        Callback
    end
    methods
        function h = UIComposant(id)
            if nargin > 0
                h.Id = id;
            end
        end

        function v = get.Type(h),     v = matlibre_ui_lire(h.Id, 'Type'); end
        function v = get.Parent(h),   v = matlibre_ui_lire(h.Id, 'Parent'); end
        function v = get.Text(h),     v = matlibre_ui_lire(h.Id, 'Text'); end
        function v = get.Value(h),    v = matlibre_ui_lire(h.Id, 'Value'); end
        function v = get.Position(h), v = matlibre_ui_lire(h.Id, 'Position'); end
        function v = get.Items(h),    v = matlibre_ui_lire(h.Id, 'Items'); end
        function v = get.Limits(h),   v = matlibre_ui_lire(h.Id, 'Limits'); end
        function v = get.Enable(h),   v = matlibre_ui_lire(h.Id, 'Enable'); end
        function v = get.Visible(h),  v = matlibre_ui_lire(h.Id, 'Visible'); end
        function v = get.Callback(h), v = matlibre_ui_lire(h.Id, 'Callback'); end

        function set.Text(h, v),     matlibre_ui_poser(h.Id, 'Text', v); end
        function set.Value(h, v),    matlibre_ui_poser(h.Id, 'Value', v); end
        function set.Position(h, v), matlibre_ui_poser(h.Id, 'Position', v); end
        function set.Items(h, v),    matlibre_ui_poser(h.Id, 'Items', v); end
        function set.Limits(h, v),   matlibre_ui_poser(h.Id, 'Limits', v); end
        function set.Enable(h, v),   matlibre_ui_poser(h.Id, 'Enable', v); end
        function set.Visible(h, v),  matlibre_ui_poser(h.Id, 'Visible', v); end
        function set.Callback(h, v), matlibre_ui_poser(h.Id, 'Callback', v); end

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

        function disp(h)
            fprintf('  %s (#%d) « %s »\n', matlibre_ui_lire(h.Id, 'Type'), h.Id, ...
                    matlibre_ui_lire(h.Id, 'Text'));
        end
    end
end
