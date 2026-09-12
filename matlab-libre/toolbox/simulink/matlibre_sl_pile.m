function sortie = matlibre_sl_pile(action, modele)
%MATLIBRE_SL_PILE Les états passés d'un modèle, pour défaire et refaire.
%   MATLIBRE_SL_PILE('poser',MODELE) retient l'état courant du modèle
%   avant qu'on le change.
%   MODELE = MATLIBRE_SL_PILE('annuler',MODELE) rend l'état d'avant le
%   dernier changement, et garde celui qu'on quitte pour pouvoir le
%   refaire.
%   MODELE = MATLIBRE_SL_PILE('refaire',MODELE) revient sur une annulation.
%   MATLIBRE_SL_PILE('vider',MODELE) oublie tout d'un modèle.
%   N = MATLIBRE_SL_PILE('profondeur',MODELE) dit combien d'annulations
%   restent possibles, et 'refaisables' combien de rétablissements.
%
%   Les états sont rangés par nom de modèle, et la pile vit aussi
%   longtemps que la session. Un modèle est une valeur : en retenir une
%   copie suffit, il n'y a pas de références à démêler.
%
%   Poser un état efface ce qu'on pouvait refaire : c'est la règle de
%   toute pile d'annulation, et l'ignorer laisserait rétablir un état qui
%   n'a plus de suite.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
%   dont l'annulation n'existe que dans l'éditeur.
%
%   Exemple :
%      m = add_block(new_system('essai'), 'gain', 'k', 'Gain', 1);
%      matlibre_sl_pile('vider', m);
%      matlibre_sl_pile('poser', m);
%      m = set_param(m, 'k', 'Gain', 5);
%      m = matlibre_sl_pile('annuler', m);
%      get_param(m, 'k', 'Gain')                % 1 : le changement est defait
%
%   Voir aussi SET_PARAM, ADD_BLOCK, DELETE_BLOCK, OPEN_SYSTEM.
    persistent noms passes futurs
    if isempty(noms)
        noms = {};
        passes = {};
        futurs = {};
    end
    if ~isstruct(modele) || ~isfield(modele, 'nom')
        error('simulink:pile:modele', ...
              'MATLIBRE_SL_PILE attend un modele bati par NEW_SYSTEM.');
    end
    nom = char(modele.nom);
    k = 0;
    for i = 1:numel(noms)
        if strcmp(noms{i}, nom)
            k = i;
        end
    end
    if k == 0
        noms{end + 1} = nom;
        passes{end + 1} = {};
        futurs{end + 1} = {};
        k = numel(noms);
    end
    sortie = [];
    switch lower(char(action))
        case 'poser'
            passes{k}{end + 1} = modele;
            % Un chemin neuf efface l'ancien futur : rétablir un état qui
            % n'a plus de suite n'aurait pas de sens.
            futurs{k} = {};
            % Cent états suffisent, et bornent ce que la session retient.
            if numel(passes{k}) > 100
                passes{k} = passes{k}(end - 99:end);
            end
        case 'annuler'
            if isempty(passes{k})
                sortie = modele;
                return
            end
            futurs{k}{end + 1} = modele;
            sortie = passes{k}{end};
            passes{k}(end) = [];
        case 'refaire'
            if isempty(futurs{k})
                sortie = modele;
                return
            end
            passes{k}{end + 1} = modele;
            sortie = futurs{k}{end};
            futurs{k}(end) = [];
        case 'vider'
            passes{k} = {};
            futurs{k} = {};
        case 'profondeur'
            sortie = numel(passes{k});
        case 'refaisables'
            sortie = numel(futurs{k});
        otherwise
            error('simulink:pile:action', 'Action inconnue : %s.', char(action));
    end
end
