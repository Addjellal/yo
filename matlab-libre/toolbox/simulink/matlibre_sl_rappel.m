function matlibre_sl_rappel(modele, nom)
%MATLIBRE_SL_RAPPEL Exécute un rappel du modèle : InitFcn, StopFcn...
%   MATLIBRE_SL_RAPPEL(MODELE,NOM) évalue dans l'espace de travail de base
%   le code que le modèle porte dans son réglage NOM, s'il en porte un.
%   Ce sont les rappels de Simulink : PreLoadFcn et PostLoadFcn quand le
%   modèle se charge, InitFcn avant qu'il se compile — les variables
%   qu'il définit servent à ses blocs —, StartFcn quand la simulation
%   commence, StopFcn quand elle s'achève, PreSaveFcn et PostSaveFcn
%   autour d'un enregistrement, CloseFcn à la fermeture.
%
%   Une erreur dans le rappel est rendue en le nommant, avec le modèle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = set_param(new_system('rappels'), 'InitFcn', 'gainDuRappel = 3;');
%      matlibre_sl_rappel(m, 'InitFcn');
%      evalin('base', 'gainDuRappel')            % 3
%
%   Voir aussi SIM, LOAD_SYSTEM, SAVE_SYSTEM, SET_PARAM.
    code = '';
    if isfield(modele, 'parametres') && isstruct(modele.parametres)
        for champ = fieldnames(modele.parametres).'
            if strcmpi(champ{1}, nom)
                code = modele.parametres.(champ{1});
            end
        end
    end
    if isstring(code)
        code = char(code);
    end
    if ~ischar(code) || isempty(strtrim(code))
        return
    end
    try
        evalin('base', code);
    catch err
        error('Simulink:Engine:CallbackEvalErr', ...
              'Erreur dans le rappel %s du modele ''%s'' : %s', nom, char(modele.nom), ...
              err.message);
    end
end
