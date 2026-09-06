function closeApp(f)
%CLOSEAPP Ferme une fenêtre d'application et tous ses composants.
%   CLOSEAPP(F) supprime la fenêtre et, avec elle, l'arbre entier de ses
%   composants. F est une UIComposant ou un identifiant numérique.
%
%   Supprimer les enfants avec le parent est ce qui évite les composants
%   orphelins : le registre d'interface les garderait sinon indéfiniment,
%   et leurs rappels resteraient déclenchables.
%
%   Exemple :
%      f = uifigure('Name', 'essai');
%      uibutton(f, 'Text', 'ok');
%      closeApp(f);
%
%   Voir aussi UIFIGURE, UIBUTTON, UIRESUME.
    if isa(f, 'UIComposant')
        matlibre_ui_supprimer(f.Id);
    elseif isnumeric(f)
        matlibre_ui_supprimer(f);
    else
        matlibre_ui_supprimer(matlibre_ui_figure());
    end
end
