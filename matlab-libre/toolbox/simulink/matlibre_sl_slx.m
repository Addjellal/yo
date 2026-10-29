function varargout = matlibre_sl_slx(action, varargin)
%MATLIBRE_SL_SLX Lit et écrit les fichiers de modèle de Simulink, .slx et .mdl.
%   MODELE = MATLIBRE_SL_SLX('lire',FICHIER) lit un modèle enregistré par
%   Simulink et le rend sous la forme de NEW_SYSTEM : ses blocs, leurs
%   paramètres, ses liens, ses sous-systèmes, sa configuration.
%
%   Un .slx est une archive ZIP de fichiers XML, que UNZIP ouvre : le
%   modèle et ses réglages dans simulink/blockdiagram.xml, chaque système
%   dans simulink/systems/system_*.xml — ou, dans les fichiers plus
%   anciens, emboîté dans le premier —, la configuration dans
%   simulink/configSet0.xml. Chaque bloc porte son type (BlockType), son
%   nom, son identifiant (SID) et ceux de ses paramètres qui diffèrent du
%   défaut ; un lien va d'un « SID#out:n » à un « SID#in:m », et se
%   ramifie par ses Branch. Un .mdl dit la même chose en texte, par
%   sections emboîtées « Block { ... } ».
%
%   Un bloc de bibliothèque masqué (BlockType Reference) est reconnu par
%   son chemin, SourceBlock : « simulink/Sources/Ramp » est la rampe de
%   MatLibre. Les paramètres que le catalogue ne connaît pas — la mise en
%   page, les couleurs, les attributs d'affichage — sont laissés de côté ;
%   un bloc dont le type n'a pas d'équivalent est refusé, avec les autres,
%   en une seule erreur qui les nomme tous, plutôt que simulé de travers.
%
%   MATLIBRE_SL_SLX('ecrire',MODELE,FICHIER) écrit le modèle au format
%   .slx, dans la disposition des fichiers de Simulink : blocs, liens par
%   SID, sous-systèmes emboîtés, réglages du solveur. Le fichier se relit
%   par LOAD_SYSTEM.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('petit');
%      m = add_block(m, 'constant', 'c', 'Value', 3);
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      m = add_line(m, 'c', 'g');
%      fichier = [tempname() '.slx'];
%      matlibre_sl_slx('ecrire', m, fichier);
%      relu = matlibre_sl_slx('lire', fichier);
%      get_param(relu, 'g', 'Gain')             % '2'
%
%   Voir aussi LOAD_SYSTEM, SAVE_SYSTEM, UNZIP, ZIP.
    switch lower(char(action))
        case 'lire'
            varargout{1} = lire(varargin{1});
        case 'ecrire'
            ecrire(varargin{1}, varargin{2});
        otherwise
            error('Simulink:slx:Action', 'Action inconnue : %s.', char(action));
    end
end

% === lecture ===================================================================

function modele = lire(fichier)
    fichier = char(fichier);
    if exist(fichier, 'file') ~= 2
        error('Simulink:Commands:OpenSystemUnknownSystem', ...
              'Invalid Simulink object name: ''%s''.', fichier);
    end
    [~, base, extension] = fileparts(fichier);
    if strcmpi(extension, '.mdl')
        D = lireMdl(fichier, base);
    else
        D = lireSlxArchive(fichier, base);
    end
    refuses = {};
    [modele, refuses] = construire(D.systeme, D.nom, D.defauts, refuses);
    if ~isempty(refuses)
        error('Simulink:slx:BlocsNonReconnus', ...
              ['Le modele ''%s'' porte %d bloc(s) sans equivalent dans MatLibre : ' ...
               '%s. Le reste du modele se lirait, mais le simuler sans eux le ' ...
               'fausserait.'], D.nom, numel(refuses), strjoin(refuses, ', '));
    end
    modele = poserConfiguration(modele, D.config);
    % la fiche que le fichier porte, sinon une fiche aux dates inconnues
    if isfield(modele, 'fiche')
        modele = rmfield(modele, 'fiche');
    end
    for nom = matlibre_sl_fiche('noms')
        if isfield(D.config, nom{1}) && ~any(strcmp(nom{1}, {'FileName', 'Dirty'}))
            modele = matlibre_sl_fiche('poser', modele, nom{1}, char(D.config.(nom{1})));
        end
    end
    if isfield(D, 'genre') && ~isempty(D.genre)
        modele.parametres.BlockDiagramType = D.genre;
    end
    if isfield(D, 'espace') && isstruct(D.espace)
        poserEspace(char(modele.nom), D.espace);
    end
end

% L'espace de travail relu : sa source, son code, puis ses variables.
function poserEspace(nom, donnees)
    hws = matlibre_sl_espace('lire', nom);
    for champ = {'DataSource', 'MATLABCode', 'FileName'}
        cle = ['matlibre__' champ{1}];
        if isfield(donnees, cle)
            hws.(champ{1}) = donnees.(cle);
            donnees = rmfield(donnees, cle);
        end
    end
    for variable = fieldnames(donnees).'
        assignin(hws, variable{1}, donnees.(variable{1}));
    end
end

% L'espace de travail du modèle, ses variables et sa source, dans une
% partie à part du .slx, en MAT : objets Simulink.Parameter compris.
function ecrireEspace(modele, fichier)
    nom = char(modele.nom);
    if ~matlibre_sl_espace('existe', nom)
        return
    end
    hws = matlibre_sl_espace('lire', nom);
    donnees = hws.Donnees;
    if isempty(fieldnames(donnees)) && strcmp(hws.DataSource, 'Model File') && ...
       isempty(hws.MATLABCode)
        return
    end
    donnees.matlibre__DataSource = hws.DataSource;
    donnees.matlibre__MATLABCode = hws.MATLABCode;
    donnees.matlibre__FileName = hws.FileName;
    save(fichier, '-struct', 'donnees');
end

