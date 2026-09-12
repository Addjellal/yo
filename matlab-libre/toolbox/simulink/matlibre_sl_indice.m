function k = matlibre_sl_indice(modele, nom)
%MATLIBRE_SL_INDICE Rang d'un bloc désigné par son nom.
%   K = MATLIBRE_SL_INDICE(MODELE,NOM) rend le rang du bloc dans
%   MODELE.blocs, et lève une erreur qui nomme le bloc s'il n'existe pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      matlibre_sl_indice(m, 'g')       % 1
%
%   Voir aussi ADD_LINE, DELETE_BLOCK, GET_PARAM.
    if ~ischar(nom) && ~isstring(nom)
        error('simulink:bloc:nomInvalide', 'Un bloc se designe par son nom.');
    end
    nom = char(nom);
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            k = i;
            return
        end
    end
    error('simulink:bloc:inconnu', 'Unknown block ''%s''.', nom);
end
