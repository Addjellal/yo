classdef ConfigSet < handle
%SIMULINK.CONFIGSET Un jeu de configuration : les réglages d'un modèle.
%   CS = SIMULINK.CONFIGSET crée un jeu libre, nommé 'Configuration', aux
%   valeurs d'un modèle neuf de Simulink : le solveur automatique à pas
%   variable, les sorties en Dataset. SET_PARAM(CS,'Reglage',VALEUR,...) le règle,
%   GET_PARAM(CS,'Reglage') le lit — en texte, comme dans Simulink —, et
%   COPY(CS) en rend un double indépendant.
%
%   ATTACHCONFIGSET l'attache à un modèle, SETACTIVECONFIGSET le rend
%   actif : ses réglages deviennent ceux que SIM applique.
%   GETACTIVECONFIGSET rend le jeu actif d'un modèle. Le jeu d'un modèle
%   de la session y reste lié : le régler règle le modèle.
%
%   Les réglages sont ceux de MATLIBRE_SL_CONFIG — StopTime, Solver,
%   FixedStep... —, vérifiés quand on les pose. Un jeu ne s'enregistre
%   pas à part : SAVE_SYSTEM écrit les réglages du jeu actif.
%
%   Exemple :
%      cs = Simulink.ConfigSet;
%      set_param(cs, 'StopTime', '3', 'Solver', 'ode4');
%      get_param(cs, 'Solver')                  % 'ode4'
%      autre = copy(cs);
%      autre.Name = 'Long';
%      set_param(autre, 'StopTime', '100');
%      get_param(cs, 'StopTime')                % '3'
%
%   Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, SETACTIVECONFIGSET,
%   GETCONFIGSETS, SET_PARAM, GET_PARAM.
    properties (Dependent)
        Name
        Description
    end
    properties (Hidden)
        % le modèle de la session auquel le jeu est lié, '' s'il est libre
        Modele = ''
        Nom = 'Configuration'
        Texte = ''
        Reglages = struct()
    end
    methods
        function obj = ConfigSet(jeu, modele)
            if nargin == 0
                % un jeu neuf part des réglages d'un modèle neuf de
                % Simulink, comme NEW_SYSTEM dans la session
                obj.Reglages = struct('Solver', 'VariableStepAuto', 'SaveFormat', 'Dataset');
            end
            if nargin >= 1
                obj.Nom = char(jeu.Name);
                obj.Texte = char(jeu.Description);
                obj.Reglages = jeu.Reglages;
            end
            if nargin >= 2
                obj.Modele = char(modele);
            end
        end

        function nom = get.Name(obj)
            nom = obj.Nom;
        end
        function set.Name(obj, nom)
            if ~((ischar(nom) && isrow(nom)) || (isstring(nom) && isscalar(nom)))
                error('Simulink:ConfigSet:InvalidName', ...
                      'The configuration set name must be text.');
            end
            obj.renommer(char(nom), obj.Description);
        end
        function texte = get.Description(obj)
            jeu = obj.structure();
            texte = jeu.Description;
        end
        function set.Description(obj, texte)
            obj.renommer(obj.Nom, char(texte));
        end

        function set_param(obj, varargin)
            if isempty(varargin) || mod(numel(varargin), 2) ~= 0
                error('Simulink:Commands:SetParamArguments', ...
                      'SET_PARAM(CS,NAME,VALUE,...): parameters must be name-value pairs.');
            end
            for k = 1:2:numel(varargin)
                if isempty(matlibre_sl_config('nom', varargin{k}))
                    error('Simulink:Commands:ParamUnknown', ...
                          'The configuration set has no parameter named ''%s''.', ...
                          char(varargin{k}));
                end
            end
            if obj.lie()
                modele = matlibre_sl_jeux('regler', matlibre_sl_ouverts('lire', obj.Modele), ...
                                          obj.Nom, varargin);
                matlibre_sl_nomme('ranger', obj.Modele, modele);
            else
                porteur = struct('nom', obj.Nom, 'blocs', {{}}, 'liens', [], ...
                                 'parametres', obj.Reglages);
                porteur = set_param(porteur, varargin{:});
                obj.Reglages = porteur.parametres;
            end
        end

        function valeur = get_param(obj, nom)
            canon = matlibre_sl_config('nom', nom);
            if isempty(canon)
                if strcmpi(char(nom), 'Name')
                    valeur = obj.Nom;
                    return
                end
                error('Simulink:Commands:ParamUnknown', ...
                      'The configuration set has no parameter named ''%s''.', char(nom));
            end
            jeu = obj.structure();
            porteur = struct('nom', obj.Nom, 'blocs', {{}}, 'liens', [], ...
                             'parametres', jeu.Reglages);
            valeur = matlibre_sl_nomme('reglage', canon, get_param(porteur, canon));
        end

        function double = copy(obj)
            double = Simulink.ConfigSet(obj.structure());
        end

        function oui = isActive(obj)
            oui = obj.lie() && strcmp(matlibre_sl_jeux('actif', ...
                                      matlibre_sl_ouverts('lire', obj.Modele)), obj.Nom);
        end

        function nom = getModel(obj)
            nom = '';
            if obj.lie()
                nom = obj.Modele;
            end
        end

        function j = structure(obj)
            % le jeu tel qu'il est : dans le modèle s'il y est lié
            if obj.lie()
                j = matlibre_sl_jeux('lire', matlibre_sl_ouverts('lire', obj.Modele), obj.Nom);
                % gardé pour le jour où le modèle se ferme : le jeu
                % redevient libre, avec ce qu'il valait
                obj.Reglages = j.Reglages;
                obj.Texte = j.Description;
            else
                j = struct('Name', obj.Nom, 'Description', obj.Texte, ...
                           'Reglages', obj.Reglages);
            end
        end

        function disp(obj)
            fprintf('  Simulink.ConfigSet ''%s''', obj.Nom);
            if obj.lie()
                fprintf(', du modele ''%s''', obj.Modele);
                if obj.isActive()
                    fprintf(' (actif)');
                end
            end
            fprintf('\n');
            jeu = obj.structure();
            r = jeu.Reglages;
            champs = fieldnames(r);
            for k = 1:numel(champs)
                fprintf('    %s: %s\n', champs{k}, ...
                        strtrim(evalc('disp(r.(champs{k}))')));
            end
        end
    end
    methods (Hidden)
        % Lié à un modèle de la session qui porte encore ce jeu.
        function oui = lie(obj)
            oui = false;
            if isempty(obj.Modele) || ~matlibre_sl_ouverts('connu', obj.Modele)
                return
            end
            noms = matlibre_sl_jeux('noms', matlibre_sl_ouverts('lire', obj.Modele));
            oui = any(strcmp(noms, obj.Nom));
        end
        function renommer(obj, nom, texte)
            if obj.lie()
                modele = matlibre_sl_jeux('nommer', matlibre_sl_ouverts('lire', obj.Modele), ...
                                          obj.Nom, nom, texte);
                matlibre_sl_nomme('ranger', obj.Modele, modele);
            end
            obj.Nom = nom;
            obj.Texte = texte;
        end
    end
end