% Un .slx : l'archive s'ouvre dans un dossier temporaire, puis chaque
% partie se lit.
function D = lireSlxArchive(fichier, base)
    dossier = tempname();
    mkdir(dossier);
    nettoyage = onCleanup(@() rmdir(dossier, 's')); %#ok<NASGU>
    try
        unzip(fichier, dossier);
    catch err
        error('Simulink:slx:ArchiveIllisible', ...
              'Le fichier ''%s'' n''est pas une archive .slx lisible : %s', fichier, ...
              err.message);
    end
    principal = fullfile(dossier, 'simulink', 'blockdiagram.xml');
    if exist(principal, 'file') ~= 2
        error('Simulink:slx:ArchiveIllisible', ...
              'Le fichier ''%s'' ne porte pas simulink/blockdiagram.xml.', fichier);
    end
    racine = matlibre_xml_analyser(fileread(principal));
    modeleXml = enfant(racine, 'Model');
    genre = '';
    % une bibliothèque, un fichier de sous-système
    for autre = {'Library', 'Subsystem'}
        if isempty(modeleXml)
            modeleXml = enfant(racine, autre{1});
            if ~isempty(modeleXml)
                genre = lower(autre{1});
            end
        end
    end
    if isempty(modeleXml)
        if strcmp(racine.Name, 'Model')
            modeleXml = racine;
        else
            error('Simulink:slx:ArchiveIllisible', ...
                  'simulink/blockdiagram.xml ne porte pas d''element Model.');
        end
    end
    D = struct('nom', base, 'defauts', struct(), 'config', struct(), 'genre', genre);
    if isfield(modeleXml.Attributes, 'Name')
        D.nom = modeleXml.Attributes.Name;
    end
    D.defauts = defautsXml(enfant(modeleXml, 'BlockParameterDefaults'));
    % Un fichier écrit par MatLibre le dit dans une partie à lui, que
    % Simulink ignore : un bloc discret sans période y garde le défaut de
    % MatLibre, le pas, au lieu d'hériter la sienne comme dans Simulink.
    if exist(fullfile(dossier, 'matlibre', 'auteur.xml'), 'file') == 2
        D.defauts.MatLibreAuteur = true;
    end
    D.config = parametresP(modeleXml);
    % La configuration du solveur, dans un configSet à part depuis 2014.
    ensembles = dir(fullfile(dossier, 'simulink', 'configSet*.xml'));
    for k = 1:numel(ensembles)
        texte = fileread(fullfile(ensembles(k).folder, ensembles(k).name));
        D.config = fusionner(D.config, configurationXml(matlibre_xml_analyser(texte)));
    end
    systeme = enfant(modeleXml, 'System');
    dossierSystemes = fullfile(dossier, 'simulink', 'systems');
    if isempty(systeme) || isfield(systeme.Attributes, 'Ref')
        reference = 'system_root';
        if ~isempty(systeme)
            reference = systeme.Attributes.Ref;
        end
        systeme = systemeFichier(dossierSystemes, reference);
    end
    D.systeme = systemeXml(systeme, dossierSystemes);
    % l'espace de travail du modèle, qu'un fichier écrit par MatLibre porte
    D.espace = [];
    if exist(fullfile(dossier, 'matlibre', 'espace.mat'), 'file') == 2
        D.espace = load(fullfile(dossier, 'matlibre', 'espace.mat'));
    end
end

function s = systemeFichier(dossier, reference)
    chemin = fullfile(dossier, [reference '.xml']);
    if exist(chemin, 'file') ~= 2
        error('Simulink:slx:ArchiveIllisible', ...
              'Le systeme ''%s'' manque a l''archive.', reference);
    end
    s = matlibre_xml_analyser(fileread(chemin));
end

% Un système XML devient la forme commune aux deux formats : des blocs —
% type, nom, identifiant, paramètres, système intérieur — et des liens.
function S = systemeXml(noeud, dossierSystemes)
    S = struct('blocs', {{}}, 'liens', {{}});
    for k = 1:numel(noeud.Children)
        e = noeud.Children{k};
        switch e.Name
            case 'Block'
                b = struct('type', attribut(e, 'BlockType', ''), ...
                           'nom', attribut(e, 'Name', ''), ...
                           'sid', attribut(e, 'SID', ''), ...
                           'parametres', parametresP(e), 'interieur', []);
                instance = enfant(e, 'InstanceData');
                if ~isempty(instance)
                    b.parametres = fusionner(b.parametres, parametresP(instance));
                end
                masque = enfant(e, 'Mask');
                if ~isempty(masque)
                    b.parametres = fusionner(b.parametres, parametresMasque(masque));
                end
                b.signaux = portsLus(e, @parametresP);
                sousSysteme = enfant(e, 'System');
                if ~isempty(sousSysteme)
                    if isfield(sousSysteme.Attributes, 'Ref')
                        sousSysteme = systemeFichier(dossierSystemes, sousSysteme.Attributes.Ref);
                    end
                    b.interieur = systemeXml(sousSysteme, dossierSystemes);
                end
                S.blocs{end + 1} = b;
            case 'Line'
                S.liens = [S.liens, liensXml(e, '')];
        end
    end
end

% Un lien et ses branches : une source, et autant de destinations.
function liens = liensXml(e, source, nom)
    if nargin < 3
        nom = '';
    end
    liens = {};
    P = parametresP(e);
    if isfield(P, 'Src')
        source = P.Src;
    end
    if isfield(P, 'Name')
        nom = P.Name;
    end
    if isfield(P, 'Dst') && ~isempty(source)
        liens{end + 1} = struct('source', source, 'destination', P.Dst, 'nom', nom);
    end
    for k = 1:numel(e.Children)
        if strcmp(e.Children{k}.Name, 'Branch')
            liens = [liens, liensXml(e.Children{k}, source, nom)]; %#ok<AGROW>
        end
    end
end

% Les ports de sortie d'un bloc lu, et les réglages de leur signal : son
% nom, sa journalisation. Seuls ceux qui s'écartent des défauts restent.
function signaux = portsLus(e, lire)
    signaux = [];
    rang = 0;
    for k = 1:numel(e.Children)
        port = e.Children{k};
        if ~strcmp(port.Name, 'Port')
            continue
        end
        rang = rang + 1;
        P = lire(port);
        if isfield(P, 'PortType') && ~strcmpi(P.PortType, 'outport')
            continue
        end
        numero = rang;
        if isfield(P, 'PortNumber')
            numero = str2double(P.PortNumber);
        end
        bloc = struct();
        bloc = matlibre_sl_signaux('bloc', bloc, numero, P);
        if isfield(bloc, 'signaux')
            if isempty(signaux)
                signaux = bloc.signaux;
            else
                signaux(end + 1) = bloc.signaux; %#ok<AGROW>
            end
        end
    end
end

function P = parametresP(noeud)
    P = struct();
    for k = 1:numel(noeud.Children)
        e = noeud.Children{k};
        if strcmp(e.Name, 'P') && isfield(e.Attributes, 'Name')
            nom = e.Attributes.Name;
            if isvarname(nom)
                P.(nom) = e.Text;
            end
        end
    end
end

% Le masque d'un bloc : son type, sa description, son code
% d'initialisation, et chaque MaskParameter — son nom, son genre, s'il
% s'évalue, son libellé, sa valeur, ses choix, son rappel. Ils deviennent
% les réglages Mask, MaskVariables, MaskValueString, MaskPrompts,
% MaskStyles... que MatLibre lit.
function P = parametresMasque(masque)
    P = struct();
    S = struct('Name', {}, 'Prompt', {}, 'Type', {}, 'TypeOptions', {}, 'Value', {}, ...
               'Evaluate', {}, 'Tunable', {}, 'Visible', {}, 'Enabled', {}, 'Callback', {});
    reglages = {'Type', 'MaskType'; 'Description', 'MaskDescription'; 'Help', 'MaskHelp'; ...
                'Initialization', 'MaskInitialization'; 'Display', 'MaskDisplay'; ...
                'SelfModifiable', 'MaskSelfModifiable'};
    for k = 1:numel(masque.Children)
        e = masque.Children{k};
        j = find(strcmp(reglages(:, 1), e.Name), 1);
        if ~isempty(j)
            P.(reglages{j, 2}) = e.Text;
            continue
        end
        if ~strcmp(e.Name, 'MaskParameter') || ~isfield(e.Attributes, 'Name')
            continue
        end
        p = struct('Name', e.Attributes.Name, 'Prompt', e.Attributes.Name, ...
                   'Type', attribut(e, 'Type', 'edit'), 'TypeOptions', {{}}, 'Value', '', ...
                   'Evaluate', attribut(e, 'Evaluate', 'on'), ...
                   'Tunable', attribut(e, 'Tunable', 'on'), ...
                   'Visible', attribut(e, 'Visible', 'on'), ...
                   'Enabled', attribut(e, 'Enabled', 'on'), 'Callback', '');
        champs = {'Value', 'Value'; 'Prompt', 'Prompt'; 'Callback', 'Callback'};
        for c = 1:size(champs, 1)
            f = enfant(e, champs{c, 1});
            if ~isempty(f)
                p.(champs{c, 2}) = f.Text;
            end
        end
        options = enfant(e, 'TypeOptions');
        if ~isempty(options)
            for o = 1:numel(options.Children)
                if strcmp(options.Children{o}.Name, 'Option')
                    p.TypeOptions{end + 1} = options.Children{o}.Text;
                end
            end
        end
        S(end + 1) = p; %#ok<AGROW>
    end
    if isempty(S) && isempty(fieldnames(P))
        return
    end
    b = matlibre_sl_masque('ecrire', struct('nom', '', 'parametres', struct()), S);
    for nom = fieldnames(b.parametres).'
        P.(nom{1}) = b.parametres.(nom{1});
    end
