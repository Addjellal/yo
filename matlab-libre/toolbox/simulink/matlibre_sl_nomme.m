function varargout = matlibre_sl_nomme(action, varargin)
%MATLIBRE_SL_NOMME La forme de MATLAB : le modèle désigné par son nom.
%   Dans MATLAB, un modèle est un objet de la session, qu'on désigne par
%   son nom, un bloc par son chemin « modele/sousSysteme/bloc », et l'un
%   comme l'autre par sa poignée :
%
%      new_system('boucle');
%      add_block('simulink/Sources/Step', 'boucle/echelon');
%      set_param('boucle/echelon', 'Time', '2');
%
%   Les fonctions de cette boîte travaillent sur une valeur, qu'elles
%   prennent et rendent. Cette fonction fait le pont : elle lit le modèle
%   au registre de la session (MATLIBRE_SL_OUVERTS), appelle la fonction
%   par valeur sur le système que le chemin désigne, et range le résultat
%   à sa place. Chaque fonction publique lui passe la main dès que son
%   premier argument n'est pas un modèle.
%
%   SORTIES = MATLIBRE_SL_NOMME(ACTION,NBSORTIES,ARGUMENTS...) : ACTION
%   est le nom de la fonction publique — 'add_block', 'add_line',
%   'delete_block', 'delete_line', 'set_param', 'get_param',
%   'find_system', 'save_system', 'replace_block', 'add_param',
%   'delete_param', 'getfullname', 'bdroot'.
%   MATLIBRE_SL_NOMME('ranger',NOM,MODELE) inscrit un modèle en gardant sa
%   figure ; MATLIBRE_SL_NOMME('systeme',OBJET) rend le nom du modèle et
%   le chemin, dans ce modèle, de ce qu'un nom ou une poignée désigne ;
%   [MODELE,NOM] = MATLIBRE_SL_NOMME('modele',OBJET) rend le modèle de la
%   session qui porte l'objet ; MATLIBRE_SL_NOMME('reglage',NOM,V) rend la
%   valeur d'un réglage de configuration comme Simulink la rend, en texte ;
%   MATLIBRE_SL_NOMME('fichier',NOM,FICHIER) note que le modèle vient
%   d'être lu de ce fichier ou d'y être écrit, et
%   MATLIBRE_SL_NOMME('chemin',FICHIER) rend son chemin absolu.
%
%   Trois choses distinguent cette forme de la forme par valeur, pour
%   répondre comme Simulink : Position s'y dit en pixels — le modèle la
%   range quarante fois plus petite, dans l'unité de sa mise en place — ;
%   un bloc pris à la bibliothèque y prend les défauts de Simulink ; et
%   la session tient pour chaque modèle Dirty et FileName.
%
%   Les poignées sont celles de MATLIBRE_SL_SIGNAUX : un nombre par
%   modèle, par bloc, par port et par ligne, le même tant que dure la
%   session.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      bdclose('all');
%      new_system('pont');
%      add_block('simulink/Sources/Constant', 'pont/c', 'Value', '4');
%      [racine, chemin] = matlibre_sl_nomme('systeme', 'pont/c')   % 'pont', 'c'
%      bdclose('all');
%
%   Voir aussi NEW_SYSTEM, ADD_BLOCK, SET_PARAM, GET_PARAM, FIND_SYSTEM.
    switch action
        case 'ranger'
            ranger(varargin{:});
        case 'systeme'
            [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = ...
                designer(varargin{1});
        case 'add_block'
            varargout{1} = ajouterBloc(varargin{2:end});
        case 'add_line'
            varargout{1} = ajouterLigne(varargin{2:end});
        case 'delete_block'
            retirerBloc(varargin{2:end});
        case 'delete_line'
            retirerLigne(varargin{2:end});
        case 'set_param'
            regler(varargin{2:end});
        case 'get_param'
            varargout{1} = lire(varargin{2:end});
        case 'find_system'
            varargout{1} = chercher(varargin{2:end});
        case 'save_system'
            varargout{1} = enregistrer(varargin{2:end});
        case 'replace_block'
            varargout{1} = remplacerBlocs(varargin{2:end});
        case 'add_param'
            ranger(varargin{2}, add_param(modeleNomme(varargin{2}), varargin{3:end}));
        case 'delete_param'
            ranger(varargin{2}, delete_param(modeleNomme(varargin{2}), varargin{3:end}));
        case 'getfullname'
            varargout{1} = nomComplet(varargin{2});
        case 'bdroot'
            varargout{1} = designer(varargin{2});
        case 'fichier'
            % MATLIBRE_SL_NOMME('fichier',NOM,FICHIER) : le modèle vient
            % d'être lu de ce fichier, ou d'y être écrit.
            matlibre_sl_ouverts('noter', char(varargin{1}), ...
                                struct('Dirty', 'off', 'FileName', cheminAbsolu(varargin{2})));
        case 'chemin'
            varargout{1} = cheminAbsolu(varargin{1});
        case 'modele'
            % [MODELE,NOM] = MATLIBRE_SL_NOMME('modele',OBJET) : le modèle de
            % la session qui porte l'objet, et son nom.
            varargout{2} = designer(varargin{1});
            varargout{1} = modeleNomme(varargout{2});
        case 'reglage'
            % T = MATLIBRE_SL_NOMME('reglage',NOM,V) : la valeur d'un réglage
            % de configuration, comme Simulink la rend — en texte.
            varargout{1} = reglageEnTexte(varargin{1}, varargin{2});
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', ...
                  char(action));
    end
end

% --- désigner -------------------------------------------------------------------

% Inscrire un modèle au registre sans perdre la figure où il est tracé.
function ranger(nom, modele)
    nom = char(nom);
    figureDuModele = 0;
    change = true;
    if matlibre_sl_ouverts('connu', nom)
        figureDuModele = matlibre_sl_ouverts('figure', nom);
        change = ~isequal(matlibre_sl_ouverts('lire', nom), modele);
    end
    matlibre_sl_ouverts('inscrire', nom, modele, figureDuModele);
    if change
        % il a changé depuis son fichier : Dirty le dit
        matlibre_sl_ouverts('noter', nom, struct('Dirty', 'on'));
    end
