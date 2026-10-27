function varargout = matlibre_sl_jeux(action, varargin)
%MATLIBRE_SL_JEUX Les jeux de configuration d'un modèle chargé.
%   Un modèle porte un ou plusieurs jeux de configuration, chacun ses
%   réglages ; le jeu actif est celui que la simulation emploie, rangé
%   dans MODELE.parametres, et les autres attendent dans MODELE.jeux.
%   GETACTIVECONFIGSET, ATTACHCONFIGSET, SETACTIVECONFIGSET... passent par
%   ici. Un même jeu rend toujours le même objet Simulink.ConfigSet : deux
%   appels de GETCONFIGSET le désignent par une même poignée.
%
%   Actions : 'noms', 'actif', 'objet', 'lire', 'ecrire', 'attacher',
%   'activer', 'detacher', 'renommer', 'reglages', 'oublier'.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      new_system('jeux');
%      matlibre_sl_jeux('noms', 'jeux')         % {'Configuration'}
%      bdclose('jeux');
%
%   Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, SIMULINK.CONFIGSET.
    switch lower(char(action))
        case 'noms'
            varargout{1} = {jeux(modeleDe(varargin{1})).nom}.';
        case 'actif'
            varargout{1} = actif(modeleDe(varargin{1}));
        case 'objet'
            varargout{1} = objet(nomDe(varargin{1}), char(varargin{2}));
        case 'lire'
            [nomModele, nomJeu, parametre] = varargin{:};
            varargout{1} = get_param(modeleDuJeu(nomModele, nomJeu), parametre);
        case 'ecrire'
            [nomModele, nomJeu, couples] = varargin{:};
            ecrire(nomModele, nomJeu, couples);
        case 'reglages'
            % les réglages posés d'un jeu attaché
            [nomModele, nomJeu] = varargin{:};
            m = modeleDuJeu(nomModele, nomJeu);
            varargout{1} = m.parametres;
        case 'attacher'
            varargout{1} = attacher(nomDe(varargin{1}), varargin{2}, varargin{3});
        case 'activer'
            activer(nomDe(varargin{1}), char(varargin{2}));
        case 'detacher'
            varargout{1} = detacher(nomDe(varargin{1}), char(varargin{2}));
        case 'renommer'
            [nomModele, ancien, nouveau] = varargin{:};
            renommer(nomModele, ancien, nouveau);
        case 'oublier'
            oublier(char(varargin{1}));
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% --- le modèle et ses jeux --------------------------------------------------------