end

function v = attribut(e, nom, defaut)
    v = defaut;
    if isfield(e.Attributes, nom)
        v = e.Attributes.(nom);
    end
end

function defauts = defautsXml(noeud)
    defauts = struct();
    if isempty(noeud)
        return
    end
    for k = 1:numel(noeud.Children)
        e = noeud.Children{k};
        if strcmp(e.Name, 'Block')
            type = attribut(e, 'BlockType', '');
            if isvarname(type)
                defauts.(type) = parametresP(e);
            end
        end
    end
end

% Les réglages du solveur, d'où qu'ils viennent : les P d'un objet
% Simulink.SolverCC, ou des objets qu'il contient.
function C = configurationXml(noeud)
    C = struct();
    if strcmp(noeud.Name, 'Object') || strcmp(noeud.Name, 'Array') || ...
       ~isempty(noeud.Children)
        C = parametresP(noeud);
    end
    for k = 1:numel(noeud.Children)
        C = fusionner(C, configurationXml(noeud.Children{k}));
    end
end

% --- le format texte .mdl ---------------------------------------------------

function D = lireMdl(fichier, base)
    texte = fileread(fichier);
    jetons = jetonsMdl(texte);
    [arbre, ~] = sectionMdl(jetons, 1, 'Racine');
    modeleMdl = enfant(arbre, 'Model');
    if isempty(modeleMdl)
        error('Simulink:slx:ArchiveIllisible', ...
              'Le fichier ''%s'' ne porte pas de section Model.', fichier);
    end
    D = struct('nom', base, 'defauts', struct(), 'config', struct());
    P = parametresMdl(modeleMdl);
    if isfield(P, 'Name')
        D.nom = P.Name;
    end
    D.config = P;
    defauts = enfant(modeleMdl, 'BlockParameterDefaults');
    if ~isempty(defauts)
        for k = 1:numel(defauts.Children)
            e = defauts.Children{k};
            if strcmp(e.Name, 'Block')
                Q = parametresMdl(e);
                if isfield(Q, 'BlockType') && isvarname(Q.BlockType)
                    D.defauts.(Q.BlockType) = Q;
                end
            end
        end
    end
    % La configuration, dans les .mdl récents, vit dans un Simulink.ConfigSet.
    for k = 1:numel(modeleMdl.Children)
        if any(strcmp(modeleMdl.Children{k}.Name, {'Array', 'Object'}))
            D.config = fusionner(D.config, configurationMdl(modeleMdl.Children{k}));
        end
    end
    D.systeme = systemeMdl(enfant(modeleMdl, 'System'));
end

function C = configurationMdl(noeud)
    C = parametresMdl(noeud);
    for k = 1:numel(noeud.Children)
        C = fusionner(C, configurationMdl(noeud.Children{k}));
    end
end

function S = systemeMdl(noeud)
    S = struct('blocs', {{}}, 'liens', {{}});
    if isempty(noeud)
        return
    end
    for k = 1:numel(noeud.Children)
        e = noeud.Children{k};
        switch e.Name
            case 'Block'
                P = parametresMdl(e);
                b = struct('type', champTexte(P, 'BlockType'), 'nom', champTexte(P, 'Name'), ...
                           'sid', champTexte(P, 'Name'), 'parametres', P, 'interieur', []);
                b.signaux = portsLus(e, @parametresMdl);
                sousSysteme = enfant(e, 'System');
                if ~isempty(sousSysteme)
                    b.interieur = systemeMdl(sousSysteme);
                end
                S.blocs{end + 1} = b;
            case 'Line'
                S.liens = [S.liens, liensMdl(e, '')];
        end
    end
end

% Un lien de .mdl nomme ses blocs : « SrcBlock "Gain" » et « SrcPort 1 ».
% On le ramène à l'écriture du .slx, « nom#out:1 ».
function liens = liensMdl(e, source, nom)
    if nargin < 3
        nom = '';
    end
    liens = {};
    P = parametresMdl(e);
    if isfield(P, 'Name')
        nom = P.Name;
    end
    if isfield(P, 'SrcBlock')
        port = '1';
        if isfield(P, 'SrcPort')
            port = P.SrcPort;
        end
        source = sprintf('%s#out:%s', P.SrcBlock, port);
    end
    if isfield(P, 'DstBlock') && ~isempty(source)
        port = '1';
        if isfield(P, 'DstPort')
            port = P.DstPort;
        end
        if all(isstrprop(port, 'digit'))
            destination = sprintf('%s#in:%s', P.DstBlock, port);
        else
            destination = sprintf('%s#%s', P.DstBlock, port);
        end
        liens{end + 1} = struct('source', source, 'destination', destination, 'nom', nom);
    end
    for k = 1:numel(e.Children)
        if strcmp(e.Children{k}.Name, 'Branch')
            liens = [liens, liensMdl(e.Children{k}, source, nom)]; %#ok<AGROW>
        end
    end
end

function P = parametresMdl(noeud)
    P = struct();
    for k = 1:size(noeud.Attributes, 1)
        nom = noeud.Attributes{k, 1};
        if isvarname(nom)
            P.(nom) = noeud.Attributes{k, 2};
        end
    end
end

% Les jetons d'un .mdl : des mots, des chaînes entre guillemets — que des
% chaînes voisines prolongent —, des tableaux entre crochets, et les
% accolades des sections.
function jetons = jetonsMdl(texte)
    jetons = {};
    i = 1;
    n = numel(texte);
    while i <= n
        c = texte(i);
        if isspace(c)
            i = i + 1;
        elseif c == '#'
            fin = find(texte(i:end) == sprintf('\n'), 1);
            if isempty(fin), break; end
            i = i + fin;
        elseif c == '{' || c == '}'
            jetons{end + 1} = struct('genre', c, 'texte', c); %#ok<AGROW>
            i = i + 1;
        elseif c == '"'
            valeur = '';
            while i <= n && texte(i) == '"'
                j = i + 1;
                while j <= n && texte(j) ~= '"'
                    if texte(j) == '\' && j < n
                        j = j + 1;
                    end
                    j = j + 1;
                end
                valeur = [valeur, desechapperMdl(texte(i + 1:j - 1))]; %#ok<AGROW>
                i = j + 1;
                % Une chaîne continuée à la ligne suivante : "abc" \n "def".
                k = i;
                while k <= n && isspace(texte(k))
                    k = k + 1;
                end
                if k <= n && texte(k) == '"'
                    i = k;
                end
            end
            jetons{end + 1} = struct('genre', 's', 'texte', valeur); %#ok<AGROW>
        elseif c == '['
            profondeur = 0;
            j = i;
            while j <= n
                if texte(j) == '['
                    profondeur = profondeur + 1;
                elseif texte(j) == ']'
                    profondeur = profondeur - 1;
                    if profondeur == 0
                        break
                    end
                end
                j = j + 1;
            end
            jetons{end + 1} = struct('genre', 'w', 'texte', texte(i:j)); %#ok<AGROW>
            i = j + 1;
        else
            j = i;
            while j <= n && ~isspace(texte(j)) && ~any(texte(j) == '{}"')
                j = j + 1;
            end
            jetons{end + 1} = struct('genre', 'w', 'texte', texte(i:j - 1)); %#ok<AGROW>
            i = j;
        end
    end
