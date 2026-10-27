classdef ConfigSet < handle
%CONFIGSET Un jeu de configuration : les réglages de simulation d'un modèle.
%   CS = SIMULINK.CONFIGSET crée un jeu, nommé 'Configuration', qui porte
%   les réglages par défaut. GET_PARAM(CS,'Solver') en lit un,
%   SET_PARAM(CS,'StopTime','5',...) en change, vérifiés comme sur le
%   modèle. ATTACHCONFIGSET l'attache à un modèle chargé, SETACTIVECONFIGSET
%   en fait le jeu que la simulation emploie ; GETACTIVECONFIGSET rend le
%   jeu actif d'un modèle, dont les changements valent aussitôt pour lui.
%   COPY(CS) en fait un autre, détaché.
%
%   Ses propriétés : Name, son nom, unique parmi les jeux d'un modèle, et
%   Description. GETPROP et SETPROP valent GET_PARAM et SET_PARAM.
%
%   Exemple :
%      cs = Simulink.ConfigSet;
%      set_param(cs, 'Solver', 'ode4', 'FixedStep', '0.1');
%      get_param(cs, 'Solver')                  % 'ode4'
%      cs.Name = 'Rapide';
%      autre = copy(cs);
%      get_param(autre, 'FixedStep')            % '0.1'
%
%   Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, SETACTIVECONFIGSET,
%   GETCONFIGSETS, DETACHCONFIGSET.
    properties
        Name = 'Configuration'
        Description = ''
    end
    properties (Hidden)
        % le modèle chargé où le jeu est attaché, '' s'il ne l'est pas
        Modele = ''
        % les réglages posés d'un jeu détaché
        Reglages = struct()
    end
    methods
        function v = get_param(cs, nom)
            nom = char(nom);
            if strcmpi(nom, 'Name')
                v = cs.Name;
                return
            end
            if strcmpi(nom, 'Description')
                v = cs.Description;
                return
            end
            if isempty(matlibre_sl_config('nom', nom))
                error('Simulink:Commands:ParamUnknown', ...
                      ['Le jeu de configuration ''%s'' n''a pas de reglage nomme ''%s'' ; ' ...
                       'ses reglages sont ceux de la boite de configuration.'], cs.Name, nom);
            end
            if isempty(cs.Modele)
                v = get_param(provisoire(cs), nom);
            else
                v = matlibre_sl_jeux('lire', cs.Modele, cs.Name, nom);
            end
        end
        function set_param(cs, varargin)
            if isempty(varargin) || mod(numel(varargin), 2) ~= 0
                error('Simulink:Commands:ParamValuePairs', ...
                      'SET_PARAM(JEU,''Reglage'',VALEUR,...) : les reglages vont par paires.');
            end
            couples = {};
            for k = 1:2:numel(varargin)
                nom = char(varargin{k});
                if strcmpi(nom, 'Name')
                    cs.Name = varargin{k + 1};
                elseif strcmpi(nom, 'Description')
                    cs.Description = varargin{k + 1};
                else
                    couples(end + 1:end + 2) = {nom, varargin{k + 1}}; %#ok<AGROW>
                end
            end
            if isempty(couples)
                return
            end
            if isempty(cs.Modele)
                t = set_param(provisoire(cs), couples{:});
                cs.Reglages = t.parametres;
            else
                matlibre_sl_jeux('ecrire', cs.Modele, cs.Name, couples);
            end
        end
        function v = getProp(cs, nom)
            v = get_param(cs, nom);
        end
        function setProp(cs, nom, valeur)
            set_param(cs, nom, valeur);
        end
        function c = copy(cs)
            c = Simulink.ConfigSet;
            c.Name = cs.Name;
            c.Description = cs.Description;
            c.Reglages = reglagesActuels(cs);
        end
        function set.Name(cs, v)
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            if ~ischar(v) || isempty(strtrim(v))
                error('Simulink:ConfigSet:InvalidName', ...
                      'Le nom d''un jeu de configuration est un texte non vide.');
            end
            if ~isempty(cs.Modele) && ~strcmp(v, cs.Name)
                matlibre_sl_jeux('renommer', cs.Modele, cs.Name, v);
            end
            cs.Name = v;
        end
        function set.Description(cs, v)
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            if ~ischar(v)
                error('Simulink:ConfigSet:InvalidDescription', ...
                      'La description d''un jeu de configuration est un texte.');
            end
            cs.Description = v;
        end
        function lier(cs, nomModele, nom)
            % attaché : ses réglages vivent désormais dans le modèle
            cs.Modele = '';
            cs.Name = nom;
            cs.Modele = nomModele;
            cs.Reglages = struct();
        end
        function delier(cs, reglages)
            % détaché : il reprend ses réglages
            cs.Modele = '';
            cs.Reglages = reglages;
        end
        function disp(cs)
            etat = 'detache';
            if ~isempty(cs.Modele)
                etat = sprintf('attache a ''%s''', cs.Modele);
                if strcmp(matlibre_sl_jeux('actif', cs.Modele), cs.Name)
                    etat = [etat ', actif'];
                end
            end
            fprintf('  Simulink.ConfigSet ''%s'' (%s)\n', cs.Name, etat);
            if ~isempty(cs.Description)
                fprintf('    Description : %s\n', cs.Description);
            end
            fprintf('    Solver : %s, StartTime : %s, StopTime : %s\n\n', ...
                    texte(get_param(cs, 'Solver')), texte(get_param(cs, 'StartTime')), ...
                    texte(get_param(cs, 'StopTime')));
        end
    end
end

function t = provisoire(cs)
    t = struct('nom', 'ConfigSet', 'blocs', {{}}, 'liens', [], 'parametres', cs.Reglages);
end

function r = reglagesActuels(cs)
    if isempty(cs.Modele)
        r = cs.Reglages;
    else
        r = matlibre_sl_jeux('reglages', cs.Modele, cs.Name);
    end
end

function t = texte(v)
    if ischar(v)
        t = v;
    else
        t = num2str(v);
    end
end
