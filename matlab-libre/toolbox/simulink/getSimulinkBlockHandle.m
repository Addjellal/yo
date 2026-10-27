function h = getSimulinkBlockHandle(chemin, charger)
%GETSIMULINKBLOCKHANDLE La poignée d'un bloc, désigné par son chemin.
%   H = GETSIMULINKBLOCKHANDLE(CHEMIN) rend la poignée du bloc de chemin
%   'modele/sousSysteme/bloc' d'un modèle chargé — ou du modèle, pour son
%   seul nom —, et -1 si rien ne porte ce chemin : comme dans Simulink, la
%   fonction ne lève pas d'erreur, ce qui en fait le test d'existence d'un
%   bloc. Avec une cellule de chemins, H est un tableau de même taille.
%
%   H = GETSIMULINKBLOCKHANDLE(CHEMIN,true) charge d'abord le modèle, s'il
%   ne l'est pas, par LOAD_SYSTEM.
%
%   Une poignée est un nombre, le même pour un même bloc toute la session ;
%   GET_PARAM, SET_PARAM, DELETE_BLOCK et GETFULLNAME l'acceptent à la
%   place du chemin.
%
%   Exemple :
%      new_system('poignees');
%      add_block('built-in/Gain', 'poignees/k');
%      h = getSimulinkBlockHandle('poignees/k');
%      get_param(h, 'Name')                     % 'k'
%      getSimulinkBlockHandle('poignees/absent')   % -1
%      bdclose('poignees');
%
%   Voir aussi GET_PARAM, GETFULLNAME, ADD_BLOCK, FIND_SYSTEM.
    if nargin < 2
        charger = false;
    end
    if iscell(chemin)
        h = -ones(size(chemin));
        for k = 1:numel(chemin)
            h(k) = getSimulinkBlockHandle(chemin{k}, charger);
        end
        return
    end
    h = -1;
    if isstring(chemin) && isscalar(chemin)
        chemin = char(chemin);
    end
    if ~ischar(chemin) || isempty(chemin)
        return
    end
    try
        morceaux = matlibre_sl_memoire('morceaux', chemin);
        if charger && ~matlibre_sl_ouverts('connu', morceaux{1})
            load_system(morceaux{1});
        end
        h = matlibre_sl_memoire('poignee', chemin);
    catch
        h = -1;
    end
end
