function [dictionnaire, base] = matlibre_sl_portee(modele)
%MATLIBRE_SL_PORTEE La portée globale des variables d'un modèle chargé.
%   [D,BASE] = MATLIBRE_SL_PORTEE(MODELE) rend le chemin du dictionnaire
%   de données du modèle, ouvert, '' s'il n'en a pas, et dit si ses blocs
%   lisent l'espace de travail de base (EnableAccessToBaseWorkspace).
%   Un modèle qui n'est pas chargé est refusé.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      new_system('porteeEssai');
%      [d, base] = matlibre_sl_portee('porteeEssai')   % '', true
%      close_system('porteeEssai', 0);
%
%   Voir aussi SIMULINK.DATA.EVALINGLOBAL, SIMULINK.DATA.ASSIGNINGLOBAL.
    if isstruct(modele) && isfield(modele, 'nom')
        modele = modele.nom;
    end
    if ~(ischar(modele) || (isstring(modele) && isscalar(modele))) || ...
       ~matlibre_sl_ouverts('connu', char(modele))
        error('Simulink:Commands:InvalidModel', ...
              ['''%s'' n''est pas un modele charge : LOAD_SYSTEM ou NEW_SYSTEM le ' ...
               'charge.'], char(string(modele)));
    end
    modele = char(modele);
    dictionnaire = char(get_param(modele, 'DataDictionary'));
    base = true;
    if ~isempty(dictionnaire)
        try
            dictionnaire = matlibre_sl_dictionnaire('ouvrir', dictionnaire);
        catch err
            error('SLDD:sldd:DictionaryNotFound', ...
                  ['Le modele ''%s'' a pour dictionnaire de donnees ''%s'' ' ...
                   '(DataDictionary) : %s'], modele, dictionnaire, err.message);
        end
        base = ~strcmpi(get_param(modele, 'EnableAccessToBaseWorkspace'), 'off');
    end
end
