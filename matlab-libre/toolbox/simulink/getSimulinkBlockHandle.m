function h = getSimulinkBlockHandle(chemin, charger)
%GETSIMULINKBLOCKHANDLE La poignée d'un bloc, ou -1 s'il n'existe pas.
%   H = GETSIMULINKBLOCKHANDLE(CHEMIN) rend la poignée du bloc
%   'modele/bloc' d'un modèle de la session, et -1 si le modèle n'est pas
%   ouvert ou n'a pas ce bloc : c'est la façon de demander si un bloc
%   existe sans attraper d'erreur. Une cellule de chemins rend un vecteur.
%   GETSIMULINKBLOCKHANDLE(CHEMIN,true) charge d'abord le modèle par
%   LOAD_SYSTEM s'il n'est pas ouvert.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Gain', 'essai/g');
%      getSimulinkBlockHandle('essai/g') > 0        % vrai
%      getSimulinkBlockHandle('essai/absent')       % -1
%      bdclose('all');
%
%   Voir aussi GET_PARAM, GETFULLNAME, FIND_SYSTEM, SIMULINK.FINDBLOCKS.
    if nargin < 2
        charger = false;
    end
    if iscell(chemin)
        h = zeros(size(chemin));
        for k = 1:numel(chemin)
            h(k) = getSimulinkBlockHandle(chemin{k}, charger);
        end
        return
    end
    h = -1;
    chemin = char(chemin);
    if ~any(chemin == '/')
        return
    end
    try
        if charger && ~bdIsLoaded(bdroot(chemin))
            load_system(bdroot(chemin));
        end
        h = get_param(chemin, 'Handle');
    catch
        h = -1;
    end
end
