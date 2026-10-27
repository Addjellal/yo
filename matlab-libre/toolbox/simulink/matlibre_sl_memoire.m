function varargout = matlibre_sl_memoire(action, varargin)
%MATLIBRE_SL_MEMOIRE Les modèles chargés, désignés par leur chemin ou leur poignée.
%   C'est le cœur de l'API de Simulink par les noms : ADD_BLOCK('m/k'),
%   SET_PARAM('m/s/k',...), GET_PARAM(H,...) agissent sur les modèles que
%   NEW_SYSTEM, LOAD_SYSTEM et OPEN_SYSTEM ont chargés dans la session.
%   Un chemin s'écrit « modele/sousSysteme/bloc » ; une barre dans un nom
%   de bloc s'y double, comme dans Simulink (« m/a//b » désigne le bloc
%   « a/b »).
%
%   [PARENT,NOM] = MATLIBRE_SL_MEMOIRE('decouper',CHEMIN) sépare le chemin
%   du système parent et le nom du dernier objet, sans ses barres
%   doublées ; PARENT est vide pour un modèle. M =
%   MATLIBRE_SL_MEMOIRE('morceaux',CHEMIN) rend tous les noms. C =
%   MATLIBRE_SL_MEMOIRE('joindre',PARENT,NOM) rebâtit un chemin.
%
%   S = MATLIBRE_SL_MEMOIRE('systeme',CHEMIN) rend le système au bout du
%   chemin — le modèle, ou le modèle que porte un sous-système. B =
%   MATLIBRE_SL_MEMOIRE('bloc',CHEMIN) rend la structure d'un bloc. S =
%   MATLIBRE_SL_MEMOIRE('appliquer',CHEMIN,F) remplace le système S au
%   bout du chemin par F(S), dans le modèle chargé, et rend F(S). G =
%   MATLIBRE_SL_MEMOIRE('genre',CHEMIN) dit 'modele' ou 'bloc', et refuse
%   un chemin qui ne mène nulle part.
%
%   C = MATLIBRE_SL_MEMOIRE('chemin',X) rend le chemin que désigne X — un
%   texte, ou une poignée de bloc, de modèle ou de ligne. H =
%   MATLIBRE_SL_MEMOIRE('poignee',CHEMIN) rend la poignée d'un bloc ou
%   d'un modèle : un nombre, le même pour un même objet toute la session,
%   qui le suit quand on le renomme. [C,GENRE,PORT] =
%   MATLIBRE_SL_MEMOIRE('objet',H) dit ce que désigne une poignée : son
%   chemin, son genre ('bloc', 'modele', 'ligne', ou le genre d'un port)
%   et son rang. VRAI = MATLIBRE_SL_MEMOIRE('estpoignee',H) le dit sans
%   erreur. H = MATLIBRE_SL_MEMOIRE('poigneeligne',SYSTEME,BLOC,E) rend la
%   poignée de la ligne qui arrive à l'entrée E du bloc BLOC de SYSTEME ;
%   L = MATLIBRE_SL_MEMOIRE('ligne',H) la relit : son système, ses deux
%   blocs et leurs ports.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [p, n] = matlibre_sl_memoire('decouper', 'm/s/a//b')   % 'm/s', 'a/b'
%      matlibre_sl_memoire('joindre', 'm', 'x/y')             % 'm/x//y'
%
%   Voir aussi ADD_BLOCK, SET_PARAM, GET_PARAM, GETSIMULINKBLOCKHANDLE.
    switch lower(char(action))
        case 'decouper'
            [varargout{1}, varargout{2}] = decouper(char(varargin{1}));
        case 'morceaux'
            varargout{1} = morceaux(char(varargin{1}));
        case 'joindre'
            varargout{1} = joindre(char(varargin{1}), char(varargin{2}));
        case 'echapper'
            varargout{1} = strrep(char(varargin{1}), '/', '//');
        case 'systeme'
            varargout{1} = systeme(cheminDe(varargin{1}));
        case 'bloc'
            [modele, noms] = racine(cheminDe(varargin{1}));
            if isempty(noms)
                varargout{1} = modele;
            else
                s = systemeDans(modele, noms(1:end - 1), cheminDe(varargin{1}));
                varargout{1} = s.blocs{indice(s, noms{end}, cheminDe(varargin{1}))};
            end
        case 'appliquer'
            varargout{1} = appliquer(cheminDe(varargin{1}), varargin{2});
        case 'genre'
            varargout{1} = genre(cheminDe(varargin{1}));
        case 'chemin'
            varargout{1} = cheminDe(varargin{1});
        case 'poignee'
            varargout{1} = poignee(cheminDe(varargin{1}));
        case 'objet'
            [varargout{1}, varargout{2}, varargout{3}] = objet(varargin{1});
        case 'poigneeligne'
            [systemeLigne, nomBloc, port] = varargin{:};
            [nomModele, rel] = relatif(joindre(cheminDe(systemeLigne), nomBloc));
            varargout{1} = matlibre_sl_signaux('numero', nomModele, rel, 'ligne', port);
        case 'ligne'
            varargout{1} = ligne(varargin{1});
        case 'estpoignee'
            x = varargin{1};
            varargout{1} = isnumeric(x) && isscalar(x) && ...
                           ~isempty(matlibre_sl_signaux('cle', double(x)));
        case 'renommer'
            % le bloc CHEMIN s'appelle désormais NOM : ses poignées le suivent
            [chemin, nom] = varargin{:};
            [parent, ~] = decouper(chemin);
            nouveau = joindre(parent, nom);
            [m, ancienR] = relatif(chemin);
            [~, nouveauR] = relatif(nouveau);
            matlibre_sl_signaux('renommer', m, ancienR, nouveauR);
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% --- les chemins ----------------------------------------------------------------

function noms = morceaux(chemin)
    noms = {};
    courant = '';
    k = 1;
    while k <= numel(chemin)
        if chemin(k) == '/'
            if k < numel(chemin) && chemin(k + 1) == '/'
                courant(end + 1) = '/'; %#ok<AGROW>
                k = k + 2;
                continue
            end
            noms{end + 1} = courant; %#ok<AGROW>
            courant = '';
        else
            courant(end + 1) = chemin(k); %#ok<AGROW>
        end
        k = k + 1;
    end
    noms{end + 1} = courant;
end

function [parent, nom] = decouper(chemin)
    noms = morceaux(chemin);
    nom = noms{end};
    parent = '';
    for k = 1:numel(noms) - 1
        parent = joindre(parent, noms{k});
    end
end

function c = joindre(parent, nom)
    if isempty(parent)
        c = strrep(nom, '/', '//');
    else
        c = [parent '/' strrep(nom, '/', '//')];
    end
end

% Le modèle, et le chemin du bloc dans le modèle — ce que les poignées
% retiennent.
function [nomModele, rel] = relatif(chemin)
    noms = morceaux(chemin);
    nomModele = noms{1};
    rel = '';
    for k = 2:numel(noms)
        rel = joindre(rel, noms{k});
    end
end

% Un chemin, ou la poignée qui en désigne un.
function chemin = cheminDe(x)
    if isnumeric(x)
        if ~isscalar(x)
            error('Simulink:Commands:InvSimulinkObjHandle', ...
                  'Une poignee d''objet Simulink est un nombre.');
        end
        chemin = objet(x);
        return
    end
    if isstring(x) && isscalar(x)
        x = char(x);
    end
    if ~ischar(x) || isempty(x)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              'Un objet Simulink se designe par son chemin, ''modele/bloc'', ou sa poignee.');
    end
    chemin = x;
