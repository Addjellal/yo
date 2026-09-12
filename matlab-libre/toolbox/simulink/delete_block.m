function modele = delete_block(modele, nom)
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
end
