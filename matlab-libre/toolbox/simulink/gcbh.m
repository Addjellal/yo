function h = gcbh()
%GCBH La poignée du bloc courant.
%   H = GCBH() rend la poignée du bloc courant — celui dont un rappel
%   (InitFcn, CopyFcn, OpenFcn...) s'exécute —, et -1 hors de tout rappel,
%   quand aucun bloc ne l'est.
%
%   Exemple :
%      new_system('courant');
%      add_block('built-in/Gain', 'courant/k', 'OpenFcn', 'hOuvert = gcbh;');
%      open_system('courant/k');
%      get_param(evalin('base', 'hOuvert'), 'Name')   % 'k'
%      gcbh()                                   % -1 : plus de rappel
%      bdclose('courant');
%
%   Voir aussi GCB, GCS, GETSIMULINKBLOCKHANDLE.
    chemin = matlibre_sl_courant('bloc');
    if isempty(chemin)
        h = -1;
        return
    end
    h = getSimulinkBlockHandle(chemin);
end
