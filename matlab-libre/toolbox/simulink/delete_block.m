function varargout = delete_block(modele, nom)
%DELETE_BLOCK Retire un bloc du modèle, et les liens qui y touchent.
%   MODELE = DELETE_BLOCK(MODELE,NOM) enlève le bloc nommé. Les liens qui
%   partaient de lui ou arrivaient à lui disparaissent avec lui : laisser
%   un lien vers un bloc absent rendrait le modèle insimulable.
%
%   Les blocs qui suivent sont renumérotés, puisque les liens désignent
%   les blocs par leur rang. C'est transparent : on désigne toujours un
%   bloc par son nom.
%
%   Comme ADD_BLOCK, la fonction rend un nouveau modèle et laisse
%   l'ancien intact : un modèle est ici une valeur, non une référence.
%   Dans MATLAB, DELETE_BLOCK modifie le modèle ouvert et ne rend rien.
%
%   DELETE_BLOCK(BLOC) est la forme de Simulink, sur un modèle chargé : BLOC
%   est un chemin 'modele/bloc', une poignée, ou plusieurs dans une cellule
%   ou un vecteur.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      m = add_line(m, 'c', 'g');
%      m = delete_block(m, 'g');
%      numel(m.blocs)                       % 1
%      isempty(m.liens)                     % le lien est parti avec le bloc
%
%   Voir aussi ADD_BLOCK, DELETE_LINE, REPLACE_BLOCK, FIND_SYSTEM.
    if nargin == 1
        retirerParNom(modele);
        return
    end
    varargout{1} = retirer(modele, nom);
end

function retirerParNom(designes)
    if iscell(designes)
        for k = 1:numel(designes)
            retirerParNom(designes{k});
        end
        return
    end
    if isnumeric(designes) && numel(designes) > 1
        for k = 1:numel(designes)
            retirerParNom(designes(k));
        end
        return
    end
    chemin = matlibre_sl_memoire('chemin', designes);
    [parent, feuille] = matlibre_sl_memoire('decouper', chemin);
    if isempty(parent)
        error('Simulink:Commands:DeleteBlockDiagram', ...
              ['''%s'' est un modele, non un bloc : BDCLOSE le decharge, ' ...
               'SIMULINK.BLOCKDIAGRAM.DELETECONTENTS le vide.'], chemin);
    end
    bloc = matlibre_sl_memoire('bloc', chemin);
    matlibre_sl_rappel('bloc', chemin, bloc, 'PreDeleteFcn');
    matlibre_sl_rappel('bloc', chemin, bloc, 'DeleteFcn');
    matlibre_sl_memoire('appliquer', parent, @(s) delete_block(s, feuille));
end

function modele = retirer(modele, nom)
    k = matlibre_sl_indice(modele, nom);
    modele.blocs(k) = [];
    if ~isempty(modele.liens)
        touche = modele.liens(:, 1) == k | modele.liens(:, 2) == k;
        modele.liens(touche, :) = [];
    end
    if ~isempty(modele.liens)
        % Les blocs situés après celui qu'on retire ont reculé d'un rang.
        apres = modele.liens(:, 1) > k;
        modele.liens(apres, 1) = modele.liens(apres, 1) - 1;
        apres = modele.liens(:, 2) > k;
        modele.liens(apres, 2) = modele.liens(apres, 2) - 1;
    end
    if isfield(modele, 'connexions') && ~isempty(modele.connexions)
        % ses connexions physiques partent avec lui
        touche = modele.connexions(:, 1) == k | modele.connexions(:, 3) == k;
        modele.connexions(touche, :) = [];
        for colonne = [1 3]
            apres = modele.connexions(:, colonne) > k;
            modele.connexions(apres, colonne) = modele.connexions(apres, colonne) - 1;
        end
    end
end
