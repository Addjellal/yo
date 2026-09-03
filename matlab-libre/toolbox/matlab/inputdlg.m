function reponses = inputdlg(invites, titre, lignes, defauts, options)
%INPUTDLG Demande des valeurs à l'utilisateur.
%   R = INPUTDLG(INVITES) pose une question par invite et rend les
%   réponses dans un tableau de cellules de chaînes. Une réponse vide
%   garde la valeur par défaut ; une interruption rend un tableau vide,
%   comme le bouton Annuler de MATLAB.
%
%   R = INPUTDLG(INVITES,TITRE,LIGNES,DEFAUTS) donne un titre, un nombre
%   de lignes par réponse — sans effet ici — et les valeurs proposées.
%
%   MatLibre pose les questions dans la console plutôt que dans une
%   fenêtre : l'interpréteur n'a pas de boucle d'événements modale, et
%   une fausse fenêtre qui rendrait la main aussitôt tromperait le
%   programme qui attend la réponse.
%
%   Exemple :
%      r = inputdlg({'Nom', 'Âge'}, 'Fiche', 1, {'', '30'});
%
%   Voir aussi INPUT, LISTDLG, UIEDITFIELD, KEYBOARD.
    if nargin < 1
        invites = {'Valeur :'};
    end
    if ischar(invites) || isstring(invites)
        invites = cellstr(invites);
    end
    invites = invites(:)';
    if nargin < 2 || isempty(titre)
        titre = '';
    end
    if nargin < 4 || isempty(defauts)
        defauts = repmat({''}, 1, numel(invites));
    end
    if ischar(defauts) || isstring(defauts)
        defauts = cellstr(defauts);
    end
    if numel(defauts) < numel(invites)
        defauts(end+1:numel(invites)) = {''};
    end
    if ~isempty(titre)
        fprintf('\n--- %s ---\n', char(titre));
    end
    reponses = cell(numel(invites), 1);
    for k = 1:numel(invites)
        invite = char(invites{k});
        defaut = char(defauts{k});
        if isempty(defaut)
            question = sprintf('%s ', invite);
        else
            question = sprintf('%s [%s] ', invite, defaut);
        end
        try
            reponse = input(question, 's');
        catch
            % Pas d'entrée disponible : c'est une annulation.
            reponses = {};
            return;
        end
        if isempty(reponse)
            reponse = defaut;
        end
        reponses{k} = reponse;
    end
end
