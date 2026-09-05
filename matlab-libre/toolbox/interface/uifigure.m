function f = uifigure(varargin)
%UIFIGURE Fenêtre d'application.
%   F = UIFIGURE crée une fenêtre par défaut.
%   F = UIFIGURE('Name',NOM,'Position',[X Y L H],...) la règle par
%   couples nom-valeur, comme dans MATLAB.
%   F = UIFIGURE(TITRE,[LARGEUR HAUTEUR]) est la forme courte de
%   MatLibre : le titre puis la taille.
%
%   Les composants s'y posent ensuite avec UIBUTTON, UILABEL, UISLIDER…
%   La fenêtre est leur parent, et la fermer les emporte.
%
%   Exemples :
%      f = uifigure('Name', 'Convertisseur', 'Position', [100 100 320 200]);
%      f = uifigure('Convertisseur', [320 200]);
%
%   Voir aussi UIBUTTON, UILABEL, UISLIDER, UIPANEL, CLOSEAPP.
    id = matlibre_ui_creer('figure', 0);
    matlibre_ui_poser(id, 'Text', 'Figure');
    matlibre_ui_poser(id, 'Position', [0 0 560 420]);
    if matlibre_ui_nomme(varargin)
        matlibre_ui_appliquer(id, varargin);
    else
        if numel(varargin) >= 1 && ~isempty(varargin{1})
            matlibre_ui_poser(id, 'Text', varargin{1});
        end
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            taille = double(varargin{2});
            if numel(taille) == 2
                taille = [0 0 taille(1) taille(2)];
            end
            matlibre_ui_poser(id, 'Position', taille);
        end
    end
    f = UIComposant(id);
end
