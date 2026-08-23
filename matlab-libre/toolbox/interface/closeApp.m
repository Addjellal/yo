function closeApp(f)
%CLOSEAPP Ferme une fenêtre d'application et tous ses composants.
    if isa(f, 'UIComposant')
        matlibre_ui_supprimer(f.Id);
    elseif isnumeric(f)
        matlibre_ui_supprimer(f);
    else
        matlibre_ui_supprimer(matlibre_ui_figure());
    end
end
