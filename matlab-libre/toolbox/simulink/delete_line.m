function modele = delete_line(modele, source, destination, entree)
%DELETE_LINE Supprime le lien qui va d'un bloc à un autre.
%   MODELE = DELETE_LINE(MODELE,SOURCE,DESTINATION) supprime le lien
%   allant de la sortie du premier bloc à l'entrée du second.
%   DELETE_LINE(MODELE,SOURCE,DESTINATION,NUMERO) précise laquelle des
%   entrées, quand plusieurs liens joignent les deux mêmes blocs.
%
%   Un lien qui n'existe pas lève une erreur qui nomme les deux blocs,
%   plutôt que de laisser croire à une suppression qui n'a pas eu lieu.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      m = add_line(m, 'c', 'g');
%      m = delete_line(m, 'c', 'g');
%      isempty(m.liens)                 % vrai
%
%   Voir aussi ADD_LINE, DELETE_BLOCK, NEW_SYSTEM.
    a = matlibre_sl_indice(modele, source);
    b = matlibre_sl_indice(modele, destination);
    if isempty(modele.liens)
        candidats = [];
    else
        candidats = find(modele.liens(:, 1) == a & modele.liens(:, 2) == b);
        if nargin >= 4
            candidats = candidats(modele.liens(candidats, 3) == entree);
        end
    end
    if isempty(candidats)
        error('simulink:delete_line:lienInconnu', ...
              'Aucun lien ne va de ''%s'' a ''%s''.', char(source), char(destination));
    end
    modele.liens(candidats, :) = [];
end
