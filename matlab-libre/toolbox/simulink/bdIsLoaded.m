function reponse = bdIsLoaded(nom)
%BDISLOADED Dit si un modèle est ouvert dans la session.
%   R = BDISLOADED(NOM) rend vrai si un modèle de ce nom a été ouvert par
%   OPEN_SYSTEM ou LOAD_SYSTEM et pas encore fermé.
%
%   Exemple :
%      bdclose('all');
%      m = new_system('essai');
%      bdIsLoaded('essai')              % faux : construit n'est pas ouvert
%      open_system(m);
%      bdIsLoaded('essai')              % vrai
%      bdclose('all');
%
%   Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, BDCLOSE, GCS, LOAD_SYSTEM.
    reponse = matlibre_sl_ouverts('connu', nom);
end
