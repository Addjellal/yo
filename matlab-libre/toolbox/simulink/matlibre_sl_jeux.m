function varargout = matlibre_sl_jeux(action, modele, varargin)
%MATLIBRE_SL_JEUX Les jeux de configuration d'un modèle.
%   Un modèle porte un jeu de configuration actif — ses réglages, ceux
%   que SET_PARAM pose et que SIM applique — et, à côté, ceux qu'on lui a
%   attachés. Les réglages du jeu actif vivent dans MODELE.parametres ;
%   les autres attendent dans MODELE.jeux, avec le nom de l'actif.
%
%   NOMS = MATLIBRE_SL_JEUX('noms',MODELE)        tous les jeux, l'actif d'abord
%   NOM = MATLIBRE_SL_JEUX('actif',MODELE)        le nom du jeu actif
%   J = MATLIBRE_SL_JEUX('lire',MODELE,NOM)       un jeu : Name, Description, Reglages
%   MODELE = MATLIBRE_SL_JEUX('attacher',MODELE,J,RENOMMER)
%   MODELE = MATLIBRE_SL_JEUX('activer',MODELE,NOM)
%   MODELE = MATLIBRE_SL_JEUX('detacher',MODELE,NOM)
%   MODELE = MATLIBRE_SL_JEUX('regler',MODELE,NOM,COUPLES)   les réglages d'un jeu
%   MODELE = MATLIBRE_SL_JEUX('nommer',MODELE,NOM,NOUVEAU,DESCRIPTION)
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('essai');
%      matlibre_sl_jeux('noms', m)                % {'Configuration'}
%      j = struct('Name', 'Rapide', 'Description', '', ...
%                 'Reglages', struct('StopTime', 1));
%      m = matlibre_sl_jeux('attacher', m, j, false);
%      m = matlibre_sl_jeux('activer', m, 'Rapide');
%      get_param(m, 'StopTime')                   % 1
%
%   Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, SETACTIVECONFIGSET.
    if ~isfield(modele, 'parametres') || isempty(modele.parametres)
        modele.parametres = struct();
    end
    if ~isfield(modele, 'jeux') || isempty(modele.jeux)
        modele.jeux = struct('actif', 'Configuration', 'description', '', ...
                             'autres', struct('Name', {}, 'Description', {}, ...
                                              'Reglages', {}));
    end
    switch action
        case 'noms'
            varargout{1} = [{modele.jeux.actif}; {modele.jeux.autres.Name}.'];
        case 'actif'
            varargout{1} = modele.jeux.actif;
        case 'lire'
            varargout{1} = lire(modele, char(varargin{1}));
        case 'attacher'
            [varargout{1}, varargout{2}] = attacher(modele, varargin{:});
        case 'activer'
            varargout{1} = activer(modele, char(varargin{1}));
        case 'detacher'
            nom = char(varargin{1});
            k = rang(modele, nom);
            if k == 0
                error('Simulink:ConfigSet:ActiveConfigSetCannotBeDetached', ...
                      ['Configuration set ''%s'' is the active configuration set of model ' ...
                       '''%s'': ' ...
                       'it cannot be detached. SETACTIVECONFIGSET activates another one.'], ...
                      nom, char(modele.nom));
            end
            modele.jeux.autres(k) = [];
            varargout{1} = modele;
        case 'regler'
            varargout{1} = regler(modele, char(varargin{1}), varargin{2});
        case 'nommer'
            [nom, nouveau, description] = varargin{:};
            k = rang(modele, char(nom));
            if ~strcmp(nom, nouveau) && any(strcmp(matlibre_sl_jeux('noms', modele), nouveau))
                error('Simulink:ConfigSet:ConfigSetNameNotUnique', ...
                      'Model ''%s'' already has a configuration set named ''%s''.', ...
                      char(modele.nom), nouveau);
            end
            if k == 0
                modele.jeux.actif = nouveau;
                modele.jeux.description = description;
            else
                modele.jeux.autres(k).Name = nouveau;
                modele.jeux.autres(k).Description = description;
            end
            varargout{1} = modele;
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% Le rang d'un jeu parmi les jeux en attente, 0 pour le jeu actif.
function k = rang(modele, nom)
    if strcmp(modele.jeux.actif, nom)
        k = 0;
        return
    end
    k = find(strcmp({modele.jeux.autres.Name}, nom), 1);
    if isempty(k)
        error('Simulink:ConfigSet:ConfigSetNotFound', ...
              ['Model ''%s'' has no configuration set ''%s''. Its configuration sets ' ...
               'are: %s.'], char(modele.nom), nom, ...
              strjoin(matlibre_sl_jeux('noms', modele).', ', '));
    end
end

% Les réglages de configuration que porte le modèle : ceux du jeu actif.
function r = reglagesActifs(modele)
    r = struct();
    champs = fieldnames(modele.parametres);
    for k = 1:numel(champs)
        if ~isempty(matlibre_sl_config('nom', champs{k}))
            r.(champs{k}) = modele.parametres.(champs{k});
        end
    end
end

function j = lire(modele, nom)
    k = rang(modele, nom);
    if k == 0
        j = struct('Name', nom, 'Description', modele.jeux.description, ...
                   'Reglages', reglagesActifs(modele));
    else
        j = modele.jeux.autres(k);
    end
end

function [modele, nom] = attacher(modele, jeu, renommer)
    nom = char(jeu.Name);
    pris = matlibre_sl_jeux('noms', modele);
    if any(strcmp(pris, nom))
        if ~renommer
            error('Simulink:ConfigSet:ConfigSetNameNotUnique', ...
                  ['Model ''%s'' already has a configuration set named ''%s'': ' ...
                   'ATTACHCONFIGSET(MODEL,CS,true) renames it.'], char(modele.nom), nom);
        end
        k = 1;
        while any(strcmp(pris, sprintf('%s%d', nom, k)))
            k = k + 1;
        end
        nom = sprintf('%s%d', nom, k);
    end
    modele.jeux.autres(end + 1) = struct('Name', nom, 'Description', ...
                                         char(jeu.Description), 'Reglages', jeu.Reglages);
end

% Le jeu actif cède la place : ses réglages vont attendre, ceux du jeu
% activé deviennent ceux du modèle.
function modele = activer(modele, nom)
    k = rang(modele, nom);
    if k == 0
        return
    end
    ancien = lire(modele, modele.jeux.actif);
    nouveau = modele.jeux.autres(k);
    champs = fieldnames(ancien.Reglages);
    for i = 1:numel(champs)
        modele.parametres = rmfield(modele.parametres, champs{i});
    end
    champs = fieldnames(nouveau.Reglages);
    for i = 1:numel(champs)
        modele.parametres.(champs{i}) = nouveau.Reglages.(champs{i});
    end
    modele.jeux.autres(k) = ancien;
    modele.jeux.actif = nouveau.Name;
    modele.jeux.description = nouveau.Description;
end

function modele = regler(modele, nom, couples)
    k = rang(modele, nom);
    if k == 0
        modele = set_param(modele, couples{:});
        return
    end
    modele.jeux.autres(k).Reglages = poser(modele.jeux.autres(k).Reglages, couples);
end

function r = poser(r, couples)
    porteur = struct('nom', 'jeu', 'blocs', {{}}, 'liens', [], 'parametres', r);
    porteur = set_param(porteur, couples{:});
    r = porteur.parametres;
end