function nom = nomDe(x)
    chemin = matlibre_sl_memoire('chemin', x);
    if ~strcmp(matlibre_sl_memoire('genre', chemin), 'modele')
        error('Simulink:ConfigSet:NotABlockDiagram', ...
              '''%s'' est un bloc : les jeux de configuration sont ceux d''un modele.', chemin);
    end
    nom = chemin;
end

function m = modeleDe(x)
    m = matlibre_sl_ouverts('lire', nomDe(x));
end

% Les jeux du modèle, le premier étant 'Configuration' s'il n'en a jamais
% eu d'autre ; le jeu actif y garde le nom, ses réglages sont ceux du
% modèle.
function J = jeux(m)
    if isfield(m, 'jeux') && ~isempty(m.jeux)
        J = m.jeux;
    else
        J = struct('nom', {'Configuration'}, 'parametres', {struct()});
    end
end

function nom = actif(m)
    nom = 'Configuration';
    if isfield(m, 'jeuActif') && ~isempty(m.jeuActif)
        nom = m.jeuActif;
    end
end

function i = rang(J, nom, nomModele)
    i = find(strcmp({J.nom}, nom), 1);
    if isempty(i)
        error('Simulink:ConfigSet:ConfigSetNotFound', ...
              'Le modele ''%s'' n''a pas de jeu de configuration nomme ''%s''.', ...
              nomModele, nom);
    end
end

% Un modèle provisoire qui porte les réglages du jeu : GET_PARAM et
% SET_PARAM y valent comme sur le modèle.
function t = modeleDuJeu(nomModele, nomJeu)
    m = matlibre_sl_ouverts('lire', nomModele);
    if strcmp(nomJeu, actif(m))
        t = m;
        return
    end
    J = jeux(m);
    t = provisoire(nomModele, J(rang(J, nomJeu, nomModele)).parametres);
end

% NEW_SYSTEM viderait l'espace de travail du modèle : le modèle provisoire
% se bâtit à la main.
function t = provisoire(nomModele, parametres)
    t = struct('nom', nomModele, 'blocs', {{}}, 'liens', [], 'parametres', parametres);
end

function ecrire(nomModele, nomJeu, couples)
    m = matlibre_sl_ouverts('lire', nomModele);
    if strcmp(nomJeu, actif(m))
        matlibre_sl_memoire('appliquer', nomModele, @(s) set_param(s, couples{:}));
        return
    end
    J = jeux(m);
    i = rang(J, nomJeu, nomModele);
    t = provisoire(nomModele, J(i).parametres);
    t = set_param(t, couples{:});
    J(i).parametres = t.parametres;
    m.jeux = J;
    matlibre_sl_ouverts('ecrire', nomModele, m);
end

% --- les objets : un par jeu attaché ----------------------------------------------

function sortie = registre(action, cle, valeur)
    persistent objets
    if isempty(objets)
        objets = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    sortie = [];
    switch action
        case 'lire'
            if isKey(objets, cle)
                sortie = objets(cle);
            end
        case 'poser'
            objets(cle) = valeur;
        case 'retirer'
            if isKey(objets, cle)
                remove(objets, cle);
            end
        case 'cles'
            sortie = keys(objets);
    end
end

function cs = objet(nomModele, nomJeu)
    m = matlibre_sl_ouverts('lire', nomModele);
    rang(jeux(m), nomJeu, nomModele);
    cs = registre('lire', [nomModele '|' nomJeu]);
    if isempty(cs)
        cs = Simulink.ConfigSet;
        cs.lier(nomModele, nomJeu);
        registre('poser', [nomModele '|' nomJeu], cs);
    end
end

function cs = attacher(nomModele, cs, permettre)
    if ~isa(cs, 'Simulink.ConfigSet') || ~isscalar(cs)
        error('Simulink:ConfigSet:InvalidConfigSet', ...
              'ATTACHCONFIGSET attache un Simulink.ConfigSet.');
    end
    if ~isempty(cs.Modele)
        error('Simulink:ConfigSet:ConfigSetAlreadyAttached', ...
              ['Le jeu de configuration ''%s'' est deja attache au modele ''%s'' : ' ...
               'ATTACHCONFIGSETCOPY en attache une copie.'], cs.Name, cs.Modele);
    end
    m = matlibre_sl_ouverts('lire', nomModele);
    J = jeux(m);
    nom = cs.Name;
    if any(strcmp({J.nom}, nom))
        if ~permettre
            error('Simulink:ConfigSet:ConfigSetNameConflict', ...
                  ['Le modele ''%s'' porte deja un jeu de configuration nomme ''%s'' : ' ...
                   'renommez-le, ou ATTACHCONFIGSET(MODELE, JEU, true) le renomme.'], ...
                  nomModele, nom);
        end
        base = regexprep(nom, '\d+$', '');
        k = 1;
        while any(strcmp({J.nom}, sprintf('%s%d', base, k)))
            k = k + 1;
        end
        nom = sprintf('%s%d', base, k);
    end
    J(end + 1) = struct('nom', nom, 'parametres', cs.Reglages);
    m.jeux = J;
    if ~isfield(m, 'jeuActif') || isempty(m.jeuActif)
        m.jeuActif = 'Configuration';
    end
    matlibre_sl_ouverts('ecrire', nomModele, m);
    cs.lier(nomModele, nom);
    registre('poser', [nomModele '|' nom], cs);
end

function activer(nomModele, nom)
    m = matlibre_sl_ouverts('lire', nomModele);
    J = jeux(m);
    j = rang(J, nom, nomModele);
    ancien = actif(m);
    if strcmp(ancien, nom)
        return
    end
    i = rang(J, ancien, nomModele);
    J(i).parametres = champsDe(m);
    m.parametres = J(j).parametres;
    m.jeux = J;
    m.jeuActif = nom;
    matlibre_sl_ouverts('ecrire', nomModele, m);
end

function p = champsDe(m)
    p = struct();
    if isfield(m, 'parametres') && isstruct(m.parametres)
        p = m.parametres;
    end
end

function cs = detacher(nomModele, nom)
    m = matlibre_sl_ouverts('lire', nomModele);
    J = jeux(m);
    i = rang(J, nom, nomModele);
    if strcmp(nom, actif(m))
        error('Simulink:ConfigSet:CannotDetachActiveConfigSet', ...
              ['Le jeu ''%s'' est le jeu actif du modele ''%s'' : SETACTIVECONFIGSET en ' ...
               'active un autre avant qu''on le detache.'], nom, nomModele);
    end
    reglages = J(i).parametres;
    J(i) = [];
    m.jeux = J;
    matlibre_sl_ouverts('ecrire', nomModele, m);
    cs = registre('lire', [nomModele '|' nom]);
    registre('retirer', [nomModele '|' nom]);
    if isempty(cs)
        cs = Simulink.ConfigSet;
        cs.Name = nom;
    end
    cs.delier(reglages);
end

function renommer(nomModele, ancien, nouveau)
    m = matlibre_sl_ouverts('lire', nomModele);
    J = jeux(m);
    i = rang(J, ancien, nomModele);
    if any(strcmp({J.nom}, nouveau))
        error('Simulink:ConfigSet:ConfigSetNameConflict', ...
              'Le modele ''%s'' porte deja un jeu de configuration nomme ''%s''.', ...
              nomModele, nouveau);
    end
    J(i).nom = nouveau;
    m.jeux = J;
    if strcmp(actif(m), ancien)
        m.jeuActif = nouveau;
    end
    matlibre_sl_ouverts('ecrire', nomModele, m);
    cs = registre('lire', [nomModele '|' ancien]);
    registre('retirer', [nomModele '|' ancien]);
    if ~isempty(cs)
        registre('poser', [nomModele '|' nouveau], cs);
    end
end

% Le modèle se ferme : ses jeux restent, détachés, avec leurs réglages.
function oublier(nomModele)
    for cle = registre('cles')
        texte = cle{1};
        if ~strncmp(texte, [nomModele '|'], numel(nomModele) + 1)
            continue
        end
        cs = registre('lire', texte);
        registre('retirer', texte);
        try
            reglages = matlibre_sl_jeux('reglages', nomModele, cs.Name);
        catch
            reglages = struct();
        end
        cs.delier(reglages);
    end
end
