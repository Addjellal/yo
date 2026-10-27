function chemin = gcb(systeme) %#ok<INUSD>
%GCB Le bloc courant.
%   GCB rend le chemin du bloc courant : celui dont un rappel s'exécute
%   (InitFcn, StartFcn, CopyFcn, OpenFcn...). Hors de tout rappel, aucun
%   bloc ne l'est : GCB rend un texte vide, comme Simulink quand rien
%   n'est choisi. GCB(SYSTEME) est accepté de même.
%
%   Exemple :
%      bdclose('all');
%      m = new_system('regulateur');
%      add_block(m, 'gain', 'g', 'Gain', 2);
%      isempty(gcb())                   % vrai : aucun bloc n'est choisi
%      bdclose('all');
%
%   Voir aussi GCS, GCBH, BDROOT, GETFULLNAME.
    chemin = matlibre_sl_courant('bloc');
end
