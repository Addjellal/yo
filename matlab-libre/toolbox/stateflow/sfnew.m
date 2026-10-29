function sfnew(varargin)
%SFNEW Crée un modèle qui porte un diagramme Stateflow vide.
%   SFNEW crée un modèle nommé untitled — untitled1, untitled2... s'il
%   est pris — qui porte un bloc Chart nommé Chart, sans état ni port.
%   SFNEW(NOM) le nomme ; SFNEW('-MATLAB',NOM) ou SFNEW('-C',NOM) choisit
%   le langage d'action du diagramme. On le garnit ensuite par l'API :
%   FIND(SFROOT,'-isa','Stateflow.Chart') rend le diagramme, et
%   STATEFLOW.STATE, STATEFLOW.TRANSITION, STATEFLOW.DATA... y créent ses
%   objets.
%
%   Exemple :
%      sfnew('sfnewEssai');
%      get_param('sfnewEssai/Chart', 'BlockType')   % 'Chart'
%      close_system('sfnewEssai', 0);
%
%   Voir aussi SFROOT, STATEFLOW.CHART, NEW_SYSTEM.
    langage = 'MATLAB';
    nom = '';
    for k = 1:numel(varargin)
        a = char(varargin{k});
        if any(strcmpi(a, {'-MATLAB', '-C'}))
            langage = upper(a(2:end));
            if strcmp(langage, 'MATLAB')
                langage = 'MATLAB';
            end
        else
            nom = a;
        end
    end
    if isempty(nom)
        nom = 'untitled';
        k = 0;
        while matlibre_sl_ouverts('connu', nom)
            k = k + 1;
            nom = sprintf('untitled%d', k);
        end
    end
    if ~isvarname(nom)
        error('Stateflow:API:InvalidModelName', ...
              '''%s'' n''est pas un nom de modele : il se nomme comme une variable.', nom);
    end
    new_system(nom);
    add_block('sflib/Chart', [nom '/Chart']);
    if strcmp(langage, 'C')
        ch = matlibre_sf_api('objet', getSimulinkBlockHandle([nom '/Chart']), 0);
        ch.ActionLanguage = 'C';
    end
end
