function chemin = gcb(systeme) %#ok<INUSD>
%GCB Le bloc courant.
%   GCB rend le chemin du bloc courant — celui qu'on a choisi dans
%   l'éditeur de Simulink. Hors de l'éditeur, aucun bloc ne l'est : GCB
%   rend un texte vide, comme Simulink quand rien n'est choisi.
%   GCB(SYSTEME) est accepté de même.
%
%   Exemple :
%      bdclose('all');
%      m = new_system('regulateur');
%      add_block(m, 'gain', 'g', 'Gain', 2);
%      isempty(gcb())                   % vrai : aucun bloc n'est choisi
%      bdclose('all');
%
%   Voir aussi GCS, BDROOT, GETFULLNAME.
    chemin = '';
end