end

function t = desechapperMdl(t)
    t = strrep(t, '\"', '"');
    t = strrep(t, '\n', sprintf('\n'));
    t = strrep(t, '\t', sprintf('\t'));
    t = strrep(t, '\\', '\');
end

% Une section : des couples « clé valeur » et des sous-sections
% « Nom { ... } ». Les couples sont rangés en attributs, les sections en
% enfants — la forme de l'arbre XML.
function [noeud, i] = sectionMdl(jetons, i, nom)
    noeud = struct('Name', nom, 'Attributes', {cell(0, 2)}, 'Children', {{}}, 'Text', '');
    while i <= numel(jetons)
        j = jetons{i};
        if j.genre == '}'
            i = i + 1;
            return
        end
        if i + 1 <= numel(jetons) && jetons{i + 1}.genre == '{'
            [sous, i] = sectionMdl(jetons, i + 2, j.texte);
            noeud.Children{end + 1} = sous;
            continue
        end
        if i + 1 <= numel(jetons) && jetons{i + 1}.genre ~= '}'
            noeud.Attributes(end + 1, :) = {j.texte, jetons{i + 1}.texte};
            i = i + 2;
        else
            i = i + 1;
        end
    end
end

% --- du système lu au modèle de MatLibre -------------------------------------

% Les paramètres qui ne disent rien du calcul : la mise en page, l'aspect,
% l'identité du bloc. Ils ne sont pas repris.
function oui = structurel(nom)
    oui = any(strcmp(nom, {'BlockType', 'Name', 'SID', 'Ports', 'ZOrder', 'Position', ...
        'SourceBlock', 'SourceType', 'SourceProductName', 'SourceProductBaseCode', ...
        'LibraryVersion', 'BackgroundColor', 'ForegroundColor', 'ShowName', ...
        'NamePlacement', 'FontName', 'FontSize', 'DropShadow', 'Orientation', ...
        'IconDisplay', 'ContentPreviewEnabled', 'RequestExecContextInheritance', ...
        'SFBlockType', 'MaskHideContents', 'PortBlocksUseCompactNotation', ...
        'Priority', 'Tag', 'Description', 'ShowPortLabels', 'BlockMirror', ...
        'BlockRotation', 'TreatAsAtomicUnit', 'SystemSampleTime', ...
        'MinAlgLoopOccurrences', 'PropExecContextOutsideSubsystem', ...
        'CheckFcnCallInpInsideContextMsg', 'Permissions', 'ErrorFcn', ...
        'PermitHierarchicalResolution', 'SimViewingDevice', 'DataTypeOverride', ...
        'MinMaxOverflowLogging', 'Opaque', 'MaskType', 'MaskDescription'}));
end

function [modele, refuses] = construire(S, nom, defauts, refuses)
    modele = new_system(nomSysteme(nom));
    sids = {};
    for k = 1:numel(S.blocs)
        b = S.blocs{k};
        [type, refus] = typeDe(b);
        if ~isempty(refus)
            refuses{end + 1} = sprintf('''%s'' (%s)', b.nom, refus); %#ok<AGROW>
            sids{end + 1} = b.sid; %#ok<AGROW>
            modele.blocs{end + 1} = struct('type', 'terminator', 'nom', b.nom, ...
                                           'parametres', struct()); %#ok<AGROW>
            continue
        end
        entree = matlibre_sl_catalogue('type', type);
        parametres = struct();
        % Les défauts du fichier d'abord, puis les valeurs du bloc.
        if isvarname(b.type) && isfield(defauts, b.type)
            parametres = reprendre(parametres, entree, defauts.(b.type));
        end
        parametres = reprendre(parametres, entree, b.parametres);
        if ~isfield(defauts, 'MatLibreAuteur')
            parametres = defautsSimulink(entree.type, parametres);
        end
        if isfield(b.parametres, 'Position')
            cadre = str2num(b.parametres.Position); %#ok<ST2NM>
            if numel(cadre) == 4
                parametres.Position = cadre / 40;
            end
        end
        if strcmp(entree.type, 'subsystem')
            interieur = b.interieur;
            if isempty(interieur)
                interieur = struct('blocs', {{}}, 'liens', {{}});
            end
            [sousModele, refuses] = construire(interieur, b.nom, defauts, refuses);
            parametres.Model = sousModele;
        end
        modele.blocs{end + 1} = struct('type', entree.type, 'nom', b.nom, ...
                                       'parametres', parametres); %#ok<AGROW>
        if isfield(b, 'signaux') && ~isempty(b.signaux)
            modele.blocs{end}.signaux = b.signaux;
        end
        sids{end + 1} = b.sid; %#ok<AGROW>
    end
    for k = 1:numel(S.liens)
        [a, ps] = extremite(S.liens{k}.source, sids, S.blocs);
        [d, pe] = extremite(S.liens{k}.destination, sids, S.blocs);
        if a == 0 || d == 0
            continue
        end
        if ischar(ps) && ischar(pe) && ~isempty(regexp(ps, '^[lr]conn:\d+$', 'once')) && ...
           ~isempty(regexp(pe, '^[lr]conn:\d+$', 'once'))
            % une connexion physique
            code = @(t) str2double(t(7:end)) * (1 - 2 * (t(1) == 'r'));
            if ~isfield(modele, 'connexions')
                modele.connexions = zeros(0, 4);
            end
            modele.connexions(end + 1, :) = [a, code(ps), d, code(pe)];
            continue
        end
        pe = portDeDestination(modele.blocs{d}, pe);
        if ischar(ps)
            % le port d'état d'un intégrateur : sa dernière sortie
            if strcmp(ps, 'state') && strcmp(modele.blocs{a}.type, 'integrator')
                [~, ps] = matlibre_sl_ports(modele.blocs{a}, 'integrator');
            else
                ps = [];
            end
        end
        if isempty(pe) || isempty(ps)
            continue
        end
        modele.liens(end + 1, :) = [a, d, pe, ps];
        % Le nom d'un lien est celui du signal : il va au port d'où il part,
        % à moins que le port n'en porte déjà un.
        if isfield(S.liens{k}, 'nom') && ~isempty(S.liens{k}.nom)
            if ~isfield(modele.blocs{a}, 'signaux') || ...
               ~any([modele.blocs{a}.signaux.Port] == ps & ...
                    ~cellfun(@isempty, {modele.blocs{a}.signaux.Name}))
                modele.blocs{a} = matlibre_sl_signaux('bloc', modele.blocs{a}, ps, ...
                                                      struct('Name', S.liens{k}.nom));
            end
        end
    end
end

function nom = nomSysteme(nom)
    nom = char(nom);
    if isempty(nom)
        nom = 'modele';
    end
end

% Le type MatLibre d'un bloc lu : par son BlockType, ou pour un bloc de
% bibliothèque par son chemin. REFUS dit pourquoi il n'y en a pas.
function [type, refus] = typeDe(b)
    type = '';
    refus = '';
    P = b.parametres;
    if strcmp(b.type, 'SubSystem') && isfield(P, 'SFBlockType') && ...
       ~any(strcmp(P.SFBlockType, {'NONE', ''}))
        refus = sprintf('SubSystem %s : son contenu Stateflow n''est pas lu', P.SFBlockType);
        return
    end
    candidats = {b.type};
    if strcmp(b.type, 'SubSystem') && isfield(P, 'ReferencedSubsystem')
        candidats = {'Subsystem Reference'};   % un sous-système qui désigne son fichier
    end
    if any(strcmp(b.type, {'Inport', 'Outport'})) && isfield(P, 'IsBusElementPort') && ...
       strcmpi(char(P.IsBusElementPort), 'on')
        % un port d'élément de bus : In Bus Element, Out Bus Element
        candidats = {strrep(strrep(b.type, 'Inport', 'In Bus Element'), 'Outport', ...
                            'Out Bus Element')};
    end
    if any(strcmp(b.type, {'Reference', 'SimscapeBlock'})) && isfield(P, 'SourceBlock')
        source = regexprep(P.SourceBlock, '\\n|\n', ' ');
        candidats = {source};
    elseif strcmp(b.type, 'SimscapeBlock')
        % un bloc Simscape sans chemin : son composant le nomme
        composant = '';
        for champ = {'ComponentPath', 'SourceFile'}
            if isfield(P, champ{1})
                composant = char(P.(champ{1}));
            end
        end
        candidats = {matlibre_sl_physique('composant', composant)};
    end
    for k = 1:numel(candidats)
        try
            entree = matlibre_sl_catalogue('type', candidats{k});
            if strcmp(entree.famille, 'Interne')
                break
            end
            type = entree.type;
            return
        catch
        end
    end
    refus = candidats{1};
end

% Les paramètres d'un bloc lu que le catalogue connaît, sous leur nom
% canonique. Les valeurs restent du texte : ce sont des expressions,
% évaluées au moment de simuler, comme dans Simulink.
function parametres = reprendre(parametres, entree, P)
    noms = fieldnames(P);
    for k = 1:numel(noms)
        if structurel(noms{k})
            continue
        end
        canon = matlibre_sl_catalogue('parametre', entree, noms{k});
        if isempty(canon) || any(strcmp(canon, parametresCommunsIgnores()))
            continue
        end
        valeur = P.(noms{k});
        if ischar(valeur)
            valeur = strtrim(valeur);
        end
        parametres.(canon) = valeur;
    end
end

function noms = parametresCommunsIgnores()
    noms = {'Position', 'Orientation', 'ForegroundColor', 'BackgroundColor', ...
            'ShowName', 'Description', 'Tag', 'Priority', 'NamePlacement', ...
            'FontSize', 'FontName', 'DropShadow', 'AttributesFormatString', 'UserData'};
end

% Quand le fichier ne dit rien, c'est le défaut de Simulink qui vaut : un
% bloc discret hérite sa période (-1), là où MatLibre prend le pas.
function parametres = defautsSimulink(type, parametres)
    if any(strcmp(type, {'delay', 'zoh', 'discreteintegrator', 'discretetransferfcn', ...
                         'discretefilter', 'discretestatespace'})) && ...
       ~isfield(parametres, 'SampleTime')
        parametres.SampleTime = -1;
    end
end

% « 12#out:1 », « 12#in:2 », « 12#enable » : le bloc et son port.
function [k, port] = extremite(texte, sids, blocs)
    k = 0;
    port = 1;
    diese = find(texte == '#', 1, 'last');
    if isempty(diese)
        return
    end
    identifiant = texte(1:diese - 1);
    k = find(strcmp(sids, identifiant), 1);
    if isempty(k)
        % Un .mdl nomme le bloc ; un SID peut aussi manquer.
        k = find(cellfun(@(b) strcmp(b.nom, identifiant), blocs), 1);
    end
    if isempty(k)
        k = 0;
        return
    end
    suite = texte(diese + 1:end);
    jetons = regexp(suite, '^(out|in):(\d+)$', 'tokens', 'once');
    if ~isempty(jetons)
        port = str2double(jetons{2});
    else
        port = lower(regexprep(suite, '^out:', ''));   % enable, trigger, ifaction, state
    end
end

% Le port d'entrée d'un lien : son numéro, ou pour un port de contrôle son
% rang parmi les entrées du sous-système, après ses INPORT.
function pe = portDeDestination(bloc, pe)
    if isnumeric(pe)
        return
    end
    if ~strcmp(bloc.type, 'subsystem') || ~isfield(bloc.parametres, 'Model')
        pe = [];
        return
    end
    interne = bloc.parametres.Model;
    types = cellfun(@(b) b.type, interne.blocs, 'UniformOutput', false);
    ordre = {};
    for candidat = {'enableport', 'triggerport', 'actionport', 'resetport'}
        if any(strcmp(types, candidat{1}))
            ordre{end + 1} = candidat{1}; %#ok<AGROW>
        end
    end
    voulu = struct('enable', 'enableport', 'trigger', 'triggerport', 'ifaction', 'actionport', ...
                   'reset', 'resetport');
    if ~isfield(voulu, pe)
        pe = [];
        return
    end
    rang = find(strcmp(ordre, voulu.(pe)), 1);
    if isempty(rang)
        pe = [];
        return
    end
    pe = sum(strcmp(types, 'inport')) + rang;
end

% Les réglages du modèle que MatLibre connaît. Un solveur que MatLibre
% n'a pas cède la place au solveur automatique du même type, en le
% disant.
function modele = poserConfiguration(modele, C)
    noms = fieldnames(matlibre_sl_config('defauts'));
    lus = fieldnames(C);
    for k = 1:numel(lus)
        canon = noms(strcmpi(noms, lus{k}));
        if isempty(canon)
            continue
        end
        canon = canon{1};
        valeur = strtrim(char(C.(lus{k})));
        if strcmp(canon, 'Solver')
            try
                matlibre_sl_config('valider', 'Solver', valeur);
            catch
                type = 'Variable-step';
                if isfield(C, 'SolverType')
                    type = char(C.SolverType);
                end
                remplacant = matlibre_sl_config('automatique', type);
                warning('Simulink:slx:SolveurRemplace', ...
                        ['Le modele ''%s'' demande le solveur %s, que MatLibre n''a pas : ' ...
                         '%s le remplace.'], modele.nom, valeur, remplacant);
                valeur = remplacant;
            end
        end
        try
            modele = set_param(modele, canon, valeur);
        catch
            % une valeur que MatLibre ne sait pas lire garde le défaut
        end
    end
    if ~isfield(C, 'Solver') && ~isfield(C, 'SolverType')
        modele = set_param(modele, 'Solver', 'VariableStepAuto');   % le défaut de Simulink
    end
end

% --- petits outils -----------------------------------------------------------

function e = enfant(noeud, nom)
    e = [];
    if isempty(noeud)
        return
    end
    for k = 1:numel(noeud.Children)
        if strcmp(noeud.Children{k}.Name, nom)
            e = noeud.Children{k};
            return
        end
    end
end

function v = attribut(noeud, nom, defaut)
    v = defaut;
    if isfield(noeud.Attributes, nom)
        v = noeud.Attributes.(nom);
    end
end

function t = champTexte(P, nom)
    t = '';
    if isfield(P, nom)
        t = char(P.(nom));
    end
end

function a = fusionner(a, b)
    noms = fieldnames(b);
    for k = 1:numel(noms)
        a.(noms{k}) = b.(noms{k});
    end
end

% === écriture ==================================================================

function ecrire(modele, fichier)
    modele = matlibre_sl_modele(modele);
    fichier = char(fichier);
    dossier = tempname();
    mkdir(dossier);
    nettoyage = onCleanup(@() rmdir(dossier, 's')); %#ok<NASGU>
    mkdir(fullfile(dossier, 'simulink'));
    mkdir(fullfile(dossier, '_rels'));
    ecrireTexte(fullfile(dossier, '[Content_Types].xml'), ...
        ['<?xml version="1.0" encoding="utf-8"?>' sprintf('\n') ...
         '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' ...
         '<Default Extension="rels" ContentType="application/' ...
         'vnd.openxmlformats-package.relationships+xml"/>' ...
         '<Default Extension="xml" ContentType="application/' ...
         'vnd.mathworks.simulink.model+xml"/></Types>']);
    ecrireTexte(fullfile(dossier, '_rels', '.rels'), ...
        ['<?xml version="1.0" encoding="utf-8"?>' sprintf('\n') ...
         '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/' ...
         'relationships"><Relationship Id="blockDiagram" Target="simulink/' ...
         'blockdiagram.xml" Type="http://schemas.mathworks.com/simulink/2010/' ...
         'relationships/blockDiagram"/></Relationships>']);
    lignes = {'<?xml version="1.0" encoding="utf-8"?>', ...
              '<ModelInformation Version="1.0">', ...
              sprintf('  <%s Name="%s">', elementDiagramme(modele), ...
                      matlibre_xml_echapper(modele.nom))};
    config = matlibre_sl_config('lire', modele);
    toujours = {'StartTime', 'StopTime', 'SolverType', 'Solver', 'FixedStep', 'RelTol', ...
                'AbsTol', 'MaxStep', 'MinStep', 'InitialStep', 'ZeroCrossControl', ...
                'AlgebraicLoopMsg'};
    % Les autres réglages — rappels, entrées externes, options d'un
    % solveur — s'écrivent quand ils ne valent pas leur défaut.
    defauts = matlibre_sl_config('defauts');
    for nom = fieldnames(config).'
        if ~any(strcmp(nom{1}, toujours)) && isequal(config.(nom{1}), defauts.(nom{1}))
            continue
        end
        texte = texteValeur(config.(nom{1}));
        if isstruct(config.(nom{1}))
            texte = texteStructure(config.(nom{1}));   % SampleTimeProperty
        end
        lignes{end + 1} = sprintf('    <P Name="%s">%s</P>', nom{1}, ...
                                  matlibre_xml_echapper(texte)); %#ok<AGROW>
    end
    % la fiche du modèle, hors FileName et Dirty, que le chargement pose
    if isfield(modele, 'fiche') && isstruct(modele.fiche)
        for nom = fieldnames(modele.fiche).'
            if any(strcmp(nom{1}, {'FileName', 'Dirty'}))
                continue
            end
            lignes{end + 1} = sprintf('    <P Name="%s">%s</P>', nom{1}, ...
                                      matlibre_xml_echapper(char(modele.fiche.(nom{1})))); %#ok<AGROW>
        end
    end
    compteur = 0;
    [lignes, ~] = ecrireSysteme(modele, lignes, '    ', compteur);
    lignes = [lignes, {sprintf('  </%s>', elementDiagramme(modele)), '</ModelInformation>'}];
    ecrireTexte(fullfile(dossier, 'simulink', 'blockdiagram.xml'), strjoin(lignes, sprintf('\n')));
    mkdir(fullfile(dossier, 'matlibre'));
    ecrireTexte(fullfile(dossier, 'matlibre', 'auteur.xml'), ...
                ['<?xml version="1.0" encoding="utf-8"?>' sprintf('\n') '<MatLibre Version="1"/>']);
    ecrireEspace(modele, fullfile(dossier, 'matlibre', 'espace.mat'));
    if exist(fichier, 'file') == 2
        delete(fichier);
    end
    zip(fichier, {'[Content_Types].xml', '_rels', 'simulink', 'matlibre'}, dossier);
    [dossierFichier, base, extension] = fileparts(fichier);
    if ~strcmpi(extension, '.slx')
        % ZIP ajoute « .zip » à un nom sans extension ; .slx en porte une.
        movefile(fullfile(dossierFichier, [base extension '.zip']), fichier);
    end
end

% Un système, emboîté : ses blocs, chacun avec un SID, puis ses liens.
function [lignes, compteur] = ecrireSysteme(modele, lignes, marge, compteur)
    lignes{end + 1} = [marge '<System>'];
    sids = zeros(1, numel(modele.blocs));
    for k = 1:numel(modele.blocs)
        compteur = compteur + 1;
        sids(k) = compteur;
        b = modele.blocs{k};
        entree = matlibre_sl_catalogue('type', b.type);
        typeSimulink = entree.simulink;
        if strcmp(entree.type, 'subsystemreference')
            typeSimulink = 'SubSystem';   % un sous-système qui désigne son fichier
            if ~isfield(b.parametres, 'ReferencedSubsystem')
                b.parametres.ReferencedSubsystem = '';   % vide, il reste une référence
            end
        end
        reference = '';
        if (referenceDeBibliotheque(entree.type) || strcmp(typeSimulink, 'SimscapeBlock')) && ...
           ~isempty(entree.chemins)
            if ~strcmp(typeSimulink, 'SimscapeBlock')
                typeSimulink = 'Reference';
            end
            reference = entree.chemins{1};
        end
        if strcmp(entree.type, 'secondorderintegratorlimited')
            % la variante bornée s'écrit comme Simulink la range : un
            % Second-Order Integrator dont les bornes sont dites
            for q = {'LimitX', 'UpperLimitX', 'LowerLimitX', 'LimitDXDT'}
                if ~isfield(b.parametres, q{1})
                    b.parametres.(q{1}) = entree.params{strcmp(entree.params(:, 1), q{1}), 2};
                end
            end
        end
        if strcmp(entree.type, 'selector')
            b.parametres = parametresSelecteur(b.parametres);
        end
        lignes{end + 1} = sprintf('%s  <Block BlockType="%s" Name="%s" SID="%d">', marge, ...
                                  typeSimulink, matlibre_xml_echapper(b.nom), sids(k)); %#ok<AGROW>
        if ~isempty(reference)
            lignes{end + 1} = sprintf('%s    <P Name="SourceBlock">%s</P>', marge, ...
                                      matlibre_xml_echapper(reference)); %#ok<AGROW>
        end
        if any(strcmp(entree.type, {'inbuselement', 'outbuselement'}))
            lignes{end + 1} = sprintf('%s    <P Name="IsBusElementPort">on</P>', marge); %#ok<AGROW>
        end
        champs = fieldnames(b.parametres);
        masque = matlibre_sl_masque('estmasque', b) && strcmp(entree.type, 'subsystem');
        for j = 1:numel(champs)
            valeur = b.parametres.(champs{j});
            if strcmp(champs{j}, 'Model') || (masque && strncmp(champs{j}, 'Mask', 4))
                continue   % le masque s'écrit à part, comme Simulink le range
            end
            if strcmp(champs{j}, 'Position')
                valeur = round(double(valeur) * 40);
            end
            texte = texteValeur(valeur);
            if isstruct(valeur) && any(strcmp(champs{j}, {'ParameterArgumentValues', ...
                                                           'InstanceParameters'}))
                texte = texteStructure(valeur);   % les arguments d'un bloc Model
            end
            if isempty(texte) && ~ischar(valeur)
                continue   % une valeur que le texte ne rend pas : une machine, un objet
            end
            lignes{end + 1} = sprintf('%s    <P Name="%s">%s</P>', marge, champs{j}, ...
                                      matlibre_xml_echapper(texte)); %#ok<AGROW>
        end
        if matlibre_sl_masque('estmasque', b) && strcmp(entree.type, 'subsystem')
            lignes = ecrireMasque(b, lignes, marge);
        end
        if isfield(b, 'signaux')
            % Les signaux qui partent du bloc, comme Simulink les range :
            % un Port par sortie réglée, avec ce qui s'écarte des défauts.
            defauts = matlibre_sl_signaux('defauts');
            for j = 1:numel(b.signaux)
                lignes{end + 1} = [marge '    <Port>']; %#ok<AGROW>
                lignes{end + 1} = sprintf('%s      <P Name="PortNumber">%d</P>', marge, ...
                                          b.signaux(j).Port); %#ok<AGROW>
                for nom = fieldnames(defauts).'
                    valeur = b.signaux(j).(nom{1});
                    if ~isequal(valeur, defauts.(nom{1}))
                        lignes{end + 1} = sprintf('%s      <P Name="%s">%s</P>', marge, ...
                                                  nom{1}, matlibre_xml_echapper(valeur)); %#ok<AGROW>
                    end
                end
                lignes{end + 1} = [marge '    </Port>']; %#ok<AGROW>
            end
        end
        if strcmp(entree.type, 'subsystem') && isfield(b.parametres, 'Model')
            [lignes, compteur] = ecrireSysteme(matlibre_sl_modele(b.parametres.Model), ...
                                               lignes, [marge '    '], compteur);
        end
        lignes{end + 1} = [marge '  </Block>']; %#ok<AGROW>
    end
    liens = matlibre_sl_liens(modele);
    for l = 1:size(liens, 1)
        destination = sprintf('%d#in:%d', sids(liens(l, 2)), liens(l, 3));
        cible = modele.blocs{liens(l, 2)};
        controle = portDeControleEcrit(cible, liens(l, 3));
        if ~isempty(controle)
            destination = sprintf('%d#%s', sids(liens(l, 2)), controle);
        end
        source = sprintf('%d#out:%d', sids(liens(l, 1)), liens(l, 4));
        if portEtatEcrit(modele.blocs{liens(l, 1)}, liens(l, 4))
            source = sprintf('%d#state', sids(liens(l, 1)));
        end
        lignes{end + 1} = sprintf('%s  <Line>', marge); %#ok<AGROW>
        nomSignal = matlibre_sl_signaux('nom', modele.blocs{liens(l, 1)}, liens(l, 4));
        if ~isempty(nomSignal)
            lignes{end + 1} = sprintf('%s    <P Name="Name">%s</P>', marge, ...
                                      matlibre_xml_echapper(nomSignal)); %#ok<AGROW>
        end
        lignes{end + 1} = sprintf('%s    <P Name="Src">%s</P>', marge, source); %#ok<AGROW>
        lignes{end + 1} = sprintf('%s    <P Name="Dst">%s</P>', marge, destination); %#ok<AGROW>
        lignes{end + 1} = sprintf('%s  </Line>', marge); %#ok<AGROW>
    end
    if isfield(modele, 'connexions')
        % une connexion physique : « 12#lconn:1 » vers « 14#rconn:1 »
        for l = 1:size(modele.connexions, 1)
            c = modele.connexions(l, :);
            lignes{end + 1} = sprintf('%s  <Line>', marge); %#ok<AGROW>
            lignes{end + 1} = sprintf('%s    <P Name="Src">%d#%s</P>', marge, sids(c(1)), ...
                                      lower(regexprep(matlibre_sl_physique('nomPort', c(2)), ...
                                                      '(\d+)$', ':$1'))); %#ok<AGROW>
            lignes{end + 1} = sprintf('%s    <P Name="Dst">%d#%s</P>', marge, sids(c(3)), ...
                                      lower(regexprep(matlibre_sl_physique('nomPort', c(4)), ...
                                                      '(\d+)$', ':$1'))); %#ok<AGROW>
            lignes{end + 1} = sprintf('%s  </Line>', marge); %#ok<AGROW>
        end
    end
    lignes{end + 1} = [marge '</System>'];
end

% Les blocs que Simulink range dans sa bibliothèque comme des sous-systèmes
% masqués : dans un fichier, ils sont des Reference à leur chemin.
function oui = referenceDeBibliotheque(type)
    oui = any(strcmp(type, {'ramp', 'comparetoconstant', 'comparetozero', ...
                            'detectchange', 'detectincrease', 'detectdecrease', ...
                            'coulombfriction', 'pidcontroller', 'repeatingsequence', ...
                            'chirp', 'bandlimitedwhitenoise', 'counterfreerunning', ...
                            'counterlimited', 'repeatingsequencestair', 'wraptozero', ...
                            'saturationdynamic', 'deadzonedynamic', 'intervaltest', ...
                            'discretederivative', 'difference', 'tappeddelay', 'xygraph', ...
                            'functioncallgenerator', 'detectrisepositive', ...
                            'detectrisenonnegative', 'detectfallnegative', ...
                            'detectfallnonpositive', 'intervaltestdynamic', ...
                            'bitwiseoperator', 'bitset', 'bitclear', 'sinewavefunction', ...
                            'lookuptabledynamic', 'sinecosine', 'transferfcnfirstorder', ...
                            'transferfcnleadorlag', 'transferfcnrealzero', ...
                            'environmentcontroller', 'checkstaticrange', ...
                            'checkstaticlowerbound', 'checkstaticupperbound', ...
                            'checkstaticgap', 'checkdynamicrange', 'checkdynamiclowerbound', ...
                            'checkdynamicupperbound', 'checkdynamicgap', ...
                            'ratelimiterdynamic', 'minmaxrunningresettable', ...
                            'firstorderhold', 'repeatingsequenceinterpolated', ...
                            'signaleditor', 'transpose', 'hermitiantranspose', ...
                            'creatediagonalmatrix', 'extractdiagonal', 'matrixsquare', ...
                            'crossproduct', 'identitymatrix', 'expandscalar', 'ishermitian', ...
                            'issymmetric', 'istriangular', 'permutematrix', 'submatrix', ...
                            'incrementrealworld', 'decrementrealworld', ...
                            'incrementstoredinteger', 'decrementstoredinteger', ...
                            'decrementtozero', 'decrementtimetozero', ...
                            'checkdiscretegradient', 'checkinputresolution', ...
                            'transferfcndirectformii', 'datatypescalingstrip', 'docblock', ...
                            'modelinfo'}));
end

% La sortie PORT d'un intégrateur est-elle son port d'état ? Simulink
% l'écrit à part, « SID#state ».
function oui = portEtatEcrit(bloc, port)
    oui = false;
    try
        entree = matlibre_sl_catalogue('type', bloc.type);
    catch
        return
    end
    if ~strcmp(entree.type, 'integrator')
        return
    end
    montre = false;
    for champ = fieldnames(bloc.parametres).'
        if strcmpi(champ{1}, 'ShowStatePort')
            montre = strcmpi(char(bloc.parametres.(champ{1})), 'on');
        end
    end
    [~, ns] = matlibre_sl_ports(bloc, 'integrator');
    oui = montre && port == ns;
end

% Le nom Simulink du port de contrôle qu'est l'entrée PORT d'un
% sous-système, ou '' pour une entrée ordinaire.
function nom = portDeControleEcrit(bloc, port)
    nom = '';
    if ~strcmp(bloc.type, 'subsystem') || ~isfield(bloc.parametres, 'Model')
        return
    end
    interne = matlibre_sl_modele(bloc.parametres.Model);
    types = cellfun(@(b) b.type, interne.blocs, 'UniformOutput', false);
    nEntrees = sum(strcmp(types, 'inport'));
    if port <= nEntrees
        return
    end
    ordre = {};
    noms = {};
    paires = {'enableport', 'enable'; 'triggerport', 'trigger'; 'actionport', 'ifaction'; ...
              'resetport', 'reset'};
    for k = 1:4
        if any(strcmp(types, paires{k, 1}))
            ordre{end + 1} = paires{k, 1}; %#ok<AGROW>
            noms{end + 1} = paires{k, 2}; %#ok<AGROW>
        end
    end
    rang = port - nEntrees;
    if rang <= numel(noms)
        nom = noms{rang};
    end
end

% Les options d'un Selector, rangées en cellules, s'écrivent comme Simulink
% les range dans ses fichiers : « Select all,Index vector (dialog) »,
% « 1,[1 3] ». Une dimension sans valeur — tout choisir — y vaut 1.
function p = parametresSelecteur(p)
    noms = {'IndexOptionArray', 'IndexOptions'; 'IndexParamArray', 'Indices'; ...
            'OutputSizeArray', 'OutputSizes'};
    for i = 1:size(noms, 1)
        if ~isfield(p, noms{i, 1})
            continue
        end
        v = p.(noms{i, 1});
        p = rmfield(p, noms{i, 1});
        if (ischar(v) || isstring(v)) && strncmp(strtrim(char(v)), '{', 1)
            v = eval(strtrim(char(v)));
        end
        if iscell(v)
            if isempty(v)
                continue   % la valeur par défaut : rien à écrire
            end
            morceaux = cell(1, numel(v));
            for j = 1:numel(v)
                if isempty(v{j})
                    morceaux{j} = '1';
                else
                    morceaux{j} = texteValeur(v{j});
                end
            end
            v = strjoin(morceaux, ',');
        end
        p.(noms{i, 2}) = v;
    end
end

% Un tableau de structures de nombres et de textes, en l'expression qui le
% refait : « struct('SamplePeriod', {0.1, 0.2}, 'Offset', {0, 0}) ».
function t = texteStructure(s)
    t = '';
    noms = fieldnames(s);
    morceaux = cell(1, numel(noms));
    for i = 1:numel(noms)
        valeurs = cell(1, numel(s));
        for j = 1:numel(s)
            x = s(j).(noms{i});
            if ischar(x) || isstring(x)
                valeurs{j} = ['''' strrep(char(x), '''', '''''') ''''];
            elseif (isnumeric(x) || islogical(x)) && ndims(x) <= 2
                valeurs{j} = mat2str(double(x), 17);
            else
                return   % une valeur que le texte ne rend pas
            end
        end
        if numel(s) == 1
            morceaux{i} = sprintf('''%s'', %s', noms{i}, valeurs{1});
        else
            morceaux{i} = sprintf('''%s'', {%s}', noms{i}, strjoin(valeurs, ', '));
        end
    end
    t = ['struct(' strjoin(morceaux, ', ') ')'];
end

% L'élément qui porte le diagramme : Model, Library pour une bibliothèque,
% Subsystem pour un fichier de sous-système.
function element = elementDiagramme(modele)
    element = 'Model';
    if isfield(modele, 'parametres') && isfield(modele.parametres, 'BlockDiagramType')
        switch lower(char(modele.parametres.BlockDiagramType))
            case 'library'
                element = 'Library';
            case 'subsystem'
                element = 'Subsystem';
        end
    end
end

function t = texteValeur(v)
    if ischar(v)
        t = v;
    elseif isstring(v)
        t = char(v);
    elseif (isnumeric(v) || islogical(v)) && ndims(v) <= 2
        if isscalar(v)
            t = num2str(double(v), 17);
        else
            t = mat2str(double(v), 17);
        end
    elseif iscellstr(v)
        t = ['{' strjoin(cellfun(@(c) ['''' strrep(c, '''', '''''') ''''], v, ...
                                 'UniformOutput', false), ', ') '}'];
    elseif isobject(v) && isenum(v)
        t = matlibre_sl_types('texte', v);   % un membre : 'Couleur.Rouge'
    else
        t = '';
    end
end

function ecrireTexte(chemin, texte)
    f = fopen(chemin, 'w');
    if f < 0
        error('Simulink:Commands:SaveFailed', 'Impossible d''ecrire ''%s''.', chemin);
    end
    fprintf(f, '%s', texte);
    fclose(f);
end

% Le masque d'un sous-système, comme Simulink le range : ses réglages,
% puis un MaskParameter par paramètre.
function lignes = ecrireMasque(b, lignes, marge)
    lignes{end + 1} = [marge '    <Mask>'];
    reglages = {'MaskType', 'Type'; 'MaskDescription', 'Description'; 'MaskHelp', 'Help'; ...
                'MaskInitialization', 'Initialization'; 'MaskDisplay', 'Display'; ...
                'MaskSelfModifiable', 'SelfModifiable'};
    for j = 1:size(reglages, 1)
        if isfield(b.parametres, reglages{j, 1}) && ~isempty(b.parametres.(reglages{j, 1}))
            lignes{end + 1} = sprintf('%s      <%s>%s</%s>', marge, reglages{j, 2}, ...
                                      matlibre_xml_echapper(char(b.parametres.(reglages{j, 1}))), ...
                                      reglages{j, 2}); %#ok<AGROW>
        end
    end
    S = matlibre_sl_masque('parametres', b);
    for j = 1:numel(S)
        p = S(j);
        options = '';
        if ~isempty(p.TypeOptions)
            options = ['<TypeOptions>' strjoin(cellfun(@(o) ['<Option>' ...
                       matlibre_xml_echapper(o) '</Option>'], p.TypeOptions, ...
                       'UniformOutput', false), '') '</TypeOptions>'];
        end
        rappel = '';
        if ~isempty(p.Callback)
            rappel = ['<Callback>' matlibre_xml_echapper(p.Callback) '</Callback>'];
        end
        lignes{end + 1} = sprintf(['%s      <MaskParameter Name="%s" Type="%s" Evaluate="%s" ' ...
                                   'Tunable="%s" Visible="%s" Enabled="%s"><Prompt>%s</Prompt>' ...
                                   '<Value>%s</Value>%s%s</MaskParameter>'], marge, p.Name, ...
                                  p.Type, p.Evaluate, p.Tunable, p.Visible, p.Enabled, ...
                                  matlibre_xml_echapper(p.Prompt), ...
                                  matlibre_xml_echapper(p.Value), options, rappel); %#ok<AGROW>
    end
    lignes{end + 1} = [marge '    </Mask>'];
end
