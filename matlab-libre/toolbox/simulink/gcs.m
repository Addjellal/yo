function nom = gcs()
%GCS Le nom du dernier modèle ouvert.
%   NOM = GCS() rend le nom du modèle ouvert le plus récemment par
%   OPEN_SYSTEM ou LOAD_SYSTEM, et une chaîne vide si aucun ne l'est.
%
%   Dans MATLAB, GCS rend le système courant, celui dont la fenêtre a le
%   focus. Il n'y a pas de fenêtre ici, et la notion la plus proche est
%   celle du dernier modèle ouvert : c'est ce que rend GCS.
%
%   Exemple :
%      bdclose('all');
%      m = new_system('regulateur');
%      open_system(m);
%      gcs()                            % 'regulateur'
%      bdclose('all');
%
%   Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, BDROOT, BDISLOADED.
    nom = matlibre_sl_ouverts('dernier');
end