end

function chemin = cheminAbsolu(fichier)
    chemin = char(fichier);
    absolu = ~isempty(chemin) && (any(chemin(1) == '/\') || ...
                                 (numel(chemin) > 1 && chemin(2) == ':'));
    if ~absolu
        chemin = fullfile(pwd(), chemin);
    end
end

% Position se dit en pixels dans Simulink, [gauche haut droite bas] ; le
% modèle la range dans l'unité de sa mise en place, quarante fois plus
% grande — celle que le lecteur de .slx emploie.
function couples = positionsDuModele(couples)
    for k = 1:2:numel(couples) - 1
        if ~((ischar(couples{k}) || isstring(couples{k})) && ...
             strcmpi(char(couples{k}), 'Position'))
            continue
        end
        v = couples{k + 1};
        if ischar(v) || (isstring(v) && isscalar(v))
            v = str2num(char(v)); %#ok<ST2NM>
        end
        if ~(isnumeric(v) && isreal(v) && numel(v) == 4 && all(isfinite(v(:))))
            error('Simulink:Commands:InvalidPosition', ...
                  'Position vaut [gauche haut droite bas], quatre nombres, en pixels.');
        end
        couples{k + 1} = double(v(:).') / 40;
    end
end

% Les défauts de Simulink là où ceux de MatLibre diffèrent, pour un bloc
% pris à la bibliothèque : un bloc discret hérite sa période (-1) — ce que
% MATLIBRE_SL_SLX applique aux fichiers qui ne la disent pas —, et To
% Workspace range une timeseries.
function bloc = defautsDeSimulink(bloc)
    if any(strcmp(bloc.type, {'delay', 'zoh', 'discreteintegrator', 'discretetransferfcn', ...
                              'discretefilter', 'discretestatespace'})) && ...
       ~isfield(bloc.parametres, 'SampleTime')
        bloc.parametres.SampleTime = -1;
    end
    if strcmp(bloc.type, 'toworkspace') && ~isfield(bloc.parametres, 'SaveFormat')
        bloc.parametres.SaveFormat = 'Timeseries';
    end
end

% Le modèle ouvert sous ce nom.
function modele = modeleNomme(nom)
    nom = char(nom);
    if ~matlibre_sl_ouverts('connu', nom)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              ['Invalid Simulink object name: ''%s''. Aucun modele de ce nom n''est ' ...
               'ouvert : NEW_SYSTEM(''%s'') le cree, LOAD_SYSTEM le charge.'], nom, nom);
    end
    modele = matlibre_sl_ouverts('lire', nom);
end

% Ce qu'un nom, un chemin ou une poignée désigne : le modèle, le chemin
% dans ce modèle ('' pour le modèle lui-même), le genre — 'modele',
% 'bloc', 'inport', 'outport', 'ligne' — et le rang du port.
function [racine, chemin, genre, port] = designer(objet)
    port = 0;
    if isnumeric(objet) && isscalar(objet)
        cle = matlibre_sl_signaux('cle', double(objet));
        if isempty(cle)
            error('Simulink:Commands:InvSimulinkObjectHandle', ...
                  'Invalid Simulink object handle : %s n''est la poignee de rien.', ...
                  num2str(double(objet), 10));
        end
        morceaux = strsplit(cle, '|');
        racine = morceaux{1};
        chemin = strjoin(morceaux(2:end - 2), '|');
        genre = morceaux{end - 1};
        port = str2double(morceaux{end});
        return
    end
    if ~(ischar(objet) || (isstring(objet) && isscalar(objet)))
        error('Simulink:Commands:InvSimulinkObjectSpecifier', ...
              ['Un objet Simulink se designe par son nom (''modele/bloc''), par sa ' ...
               'poignee, ou par le modele que rend NEW_SYSTEM.']);
    end
    texte = char(objet);
    barre = find(texte == '/', 1);
    if isempty(barre)
        racine = texte;
        chemin = '';
        genre = 'modele';
    else
        racine = texte(1:barre - 1);
        chemin = texte(barre + 1:end);
        genre = 'bloc';
    end
end

function h = poignee(racine, chemin, genre, port)
    cle = sprintf('%s|%s|%s|%d', racine, chemin, genre, port);
    h = matlibre_sl_signaux('numero', cle);
end

function [parent, feuille] = couper(chemin)
    barre = find(chemin == '/', 1, 'last');
    if isempty(barre)
        parent = '';
        feuille = chemin;
    else
        parent = chemin(1:barre - 1);
        feuille = chemin(barre + 1:end);
    end
end

function texte = joindre(varargin)
    morceaux = varargin(~cellfun(@isempty, varargin));
    texte = strjoin(morceaux, '/');
end

% Le système que désigne un chemin dans le modèle. Un sous-système posé
% vide — « built-in/Subsystem » — reçoit le système vide qu'il attend.
function [modele, systeme] = systemeDe(modele, chemin)
    systeme = modele;
    if isempty(chemin)
        return
    end
    etapes = strsplit(chemin, '/');
    fait = '';
    for k = 1:numel(etapes)
        i = matlibre_sl_indice(systeme, etapes{k});
        bloc = systeme.blocs{i};
        if strcmp(bloc.type, 'subsystem') && ~isfield(bloc.parametres, 'Model') && ...
           ~isfield(bloc.parametres, 'Modele')
            bloc.parametres.Model = systemeVide(etapes{k});
            systeme.blocs{i} = bloc;
            if isempty(fait)
                modele = systeme;
            else
                modele = matlibre_sl_remplacer(modele, fait, systeme);
            end
        end
        fait = joindre(fait, etapes{k});
        systeme = matlibre_sl_dedans(modele, fait);
    end
end

% Le contenu vide d'un sous-système. Non pas NEW_SYSTEM(NOM) : il oublie
% l'espace de travail du modèle qui porterait ce nom dans la session.
function systeme = systemeVide(nom)
    systeme = struct('nom', char(nom), 'blocs', {{}}, 'liens', [], 'parametres', struct());
end

function modele = reposer(modele, chemin, systeme)
    if isempty(chemin)
        modele = systeme;
    else
        modele = matlibre_sl_remplacer(modele, chemin, systeme);
    end
end

function bloc = blocDe(modele, chemin)
    [parent, feuille] = couper(chemin);
    [~, systeme] = systemeDe(modele, parent);
    bloc = systeme.blocs{matlibre_sl_indice(systeme, feuille)};
end

% --- bâtir ----------------------------------------------------------------------

function h = ajouterBloc(source, destination, varargin)
    [racine, chemin] = designer(destination);
    if isempty(chemin)
        error('Simulink:Commands:AddBlockInvalidDest', ...
              ['ADD_BLOCK(SOURCE,DESTINATION) : la destination ''%s'' doit dire le ' ...
               'modele et le nom du bloc, ''modele/bloc''.'], char(destination));
    end
    modele = modeleNomme(racine);
    [parent, feuille] = couper(chemin);
    [modele, systeme] = systemeDe(modele, parent);
    if isnumeric(source)
        source = nomComplet(source);
    end
    source = char(source);
    if strncmpi(source, 'built-in/', 9)
        source = source(10:end);
    end
    % MakeNameUnique, ici plutôt que dans ADD_BLOCK : un bloc recopié d'un
    % autre système y a droit aussi.
    k = find(strcmpi(varargin(1:2:end), 'MakeNameUnique'), 1) * 2 - 1;
    if ~isempty(k)
        unique = strcmpi(char(varargin{k + 1}), 'on');
        varargin(k:k + 1) = [];
        pris = cellfun(@(b) char(b.nom), systeme.blocs, 'UniformOutput', false);
        if unique && any(strcmp(pris, feuille))
            base = regexprep(feuille, '\d+$', '');
            rang = 1;
            while any(strcmp(pris, sprintf('%s%d', base, rang)))
                rang = rang + 1;
            end
            feuille = sprintf('%s%d', base, rang);
        end
    end
    % Le Subsystem de la bibliothèque arrive garni, comme dans Simulink :
    % une entrée reliée à une sortie. « built-in/Subsystem » est vide.
    if any(strcmpi(source, {'simulink/Ports & Subsystems/Subsystem', ...
                            'simulink/Commonly Used Blocks/Subsystem'})) && ...
       ~any(strcmpi(varargin(1:2:end), 'Model'))
        garni = add_block(add_block(systemeVide(feuille), 'inport', 'In1'), 'outport', 'Out1');
        varargin(end + 1:end + 2) = {'Model', add_line(garni, 'In1/1', 'Out1/1')};
    end
    % un bloc de la bibliothèque, ou la copie d'un bloc qui existe ?
    deLaBibliotheque = true;
    try
        matlibre_sl_catalogue('type', source);
    catch
        deLaBibliotheque = false;
    end
    varargin = positionsDuModele(varargin);
    systeme = add_block(systeme, source, feuille, varargin{:});
    if deLaBibliotheque
        systeme.blocs{end} = defautsDeSimulink(systeme.blocs{end});
    end
    % Un Inport ou un Outport neuf prend le rang suivant, comme dans
    % Simulink : les ports d'un système vont de 1 à N. Un rang donné
    % s'insère, et décale ceux qui le suivent.
    genre = genreDePort(systeme.blocs{end});
    if ~isempty(genre)
        n = numel(portsDuSysteme(systeme, genre));
        if any(strcmpi(varargin(1:2:end), 'Port'))
            systeme = renumeroter(systeme, numel(systeme.blocs), n, ...
                                  rangDemande(systeme.blocs{end}, n, joindre(racine, parent)), ...
                                  joindre(racine, chemin));
        else
            systeme.blocs{end}.parametres.Port = n;
        end
    end
    pose = systeme.blocs{end}.nom;
    ranger(racine, reposer(modele, parent, systeme));
    h = poignee(racine, joindre(parent, pose), 'bloc', 0);
end

% Un bout de ligne — 'bloc/1', 'bloc', ou une poignée de port — rendu
% comme ADD_LINE par valeur l'attend, relatif au système.
function texte = bout(extremite, racine, parent)
    if isnumeric(extremite)
        [r, chemin, genre, port] = designer(extremite);
        [p, feuille] = couper(chemin);
        if ~strcmp(r, racine) || ~strcmp(p, parent) || ...
           ~any(strcmp(genre, {'inport', 'outport'}))
            error('Simulink:Commands:InvalidPortHandle', ...
                  ['La poignee %s n''est pas celle d''un port d''un bloc du systeme ' ...
                   '''%s''.'], num2str(double(extremite), 10), joindre(racine, parent));
        end
        texte = sprintf('%s/%d', feuille, port);
    else
        texte = char(extremite);
    end
end

function [bloc, port] = blocEtPort(texte)
    jetons = regexp(texte, '^(.*)/(\d+)$', 'tokens', 'once');
    if isempty(jetons)
        bloc = texte;
        port = 1;
    else
        bloc = jetons{1};
        port = str2double(jetons{2});
    end
end

function h = ajouterLigne(systemeNomme, sources, destinations, varargin)
    [racine, parent] = designer(systemeNomme);
    % 'autorouting' et sa valeur : le tracé se calcule tout seul ici
    k = 1;
    while k <= numel(varargin)
        if (ischar(varargin{k}) || isstring(varargin{k})) && ...
           strcmpi(char(varargin{k}), 'autorouting')
            varargin(k:min(k + 1, end)) = [];
        else
            k = k + 1;
        end
    end
    if nargin < 3
        error('Simulink:Commands:AddLinePoints', ...
              ['ADD_LINE(SYSTEME,POINTS) trace un fil sans le brancher : MatLibre ne ' ...
               'garde que les liens entre ports, ADD_LINE(SYSTEME,SORTIE,ENTREE).']);
    end
    if ~iscell(sources), sources = {sources}; end
    if ~iscell(destinations), destinations = {destinations}; end
    if isscalar(sources), sources = repmat(sources, size(destinations)); end
    if numel(sources) ~= numel(destinations)
        error('Simulink:Commands:AddLineMismatch', ...
              'ADD_LINE : autant de sorties que d''entrees, ou une seule sortie.');
    end
    modele = modeleNomme(racine);
    [modele, systeme] = systemeDe(modele, parent);
    h = zeros(numel(sources), 1);
    for k = 1:numel(sources)
        source = bout(sources{k}, racine, parent);
        systeme = add_line(systeme, source, bout(destinations{k}, racine, parent), ...
                           varargin{:});
        [bloc, port] = blocEtPort(source);
        h(k) = poignee(racine, joindre(parent, bloc), 'ligne', port);
    end
    ranger(racine, reposer(modele, parent, systeme));
end

function retirerBloc(objets)
    if ~iscell(objets)
        if isnumeric(objets), objets = num2cell(objets); else, objets = {objets}; end
    end
    for k = 1:numel(objets)
        [racine, chemin, genre] = designer(objets{k});
        if ~strcmp(genre, 'bloc')
            error('Simulink:Commands:InvSimulinkObjectName', ...
                  'DELETE_BLOCK attend le chemin d''un bloc, ''modele/bloc'', ou sa poignee.' ...
                  );
        end
        modele = modeleNomme(racine);
        [parent, feuille] = couper(chemin);
        [modele, systeme] = systemeDe(modele, parent);
        i = matlibre_sl_indice(systeme, feuille);
        genre = genreDePort(systeme.blocs{i});
        if ~isempty(genre)
            % les ports qui le suivent reculent d'un rang, comme dans Simulink
            rang = rangDe(systeme.blocs{i});
            [indices, rangs] = portsDuSysteme(systeme, genre);
            for j = indices(rangs > rang)
                systeme.blocs{j}.parametres.Port = rangDe(systeme.blocs{j}) - 1;
            end
        end
        ranger(racine, reposer(modele, parent, delete_block(systeme, feuille)));
    end
end

% --- les rangs des ports ------------------------------------------------------

% 'inport' ou 'outport' pour un bloc de port d'un système, '' sinon.
function genre = genreDePort(bloc)
    genre = '';
    try
        entree = matlibre_sl_catalogue('type', bloc.type);
    catch
        return
    end
    if any(strcmp(entree.type, {'inport', 'outport'}))
        genre = entree.type;
    end
end

function rang = rangDe(bloc)
    rang = 1;
    if isfield(bloc.parametres, 'Port')
        rang = bloc.parametres.Port;
        if ischar(rang) || isstring(rang)
            rang = str2double(rang);
        end
        rang = double(rang);
    end
end

function [indices, rangs] = portsDuSysteme(systeme, genre)
    indices = [];
    rangs = [];
    for k = 1:numel(systeme.blocs)
        if strcmp(genreDePort(systeme.blocs{k}), genre)
            indices(end + 1) = k; %#ok<AGROW>
            rangs(end + 1) = rangDe(systeme.blocs{k}); %#ok<AGROW>
        end
    end
end

% Le rang demandé pour un port, vérifié : un entier de 1 à N.
function rang = rangDemande(bloc, n, ou)
    rang = rangDe(bloc);
    if ~(isscalar(rang) && isfinite(rang) && rang == fix(rang) && rang >= 1 && rang <= n)
        error('Simulink:blocks:InvalidPortNumber', ...
              ['Le rang (Port) du bloc ''%s/%s'' doit etre un entier de 1 a %d : le systeme a ' ...
               '%d port(s) de ce genre.'], ou, char(bloc.nom), n, n);
    end
end

% Le port K passe du rang AVANT au rang APRES, et les autres se décalent
% pour que les rangs restent 1 à N, comme Simulink les renumérote.
function systeme = renumeroter(systeme, k, avant, apres, ~)
    genre = genreDePort(systeme.blocs{k});
    [indices, rangs] = portsDuSysteme(systeme, genre);
    for i = 1:numel(indices)
        j = indices(i);
        if j == k
            continue
        end
        if apres < avant && rangs(i) >= apres && rangs(i) < avant
            systeme.blocs{j}.parametres.Port = rangs(i) + 1;
        elseif apres > avant && rangs(i) > avant && rangs(i) <= apres
            systeme.blocs{j}.parametres.Port = rangs(i) - 1;
        end
    end
    systeme.blocs{k}.parametres.Port = apres;
end

function retirerLigne(objet, source, destination)
    if nargin == 1
        % une poignée de ligne : tous les liens qui partent de ce port
        for h = reshape(double(objet), 1, [])
            [racine, chemin, genre, port] = designer(h);
            if ~strcmp(genre, 'ligne')
                error('Simulink:Commands:InvalidLineHandle', ...
                      '%s n''est pas la poignee d''une ligne.', num2str(h, 10));
            end
            modele = modeleNomme(racine);
            [parent, feuille] = couper(chemin);
            [modele, systeme] = systemeDe(modele, parent);
            liens = matlibre_sl_liens(systeme);
            depart = matlibre_sl_indice(systeme, feuille);
            systeme.liens = liens(~(liens(:, 1) == depart & liens(:, 4) == port), :);
            ranger(racine, reposer(modele, parent, systeme));
        end
        return
    end
    [racine, parent] = designer(objet);
    modele = modeleNomme(racine);
    [modele, systeme] = systemeDe(modele, parent);
    systeme = delete_line(systeme, bout(source, racine, parent), ...
                          bout(destination, racine, parent));
    ranger(racine, reposer(modele, parent, systeme));
end

% --- régler et lire -------------------------------------------------------------

function regler(objet, varargin)
    if iscell(objet)
        for k = 1:numel(objet)
            regler(objet{k}, varargin{:});
        end
        return
    end
    if mod(numel(varargin), 2) ~= 0 || isempty(varargin)
        error('Simulink:Commands:SetParamArguments', ...
              'SET_PARAM(OBJET,NOM,VALEUR,...) : les reglages vont par paires.');
    end
    [racine, chemin, genre, port] = designer(objet);
    modele = modeleNomme(racine);
    info = matlibre_sl_ouverts('info', racine);
    switch genre
        case 'modele'
            % Dirty et FileName sont à la session, non au modèle
            k = 1;
            while k <= numel(varargin)
                if strcmpi(char(varargin{k}), 'FileName')
                    error('Simulink:Commands:SetParamReadOnly', ...
                          ['Le reglage FileName du modele ''%s'' se lit, mais ne se regle ' ...
                           'pas : SAVE_SYSTEM(MODELE,FICHIER) l''enregistre ailleurs.'], racine);
                elseif strcmpi(char(varargin{k}), 'Dirty')
                    info.Dirty = matlibre_sl_parametre('choix', varargin{k + 1}, 'Dirty', ...
                                                       {'off', 'on'});
                    info.DirtyDit = true;
                    varargin(k:k + 1) = [];
                else
                    k = k + 2;
                end
            end
            if ~isempty(varargin)
                modele = set_param(modele, varargin{:});
            end
            if ~strcmp(char(modele.nom), racine)
                matlibre_sl_ouverts('retirer', racine);
                racine = char(modele.nom);
                matlibre_sl_ouverts('inscrire', racine, modele, 0);
                matlibre_sl_ouverts('noter', racine, struct('FileName', info.FileName));
            end
        case 'bloc'
            % descendre d'abord : un sous-système posé vide y gagne son système
            modele = systemeDe(modele, couper(chemin));
            varargin = positionsDuModele(varargin);
            [parent, feuille] = couper(chemin);
            [~, systeme] = systemeDe(modele, parent);
            i = matlibre_sl_indice(systeme, feuille);
            avant = rangDe(systeme.blocs{i});
            modele = set_param(modele, chemin, varargin{:});
            genre = genreDePort(systeme.blocs{i});
            if ~isempty(genre) && any(strcmpi(varargin(1:2:end), 'Port'))
                % le rang change : les autres ports se décalent
                [~, systeme] = systemeDe(modele, parent);
                n = numel(portsDuSysteme(systeme, genre));
                apres = rangDemande(systeme.blocs{i}, n, joindre(racine, parent));
                systeme = renumeroter(systeme, i, avant, apres);
                modele = reposer(modele, parent, systeme);
            end
        case 'ligne'
            % une ligne porte les réglages du signal : ceux du port d'où elle part
            depart = poignee(racine, chemin, 'outport', port);
            modele = set_param(modele, depart, varargin{:});
        otherwise
            modele = set_param(modele, double(objet), varargin{:});
    end
    ranger(racine, modele);
    if isfield(info, 'DirtyDit')
        % Dirty réglé à la main l'emporte sur ce que le réglage a changé
        matlibre_sl_ouverts('noter', racine, struct('Dirty', info.Dirty));
    end
end

function valeur = lire(objet, parametre)
    if iscell(objet)
        valeur = cell(size(objet));
        for k = 1:numel(objet)
            valeur{k} = lire(objet{k}, parametre);
        end
        return
    end
    if isnumeric(objet) && ~isscalar(objet)
        valeur = cell(size(objet));
        for k = 1:numel(objet)
            valeur{k} = lire(objet(k), parametre);
        end
        return
    end
    parametre = char(parametre);
    [racine, chemin, genre, port] = designer(objet);
    modele = modeleNomme(racine);
    switch genre
        case 'modele'
            valeur = lireModele(modele, racine, parametre);
        case 'bloc'
            valeur = lireBloc(modele, racine, chemin, parametre);
        case 'ligne'
            valeur = lireLigne(modele, racine, chemin, port, parametre);
        otherwise
            valeur = lirePort(modele, racine, chemin, genre, port, parametre, ...
                              double(objet));
    end
end

function valeur = lireModele(modele, racine, parametre)
    switch lower(parametre)
        case 'handle'
            valeur = poignee(racine, '', 'modele', 0);
        case 'type'
            valeur = 'block_diagram';
        case 'name'
            valeur = racine;
        case 'parent'
            valeur = '';
        case 'blocks'
            valeur = cellfun(@(b) char(b.nom), modele.blocs(:), 'UniformOutput', false);
        case 'lines'
            valeur = lignesDe(racine, '', modele);
        case 'dirty'
            info = matlibre_sl_ouverts('info', racine);
            valeur = info.Dirty;
        case 'filename'
            info = matlibre_sl_ouverts('info', racine);
            valeur = info.FileName;
        otherwise
            valeur = reglageEnTexte(parametre, get_param(modele, parametre));
    end
end

% Les réglages de la boîte de configuration sont du texte dans Simulink :
% StopTime vaut '10', non 10.
function valeur = reglageEnTexte(parametre, valeur)
    if (isnumeric(valeur) || islogical(valeur)) && ...
       ~isempty(matlibre_sl_config('nom', parametre)) && ...
       ~any(strcmpi(parametre, {'SimulationTime', 'PacingRate'}))
        valeur = enTexte(valeur);
    end
end

function texte = enTexte(valeur)
    if isempty(valeur)
        texte = '[]';
    else
        texte = mat2str(double(valeur));
    end
end

function valeur = lireBloc(modele, racine, chemin, parametre)
    [parent, feuille] = couper(chemin);
    [~, systeme] = systemeDe(modele, parent);
    bloc = systeme.blocs{matlibre_sl_indice(systeme, feuille)};
    entree = matlibre_sl_catalogue('type', bloc.type);
    switch lower(parametre)
        case 'handle'
            valeur = poignee(racine, chemin, 'bloc', 0);
        case 'type'
            valeur = 'block';
        case 'blocktype'
            valeur = char(entree.simulink);
            if isempty(valeur)
                valeur = bloc.type;
            end
        case 'name'
            valeur = feuille;
        case 'parent'
            valeur = joindre(racine, parent);
        case 'position'
            % en pixels, comme Simulink : le modèle la range quarante fois
            % plus petite
            valeur = round(get_param(modele, chemin, 'Position') * 40);
        case 'porthandles'
            valeur = get_param(modele, chemin, 'PortHandles');
        case 'linehandles'
            ph = get_param(modele, chemin, 'PortHandles');
            valeur = struct('Inport', zeros(1, 0), 'Outport', zeros(1, 0));
            for k = 1:numel(ph.Inport)
                valeur.Inport(k) = ligneDuPort(systeme, racine, parent, feuille, ...
                                               'inport', k);
            end
            for k = 1:numel(ph.Outport)
                valeur.Outport(k) = ligneDuPort(systeme, racine, parent, feuille, ...
                                                'outport', k);
            end
        case 'portconnectivity'
            valeur = connectivite(systeme, racine, parent, feuille);
        case 'blocks'
            [~, dedans] = systemeDe(modele, chemin);
            valeur = cellfun(@(b) char(b.nom), dedans.blocs(:), 'UniformOutput', false);
        case 'lines'
            [~, dedans] = systemeDe(modele, chemin);
            valeur = lignesDe(racine, chemin, dedans);
        otherwise
            valeur = get_param(modele, chemin, parametre);
            % Les paramètres du dialogue sont du texte dans Simulink : un
            % gain vaut '3', et STR2DOUBLE(GET_PARAM(...)) le relit.
            if ~isempty(entree.params) && (isnumeric(valeur) || islogical(valeur)) && ...
               any(strcmpi(parametre, entree.params(:, 1)))
                valeur = enTexte(valeur);
            end
    end
end

% La poignée de la ligne branchée sur un port, -1 s'il est libre.
function h = ligneDuPort(systeme, racine, parent, feuille, genre, port)
    h = -1;
    liens = matlibre_sl_liens(systeme);
    if isempty(liens)
        return
    end
    k = matlibre_sl_indice(systeme, feuille);
    if strcmp(genre, 'outport')
        if any(liens(:, 1) == k & liens(:, 4) == port)
            h = poignee(racine, joindre(parent, feuille), 'ligne', port);
        end
    else
        i = find(liens(:, 2) == k & liens(:, 3) == port, 1);
        if ~isempty(i)
            h = poignee(racine, joindre(parent, char(systeme.blocs{liens(i, 1)}.nom)), ...
                        'ligne', liens(i, 4));
        end
    end
end

% PortConnectivity : un élément par port, les entrées puis les sorties.
function c = connectivite(systeme, racine, parent, feuille)
    c = struct('Type', {}, 'Position', {}, 'SrcBlock', {}, 'SrcPort', {}, ...
               'DstBlock', {}, 'DstPort', {});
    k = matlibre_sl_indice(systeme, feuille);
    [ne, ns] = matlibre_sl_ports(systeme.blocs{k});
    ne(isnan(ne)) = 0;
    ns(isnan(ns)) = 0;
    liens = matlibre_sl_liens(systeme);
    if isempty(liens)
        liens = zeros(0, 4);
    end
    de = @(i) poignee(racine, joindre(parent, char(systeme.blocs{i}.nom)), 'bloc', 0);
    for p = 1:ne
        i = find(liens(:, 2) == k & liens(:, 3) == p, 1);
        c(end + 1).Type = sprintf('%d', p); %#ok<AGROW>
        c(end).Position = [0 0];
        c(end).SrcBlock = -1;
        c(end).SrcPort = zeros(1, 0);
        if ~isempty(i)
            c(end).SrcBlock = de(liens(i, 1));
            c(end).SrcPort = liens(i, 4) - 1;   % compté de zéro, comme Simulink
        end
        c(end).DstBlock = zeros(1, 0);
        c(end).DstPort = zeros(1, 0);
    end
    for p = 1:ns
        vers = find(liens(:, 1) == k & liens(:, 4) == p).';
        c(end + 1).Type = sprintf('%d', p); %#ok<AGROW>
        c(end).Position = [0 0];
        c(end).SrcBlock = zeros(1, 0);
        c(end).SrcPort = zeros(1, 0);
        c(end).DstBlock = arrayfun(@(i) de(liens(i, 2)), vers);
        c(end).DstPort = liens(vers, 3).' - 1;
    end
end

% Les lignes d'un système : une par port de sortie d'où part un lien.
function lignes = lignesDe(racine, chemin, systeme)
    lignes = struct('Handle', {}, 'Name', {}, 'Parent', {}, 'SrcBlock', {}, ...
                    'SrcPort', {}, 'DstBlock', {}, 'DstPort', {});
    liens = matlibre_sl_liens(systeme);
    if isempty(liens)
        return
    end
    departs = unique(liens(:, [1 4]), 'rows');
    for k = 1:size(departs, 1)
        nomSource = char(systeme.blocs{departs(k, 1)}.nom);
        vers = find(liens(:, 1) == departs(k, 1) & liens(:, 4) == departs(k, 2)).';
        lignes(end + 1).Handle = poignee(racine, joindre(chemin, nomSource), 'ligne', ...
                                         departs(k, 2)); %#ok<AGROW>
        lignes(end).Name = matlibre_sl_signaux('nom', systeme.blocs{departs(k, 1)}, ...
                                               departs(k, 2));
        lignes(end).Parent = joindre(racine, chemin);
        lignes(end).SrcBlock = poignee(racine, joindre(chemin, nomSource), 'bloc', 0);
        lignes(end).SrcPort = sprintf('%d', departs(k, 2));
        lignes(end).DstBlock = arrayfun(@(i) poignee(racine, ...
            joindre(chemin, char(systeme.blocs{liens(i, 2)}.nom)), 'bloc', 0), vers);
        lignes(end).DstPort = arrayfun(@(i) sprintf('%d', liens(i, 3)), vers, ...
                                       'UniformOutput', false);
    end
end

function valeur = lireLigne(modele, racine, chemin, port, parametre)
    [parent, feuille] = couper(chemin);
    [~, systeme] = systemeDe(modele, parent);
    k = matlibre_sl_indice(systeme, feuille);
    liens = matlibre_sl_liens(systeme);
    if isempty(liens)
        liens = zeros(0, 4);
    end
    vers = find(liens(:, 1) == k & liens(:, 4) == port).';
    if isempty(vers)
        error('Simulink:Commands:InvalidLineHandle', ...
              'La ligne qui partait du port %d de ''%s'' n''existe plus.', port, ...
              joindre(racine, chemin));
    end
    switch lower(parametre)
        case 'handle'
            valeur = poignee(racine, chemin, 'ligne', port);
        case 'type'
            valeur = 'line';
        case 'parent'
            valeur = joindre(racine, parent);
        case 'srcblockhandle'
            valeur = poignee(racine, chemin, 'bloc', 0);
        case 'srcporthandle'
            valeur = poignee(racine, chemin, 'outport', port);
        case 'dstblockhandle'
            valeur = arrayfun(@(i) poignee(racine, ...
                joindre(parent, char(systeme.blocs{liens(i, 2)}.nom)), 'bloc', 0), vers(:));
        case 'dstporthandle'
            valeur = arrayfun(@(i) poignee(racine, ...
                joindre(parent, char(systeme.blocs{liens(i, 2)}.nom)), 'inport', ...
                liens(i, 3)), vers(:));
        otherwise
            valeur = get_param(modele, poignee(racine, chemin, 'outport', port), parametre);
    end
end

function valeur = lirePort(modele, racine, chemin, genre, port, parametre, h)
    switch lower(parametre)
        case 'handle'
            valeur = h;
        case 'type'
            valeur = 'port';
        case 'parent'
            valeur = joindre(racine, chemin);
        case 'porttype'
            valeur = genre;
        case 'portnumber'
            valeur = port;
        case 'line'
            [parent, feuille] = couper(chemin);
            [~, systeme] = systemeDe(modele, parent);
            valeur = ligneDuPort(systeme, racine, parent, feuille, genre, port);
        otherwise
            valeur = get_param(modele, h, parametre);
    end
end

function nom = nomComplet(objets)
    if iscell(objets) || (isnumeric(objets) && ~isscalar(objets))
        if isnumeric(objets), objets = num2cell(objets); end
        nom = cell(size(objets));
        for k = 1:numel(objets)
            nom{k} = nomComplet(objets{k});
        end
        return
    end
    [racine, chemin, genre, port] = designer(objets);
    modeleNomme(racine);
    nom = joindre(racine, chemin);
    if any(strcmp(genre, {'inport', 'outport', 'ligne'}))
        nom = sprintf('%s/%d', nom, port);
    end
end

% --- chercher -------------------------------------------------------------------

% FIND_SYSTEM de MATLAB : le système lui-même, puis ses blocs, en
% profondeur ; les options d'abord, les critères ensuite.
function trouves = chercher(varargin)
    options = struct('SearchDepth', Inf, 'LookUnderMasks', 'graphical', ...
                     'FollowLinks', 'off', 'FindAll', 'off', 'CaseSensitive', 'on', ...
                     'RegExp', 'off', 'Variants', '', 'MatchFilter', [], ...
                     'IncludeCommented', 'off', 'LookInsideSubsystemReference', 'on', ...
                     'FirstResultOnly', 'off');
    nomsOptions = fieldnames(options);
    departs = {};
    parPoignee = false;
    if mod(numel(varargin), 2) == 1
        depart = varargin{1};
        varargin(1) = [];
        parPoignee = isnumeric(depart);
        if isnumeric(depart)
            departs = num2cell(depart(:));
        elseif iscell(depart)
            departs = depart(:);
        else
            departs = {depart};
        end
    else
        ouverts = matlibre_sl_ouverts('noms');
        departs = ouverts(:);
    end
    criteres = {};
    for k = 1:2:numel(varargin)
        nom = char(varargin{k});
        i = find(strcmpi(nom, nomsOptions), 1);
        if ~isempty(i) && isempty(criteres)
            options.(nomsOptions{i}) = varargin{k + 1};
        else
            criteres(end + 1, :) = {nom, varargin{k + 1}}; %#ok<AGROW>
        end
    end
    profondeur = options.SearchDepth;
    if ischar(profondeur) || isstring(profondeur)
        profondeur = str2double(profondeur);
    end
    sousMasques = options.LookUnderMasks;
    if ~(ischar(sousMasques) || isstring(sousMasques))
        error('Simulink:Commands:FindSystemInvalidOption', ...
              'LookUnderMasks vaut ''graphical'', ''none'', ''functional'', ''all'', ''on'' ou ''off''.');
    end
    reglage = struct('profondeur', profondeur, ...
                     'masques', any(strcmpi(char(sousMasques), {'all', 'on', 'functional'})), ...
                     'liens', strcmpi(char(options.FollowLinks), 'on'), ...
                     'commentes', strcmpi(char(options.IncludeCommented), 'on'), ...
                     'tout', strcmpi(char(options.FindAll), 'on'));
    objets = {};
    for k = 1:numel(departs)
        [racine, chemin] = designer(departs{k});
        modele = modeleNomme(racine);
        if isempty(chemin)
            objets{end + 1, 1} = racine; %#ok<AGROW>
            objets = parcourir(objets, racine, '', modele, 1, reglage);
        else
            blocDe(modele, chemin);
            objets{end + 1, 1} = joindre(racine, chemin); %#ok<AGROW>
            objets = descendre(objets, racine, chemin, modele, 1, reglage);
        end
    end
    garde = true(size(objets));
    for k = 1:numel(objets)
        for c = 1:size(criteres, 1)
            if ~repond(objets{k}, criteres{c, 1}, criteres{c, 2}, options)
                garde(k) = false;
                break
            end
        end
    end
    objets = objets(garde);
    if strcmpi(char(options.FirstResultOnly), 'on') && ~isempty(objets)
        objets = objets(1);
    end
    if reglage.tout || parPoignee
        trouves = zeros(numel(objets), 1);
        for k = 1:numel(objets)
            if isnumeric(objets{k})
                trouves(k) = objets{k};
            else
                trouves(k) = lire(objets{k}, 'Handle');
            end
        end
    else
        trouves = objets;
    end
end

% Les blocs d'un système, chacun suivi de ce qu'il contient ; puis, avec
% FindAll, ses lignes et les ports de ses blocs.
function objets = parcourir(objets, racine, chemin, systeme, niveau, reglage)
    if niveau > reglage.profondeur
        return
    end
    vus = true(1, numel(systeme.blocs));
    for k = 1:numel(systeme.blocs)
        % un bloc commenté, et ce qu'il contient, ne se voit qu'à la demande
        if ~reglage.commentes && estCommente(systeme.blocs{k})
            vus(k) = false;
            continue
        end
        ici = joindre(chemin, char(systeme.blocs{k}.nom));
        objets{end + 1, 1} = joindre(racine, ici); %#ok<AGROW>
        objets = descendre(objets, racine, ici, systeme.blocs{k}, niveau + 1, reglage);
    end
    if reglage.tout
        lignes = lignesDe(racine, chemin, systeme);
        for k = 1:numel(lignes)
            objets{end + 1, 1} = lignes(k).Handle; %#ok<AGROW>
        end
        for k = find(vus)
            % les poignées se comptent depuis la racine
            ph = get_param(modeleNomme(racine), ...
                           joindre(chemin, char(systeme.blocs{k}.nom)), 'PortHandles');
            for h = [ph.Inport, ph.Outport]
                objets{end + 1, 1} = h; %#ok<AGROW>
            end
        end
    end
end

function oui = estCommente(bloc)
    oui = isfield(bloc.parametres, 'Commented') && ...
          ~strcmpi(char(bloc.parametres.Commented), 'off');
end

% Sous un bloc : rien s'il n'est pas un sous-système, ou si son masque ou
% son lien de bibliothèque le ferment à la recherche.
function objets = descendre(objets, racine, chemin, bloc, niveau, reglage)
    if isfield(bloc, 'blocs')
        % appelé sur le modèle : le bloc est à lire
        bloc = blocDe(bloc, chemin);
    end
    if ~strcmp(bloc.type, 'subsystem')
        return
    end
    if isfield(bloc, 'reference') && ~reglage.liens
        return
    end
    if ~reglage.masques && ~isempty(matlibre_sl_masque('variables', bloc))
        return
    end
    if isfield(bloc.parametres, 'Model')
        dedans = bloc.parametres.Model;
    elseif isfield(bloc.parametres, 'Modele')
        dedans = bloc.parametres.Modele;
    else
        return
    end
    if ~(isstruct(dedans) && isfield(dedans, 'blocs'))
        return
    end
    objets = parcourir(objets, racine, chemin, dedans, niveau, reglage);
end

function oui = repond(objet, critere, attendu, options)
    oui = false;
    try
        obtenu = lire(objet, critere);
    catch
        return
    end
    if (ischar(obtenu) || isstring(obtenu)) && (ischar(attendu) || isstring(attendu))
        obtenu = char(obtenu);
        attendu = char(attendu);
        if strcmpi(char(options.RegExp), 'on')
            if strcmpi(char(options.CaseSensitive), 'off')
                oui = ~isempty(regexpi(obtenu, attendu, 'once'));
            else
                oui = ~isempty(regexp(obtenu, attendu, 'once'));
            end
        elseif strcmpi(char(options.CaseSensitive), 'off')
            oui = strcmpi(obtenu, attendu);
        else
            oui = strcmp(obtenu, attendu);
        end
        return
    end
    oui = matlibre_meme_valeur(obtenu, attendu);
end

% --- enregistrer, remplacer -----------------------------------------------------

% SAVE_SYSTEM(NOM) écrit NOM.slx ; sous un autre nom de fichier, le
% modèle ouvert prend ce nom, comme dans Simulink.
function fichier = enregistrer(nom, fichier, varargin)
    racine = designer(nom);
    modele = modeleNomme(racine);
    if nargin < 2 || isempty(fichier)
        fichier = [racine '.slx'];
    end
    fichier = char(fichier);
    [dossier, base, extension] = fileparts(fichier);
    if isempty(extension)
        extension = '.slx';
        fichier = fullfile(dossier, [base extension]);
    end
    if ~strcmp(base, racine) && any(strcmpi(extension, {'.slx', '.mdl'}))
        if matlibre_sl_ouverts('connu', base)
            error('Simulink:Commands:SaveSysAlreadyOpen', ...
                  ['Le modele ''%s'' ne s''enregistre pas sous le nom ''%s'' : un autre ' ...
                   'modele ouvert porte deja ce nom.'], racine, base);
        end
        figureDuModele = matlibre_sl_ouverts('figure', racine);
        matlibre_sl_ouverts('retirer', racine);
        modele.nom = base;
        matlibre_sl_ouverts('inscrire', base, modele, figureDuModele);
    end
    fichier = save_system(modele, fichier);
    racine = char(modele.nom);
    if matlibre_sl_ouverts('connu', racine)
        matlibre_sl_ouverts('noter', racine, ...
                            struct('Dirty', 'off', 'FileName', cheminAbsolu(fichier)));
    end
end

% REPLACE_BLOCK(SYSTEME,ANCIEN,NOUVEAU) : dans le système et tout ce
% qu'il contient ; rend les chemins des blocs remplacés.
function remplaces = remplacerBlocs(systemeNomme, ancien, nouveau, varargin)
    varargin(cellfun(@(a) (ischar(a) || isstring(a)) && strcmpi(char(a), 'noprompt'), ...
                     varargin)) = [];
    [racine, chemin] = designer(systemeNomme);
    modele = modeleNomme(racine);
    entreeAncien = matlibre_sl_catalogue('type', ancien);
    type = entreeAncien.type;
    avant = chercher(joindre(racine, chemin), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
                     'IncludeCommented', 'on');
    remplaces = {};
    systemes = {chemin};
    for k = 2:numel(avant)
        relatif = avant{k}(numel(racine) + 2:end);
        bloc = blocDe(modele, relatif);
        if strcmp(bloc.type, type)
            remplaces{end + 1, 1} = avant{k}; %#ok<AGROW>
        elseif strcmp(bloc.type, 'subsystem')
            systemes{end + 1} = relatif; %#ok<AGROW>
        end
    end
    % les plus profonds d'abord : un système reposé emporte ce qu'il contient
    [~, ordre] = sort(cellfun(@numel, systemes), 'descend');
    for k = ordre
        [modele, systeme] = systemeDe(modele, systemes{k});
        systeme = replace_block(systeme, ancien, nouveau, varargin{:});
        modele = reposer(modele, systemes{k}, systeme);
    end
    ranger(racine, modele);
end
