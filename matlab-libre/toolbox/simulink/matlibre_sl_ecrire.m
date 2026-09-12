function chemin = matlibre_sl_ecrire(modele, chemin)
%MATLIBRE_SL_ECRIRE Écrit dans un fichier le programme qui simule un schéma.
%   CHEMIN = MATLIBRE_SL_ECRIRE(MODELE,CHEMIN) écrit à cet endroit le
%   programme que rend MATLIBRE_SL_PROGRAMME, et rend le chemin écrit.
%   L'extension .m est ajoutée si elle manque, et le nom de la fonction
%   est celui du fichier — sans quoi elle ne s'appellerait pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('petit'), 'constant', 'c', 'Value', 1);
%      f = matlibre_sl_ecrire(m, [tempname() '.m']);
%      isfile(f)                                % 1
%      delete(f);
%
%   Voir aussi MATLIBRE_SL_PROGRAMME, SAVE_SYSTEM.
    chemin = char(chemin);
    if numel(chemin) < 2 || ~strcmp(chemin(end-1:end), '.m')
        chemin = [chemin '.m'];
    end
    [~, base] = fileparts(chemin);
    texte = matlibre_sl_programme(modele, base);
    identifiant = fopen(chemin, 'w');
    if identifiant < 0
        error('Simulink:programme:EcritureImpossible', ...
              'Impossible d''ecrire ''%s''.', chemin);
    end
    fprintf(identifiant, '%s', texte);
    fclose(identifiant);
end