end

% --- les systèmes -----------------------------------------------------------------

function [modele, noms] = racine(chemin)
    noms = morceaux(chemin);
    nomModele = noms{1};
    noms = noms(2:end);
    if ~matlibre_sl_ouverts('connu', nomModele)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              ['Nom d''objet Simulink invalide : ''%s''. Le modele ''%s'' n''est pas ' ...
               'charge : NEW_SYSTEM, LOAD_SYSTEM ou OPEN_SYSTEM le chargent.'], ...
              chemin, nomModele);
    end
    modele = matlibre_sl_ouverts('lire', nomModele);
end

function k = indice(s, nom, chemin)
    for k = 1:numel(s.blocs)
        if strcmp(s.blocs{k}.nom, nom)
            return
        end
    end
    error('Simulink:Commands:InvSimulinkObjectName', ...
          'Nom d''objet Simulink invalide : ''%s'' — aucun bloc ne s''appelle ''%s''.', ...
          chemin, nom);
end

function s = systemeDans(modele, noms, chemin)
    s = modele;
    for k = 1:numel(noms)
        s = interieur(s.blocs{indice(s, noms{k}, chemin)}, chemin);
    end
end

function s = systeme(chemin)
    [modele, noms] = racine(chemin);
    s = systemeDans(modele, noms, chemin);
