function varargout = evalinGlobal(modele, expression)
%EVALINGLOBAL Évalue une expression là où les blocs d'un modèle lisent leurs variables.
%   V = SIMULINK.DATA.EVALINGLOBAL(MODELE,EXPRESSION) évalue EXPRESSION
%   avec les variables du dictionnaire de données du modèle chargé MODELE
%   — section 'Design Data', références comprises — puis celles de
%   l'espace de travail de base, quand le modèle n'en a pas ou que
%   EnableAccessToBaseWorkspace vaut 'on'. Sans sortie, l'expression peut
%   être une affectation, 'K = 5' : la variable change là où elle est
%   définie, dans le dictionnaire si elle y est.
%
%   Exemple :
%      new_system('globalEval');
%      assignin('base', 'kGlobal', 3);
%      Simulink.data.evalinGlobal('globalEval', 'kGlobal * 2')   % 6
%      evalin('base', 'clear kGlobal');
%      close_system('globalEval', 0);
%
%   Voir aussi SIMULINK.DATA.EXISTSINGLOBAL, SIMULINK.DATA.ASSIGNINGLOBAL.
    [dictionnaire, base] = matlibre_sl_portee(modele);
    expression = char(expression);
    if isempty(dictionnaire)
        if nargout > 0
            varargout{1} = evalin('base', expression);
        else
            evalin('base', [expression ';']);
        end
        return
    end
    section = getSection(Simulink.data.Dictionary(dictionnaire), 'Design Data');
    if ~base
        if nargout > 0
            varargout{1} = evalin(section, expression);
        else
            evalin(section, expression);
        end
        return
    end
    % le dictionnaire passe avant l'espace de base : les variables qu'il
    % ne porte pas se lisent dans l'espace de base
    noms = matlibre_sl_dictionnaire('entrees', dictionnaire, 'Design Data');
    D = struct();
    for id = unique(regexp(expression, '[A-Za-z]\w*', 'match'))
        if ~any(strcmp(noms, id{1})) && evalin('base', sprintf('exist(''%s'', ''var'')', id{1})) == 1
            D.(id{1}) = evalin('base', id{1});
        end
    end
    for k = 1:numel(noms)
        D.(noms{k}) = matlibre_sl_dictionnaire('lire', dictionnaire, 'Design Data', noms{k});
    end
    if nargout > 0
        apres = matlibre_sl_espace('executer', D, ['matlibreResultat__ = ' expression], ...
                                   char(modele));
        varargout{1} = apres.matlibreResultat__;
        return
    end
    apres = matlibre_sl_espace('executer', D, expression, char(modele));
    for champ = fieldnames(apres).'
        n = champ{1};
        if ~isfield(D, n) || ~isequal(D.(n), apres.(n))
            Simulink.data.assigninGlobal(modele, n, apres.(n));
        end
    end
end
