function app = appCompteur()
%APPCOMPTEUR Petite application : un bouton qui incrémente une étiquette.
    f = uifigure('Compteur', [300 160]);
    etiquette = uilabel(f, '0', [20 100 200 22]);
    bouton = uibutton(f, 'Incrementer', [20 40 140 28]);
    curseur = uislider(f, [0 10], 1, [180 40 100 30]);
    compteur = 0;
    bouton.Callback = @(source, evenement) incrementer();
    app = struct('figure', f, 'etiquette', etiquette, 'bouton', bouton, ...
                 'curseur', curseur);
    function incrementer()
        compteur = compteur + curseur.Value;
        etiquette.Text = sprintf('%g', compteur);
    end
end