end

function g = genre(chemin)
    [modele, noms] = racine(chemin);
    if isempty(noms)
        g = 'modele';
        return
    end
    s = systemeDans(modele, noms(1:end - 1), chemin);
    indice(s, noms{end}, chemin);
    g = 'bloc';
end

function sortie = appliquer(chemin, f)
    [modele, noms] = racine(chemin);
    sortie = f(systemeDans(modele, noms, chemin));
    modele = reposer(modele, noms, sortie, chemin);
    tous = morceaux(chemin);
    matlibre_sl_ouverts('ecrire', tous{1}, modele);
end

function modele = reposer(modele, noms, sous, chemin)
    if isempty(noms)
        modele = sous;
        return
    end
    k = indice(modele, noms{1}, chemin);
    bloc = modele.blocs{k};
    dedans = reposer(interieur(bloc, chemin), noms(2:end), sous, chemin);
    if isfield(bloc.parametres, 'Modele') && ~isfield(bloc.parametres, 'Model')
        bloc.parametres.Modele = dedans;
    else
        bloc.parametres.Model = dedans;
    end
    modele.blocs{k} = bloc;
end

% Le modèle que porte un sous-système ; vide s'il n'en porte pas encore,
% comme un Subsystem que l'on vient de poser.
function s = interieur(bloc, chemin)
    if ~strcmp(bloc.type, 'subsystem')
        error('Simulink:Commands:InvSimulinkObjectName', ...
              ['Nom d''objet Simulink invalide : ''%s'' — le bloc ''%s'' n''est pas un ' ...
               'sous-systeme : on n''y descend pas.'], chemin, bloc.nom);
    end
    if isfield(bloc.parametres, 'Model')
        s = matlibre_sl_modele(bloc.parametres.Model);
    elseif isfield(bloc.parametres, 'Modele')
        s = matlibre_sl_modele(bloc.parametres.Modele);
    else
        s = new_system(regexprep(char(bloc.nom), '[^A-Za-z0-9_]', '_'));
    end
end

% --- les poignées -------------------------------------------------------------------

function h = poignee(chemin)
    g = genre(chemin);
    [nomModele, rel] = relatif(chemin);
    if strcmp(g, 'modele')
        h = matlibre_sl_signaux('numero', nomModele, '', 'modele', 0);
    else
        h = matlibre_sl_signaux('numero', nomModele, rel, 'bloc', 0);
    end
end

function [chemin, g, port] = objet(h)
    cle = '';
    if isnumeric(h) && isscalar(h)
        cle = matlibre_sl_signaux('cle', double(h));
    end
    if isempty(cle)
        error('Simulink:Commands:InvSimulinkObjHandle', ...
              'Poignee d''objet Simulink invalide : %s.', num2str(h, 10));
    end
    morceauxCle = strsplit(cle, '|');
    nomModele = morceauxCle{1};
    rel = strjoin(morceauxCle(2:end - 2), '|');
    g = morceauxCle{end - 1};
    port = str2double(morceauxCle{end});
    chemin = nomModele;
    if ~isempty(rel)
        chemin = [nomModele '/' rel];
    end
end

% La ligne d'une poignée : celle qui arrive à l'entrée qu'elle désigne,
% tant qu'elle existe.
function L = ligne(h)
    [chemin, g, port] = objet(h);
    if ~strcmp(g, 'ligne')
        error('Simulink:Commands:InvSimulinkObjHandle', ...
              '%s n''est pas une poignee de ligne : ADD_LINE et LineHandles en rendent.', ...
              num2str(h, 10));
    end
    [parent, nomBloc] = decouper(chemin);
    s = systeme(parent);
    b = indice(s, nomBloc, chemin);
    liens = matlibre_sl_liens(s);
    r = find(liens(:, 2) == b & liens(:, 3) == port, 1);
    if isempty(r)
        error('Simulink:Commands:InvSimulinkObjHandle', ...
              ['La ligne %s n''existe plus : l''entree %d de ''%s'' n''est plus ' ...
               'reliee.'], num2str(h, 10), port, chemin);
    end
    L = struct('systeme', parent, 'source', s.blocs{liens(r, 1)}.nom, ...
               'portSource', liens(r, 4), 'destination', nomBloc, 'portDestination', port);
end
