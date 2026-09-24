function [dx, y] = matlibre_sl_derivee(modele, x, u, pas)
%MATLIBRE_SL_DERIVEE Dérivée d'état et sortie d'un modèle en un point.
%   [DX,Y] = MATLIBRE_SL_DERIVEE(MODELE,X,U) place les états continus à X
%   et les entrées à U, calcule une passe de sortie, et rend la dérivée de
%   chaque état ainsi que la valeur de chaque sortie. MODELE peut aussi
%   être le modèle déjà préparé que rend MATLIBRE_SL_ETATS : les appels
%   répétés de LINMOD et de TRIM ne le recompilent pas. Un quatrième
%   argument, le pas, est accepté et ignoré : rien n'est simulé.
%
%   La dérivée ne se mesure pas : elle se lit. L'entrée d'un intégrateur
%   est sa dérivée, et une représentation d'état donne A x + B u, calculé
%   sur l'entrée à l'instant même.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('chaine');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'gain', 'k', 'Gain', 3);
%      m = add_block(m, 'integrator', 'x');
%      m = add_line(m, 'u', 'k');
%      m = add_line(m, 'k', 'x');
%      matlibre_sl_derivee(m, 0, 2)           % 6 : la dérivée vaut 3*u
%
%   Voir aussi LINMOD, DLINMOD, TRIM, SIM.
    if isstruct(modele) && isfield(modele, 'listeTout')
        T = modele;
    else
        [~, ~, ~, ~, T] = matlibre_sl_etats(modele);
    end
    [y, dx] = matlibre_sl_executer('point', T, x(:), u(:));
end
