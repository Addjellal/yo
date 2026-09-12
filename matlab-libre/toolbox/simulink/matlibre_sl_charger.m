function nom = matlibre_sl_charger(chemin)
%MATLIBRE_SL_CHARGER Relit un modèle et le dépose dans l'espace de travail.
%   NOM = MATLIBRE_SL_CHARGER(CHEMIN) exécute le fichier .m qui bâtit un
%   modèle — celui qu'écrit SAVE_SYSTEM — et pose le modèle obtenu dans
%   l'espace de travail de base, sous son propre nom. Il rend ce nom.
%
%   C'est ce que fait l'éditeur du bureau quand on ouvre un modèle : il
%   ne garde pas le modèle pour lui, il le met là où tout le monde le
%   voit — la console, l'explorateur de variables, et l'éditeur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('reprise'), 'gain', 'k', 'Gain', 2);
%      chemin = save_system(m, [tempname() '.m']);
%      nom = matlibre_sl_charger(chemin);
%      strcmp(nom, 'reprise')                  % 1
%      delete(chemin);
%
%   Voir aussi LOAD_SYSTEM, SAVE_SYSTEM, OPEN_SYSTEM.
    modele = load_system(chemin);
    nom = modele.nom;
    variable = regexprep(char(nom), '[^A-Za-z0-9_]', '_');
    if isempty(variable) || ~isletter(variable(1))
        variable = ['modele_' variable];
    end
    assignin('base', variable, modele);
    nom = variable;
end
