function varargout = matlibre_sl_signaux(action, varargin)
%MATLIBRE_SL_SIGNAUX Les ports des blocs, leurs signaux et leur journal.
%   PH = MATLIBRE_SL_SIGNAUX('poignees',MODELE,BLOC) rend les poignées des
%   ports du bloc, comme GET_PARAM(MODELE,BLOC,'PortHandles') : une
%   structure à champs Inport, Outport, Enable, Trigger, State, LConn,
%   RConn, Ifaction et Reset. Une poignée est un nombre, le même pour un
%   même port tout au long de la session.
%
%   M = MATLIBRE_SL_SIGNAUX('poser',MODELE,H,NOM,VALEUR,...) règle le
%   signal qui part du port de sortie H : son nom (Name) et sa
%   journalisation — DataLogging, DataLoggingNameMode ('SignalName' ou
%   'Custom'), DataLoggingName, DataLoggingDecimateData et
%   DataLoggingDecimation, DataLoggingLimitDataPoints et
%   DataLoggingMaxPoints —, et TestPoint. SET_PARAM(MODELE,H,...) passe
%   par là. V = MATLIBRE_SL_SIGNAUX('lire',MODELE,H,NOM) relit un réglage,
%   ou PortType, PortNumber, Parent et Handle ; GET_PARAM(MODELE,H,NOM)
%   passe par là.
%
%   DS = MATLIBRE_SL_SIGNAUX('journal',C,T,J,INSTANTS) rend le journal
%   des signaux d'une simulation — ce que SIM range dans logsout — : un
%   Simulink.SimulationData.Dataset, un élément par signal dont
%   DataLogging vaut 'on', chacun portant son nom, le chemin de son bloc,
%   son port et ses valeurs en timeseries. Vide si aucun signal n'est
%   journalisé.
%
%   Les réglages d'un signal sont rangés dans le bloc d'où il part, champ
%   SIGNAUX : c'est le port de sortie qui porte le signal, comme dans
%   Simulink.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('m'), 'sine', 's');
%      ph = matlibre_sl_signaux('poignees', m, 's');
%      m = matlibre_sl_signaux('poser', m, ph.Outport(1), 'Name', 'onde');
%      matlibre_sl_signaux('lire', m, ph.Outport(1), 'Name')     % 'onde'
%
%   Voir aussi GET_PARAM, SET_PARAM, SIM, SIMULINK.SIMULATIONDATA.DATASET.
    switch action
        case 'poignees'
            varargout{1} = poignees(varargin{:});
        case 'poser'
            varargout{1} = poser(varargin{:});
        case 'lire'
            varargout{1} = lire(varargin{:});
        case 'journal'
            varargout{1} = journal(varargin{:});
        case 'defauts'
            varargout{1} = defauts();
        case 'nom'
            % NOM = MATLIBRE_SL_SIGNAUX('nom',BLOC,PORT) : le nom du signal
            % qui part du port de sortie PORT, '' s'il n'en a pas.
            varargout{1} = reglageDe(varargin{1}, varargin{2}).Name;
        case 'reglage'
            % R = MATLIBRE_SL_SIGNAUX('reglage',BLOC,PORT) : tous les
            % réglages du signal qui part du port de sortie PORT.
            varargout{1} = reglageDe(varargin{1}, varargin{2});
        case 'bloc'
            % BLOC = MATLIBRE_SL_SIGNAUX('bloc',BLOC,PORT,REGLAGE) : les champs
            % de la structure REGLAGE, posés sur le port de sortie PORT.
            [bloc, port, partiel] = varargin{:};
            reglage = reglageDe(bloc, port);
            for nom = intersect(fieldnames(partiel).', fieldnames(reglage).')
                reglage.(nom{1}) = partiel.(nom{1});
            end
            varargout{1} = rangerReglage(bloc, port, reglage);
        otherwise
            error('Simulink:Signaux:Action', 'Action inconnue : %s.', char(action));
    end
end

% Les réglages d'un signal, et leur valeur par défaut, dans l'ordre où
% Simulink les montre.
function d = defauts()
    d = struct('Name', '', 'DataLogging', 'off', 'DataLoggingNameMode', 'SignalName', ...
               'DataLoggingName', '', 'DataLoggingDecimateData', 'off', ...
               'DataLoggingDecimation', '2', 'DataLoggingLimitDataPoints', 'off', ...
               'DataLoggingMaxPoints', '5000', 'TestPoint', 'off');
end

% --- les poignées ---------------------------------------------------------------

% Le registre des poignées : un numéro par port, le même tant que dure
% la session. La clé dit le modèle, le chemin du bloc, le genre de port
% et son rang.
function sortie = registre(action, argument)
    persistent parCle parNumero compteur
    if isempty(parCle)
        parCle = containers.Map('KeyType', 'char', 'ValueType', 'double');
        parNumero = containers.Map('KeyType', 'double', 'ValueType', 'any');
        compteur = 0;
    end
    switch action
        case 'numero'
            if isKey(parCle, argument)
                sortie = parCle(argument);
                return
            end
            compteur = compteur + 1;
            sortie = compteur + 0.0001;
            parCle(argument) = sortie;
            parNumero(sortie) = argument;
        case 'cle'
            sortie = '';
            if isKey(parNumero, argument)
                sortie = parNumero(argument);
            end
    end
end

function h = numero(modele, chemin, genre, port)
    h = registre('numero', sprintf('%s|%s|%s|%d', char(modele), chemin, genre, port));
end

function [nomModele, chemin, genre, port] = decoder(h)
    if ~(isnumeric(h) && isscalar(h))
        error('Simulink:Commands:InvalidPortHandle', ...
              'Une poignee de port est un nombre, que rend GET_PARAM(M,BLOC,''PortHandles'').');
    end
    cle = registre('cle', double(h));
    if isempty(cle)
        error('Simulink:Commands:InvalidPortHandle', ...
              ['%s n''est pas une poignee de port : GET_PARAM(M,BLOC,''PortHandles'') ' ...
               'les rend.'], num2str(h, 10));
    end
    morceaux = strsplit(cle, '|');
    nomModele = morceaux{1};
    chemin = strjoin(morceaux(2:end - 2), '|');
    genre = morceaux{end - 1};
    port = str2double(morceaux{end});
end

function ph = poignees(modele, chemin)
    chemin = cheminRelatif(modele, char(chemin));
    bloc = blocDe(modele, chemin);
    [ne, ns] = matlibre_sl_ports(bloc);
    ne(isnan(ne)) = 0;
    ns(isnan(ns)) = 0;
    ph = struct('Inport', zeros(1, 0), 'Outport', zeros(1, 0), 'Enable', [], ...
                'Trigger', [], 'State', [], 'LConn', [], 'RConn', [], 'Ifaction', [], ...
                'Reset', []);
    for k = 1:ne
        ph.Inport(k) = numero(modele.nom, chemin, 'inport', k);
    end
    for k = 1:ns
        ph.Outport(k) = numero(modele.nom, chemin, 'outport', k);
    end
end

% Le chemin d'un bloc dans son modèle, sans le nom du modèle devant.
function chemin = cheminRelatif(modele, chemin)
    prefixe = [char(modele.nom) '/'];
    if ~estBloc(modele, chemin) && strncmp(chemin, prefixe, numel(prefixe))
        chemin = chemin(numel(prefixe) + 1:end);
    end
end

function oui = estBloc(modele, chemin)
    oui = any(cellfun(@(b) strcmp(char(b.nom), chemin), modele.blocs));
end

% Le bloc que désigne un chemin, sous-systèmes compris.
function bloc = blocDe(modele, chemin)
    [parent, feuille] = decouper(modele, chemin);
    systeme = modele;
    if ~isempty(parent)
        systeme = matlibre_sl_dedans(modele, parent);
    end
    k = find(cellfun(@(b) strcmp(char(b.nom), feuille), systeme.blocs), 1);
    if isempty(k)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              'Nom d''objet Simulink invalide : le modele ''%s'' n''a pas de bloc ''%s''.', ...
              char(modele.nom), chemin);
    end
    bloc = systeme.blocs{k};
end

function [parent, feuille] = decouper(modele, chemin)
    parent = '';
    feuille = chemin;
    if estBloc(modele, chemin) || ~any(chemin == '/')
        return
    end
    barre = find(chemin == '/', 1, 'last');
    parent = chemin(1:barre - 1);
    feuille = chemin(barre + 1:end);
end

% --- régler et relire -----------------------------------------------------------

function modele = poser(modele, h, varargin)
    [nomModele, chemin, genre, port] = decoder(h);
    verifierModele(modele, nomModele, h);
    if mod(numel(varargin), 2) ~= 0 || isempty(varargin)
        error('Simulink:Commands:SetParamArguments', ...
              'SET_PARAM(M,PORT,NOM,VALEUR,...) : les reglages vont par paires.');
    end
    if ~strcmp(genre, 'outport')
        error('Simulink:Commands:ParamReadOnly', ...
              ['Le port d''entree %d du bloc ''%s/%s'' ne porte pas de reglage : un ' ...
               'signal se regle sur le port de sortie d''ou il part.'], port, nomModele, chemin);
    end
    [parent, feuille] = decouper(modele, chemin);
    if isempty(parent)
        modele = poserSurBloc(modele, feuille, port, varargin, nomModele, chemin);
    else
        interieur = matlibre_sl_dedans(modele, parent);
        interieur = poserSurBloc(interieur, feuille, port, varargin, nomModele, chemin);
        modele = matlibre_sl_remplacer(modele, parent, interieur);
    end
end

function verifierModele(modele, nomModele, h)
    if ~strcmp(char(modele.nom), nomModele)
        error('Simulink:Commands:InvalidPortHandle', ...
              'La poignee %s designe un port du modele ''%s'', pas du modele ''%s''.', ...
              num2str(h, 10), nomModele, char(modele.nom));
    end
end

function systeme = poserSurBloc(systeme, feuille, port, couples, nomModele, chemin)
    k = find(cellfun(@(b) strcmp(char(b.nom), feuille), systeme.blocs), 1);
    if isempty(k)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              'Nom d''objet Simulink invalide : le modele ''%s'' n''a plus de bloc ''%s''.', ...
              nomModele, chemin);
    end
    bloc = systeme.blocs{k};
    [~, ns] = matlibre_sl_ports(bloc);
    if ~isnan(ns) && port > ns
        error('Simulink:Commands:InvalidPortHandle', ...
              'Le bloc ''%s/%s'' n''a plus que %d port(s) de sortie.', nomModele, chemin, ns);
    end
    reglage = reglageDe(bloc, port);
    admis = fieldnames(defauts());
    for i = 1:2:numel(couples)
        nom = couples{i};
        j = [];
        if ischar(nom) || (isstring(nom) && isscalar(nom))
            j = find(strcmpi(char(nom), admis), 1);
        end
        if isempty(j)
            error('Simulink:Commands:ParamUnknown', ...
                  ['Le port de sortie %d du bloc ''%s/%s'' n''a pas de reglage ''%s'' ; ' ...
                   'ses reglages sont : %s.'], port, nomModele, chemin, texte(nom), ...
                  strjoin(admis.', ', '));
        end
        reglage.(admis{j}) = valider(admis{j}, couples{i + 1}, nomModele, chemin, port);
    end
    bloc = rangerReglage(bloc, port, reglage);
    systeme.blocs{k} = bloc;
end

function t = texte(v)
    if ischar(v) || isstring(v)
        t = char(v);
    else
        t = class(v);
    end
end

function v = valider(nom, v, nomModele, chemin, port)
    ou = sprintf('du port de sortie %d du bloc ''%s/%s''', port, nomModele, chemin);
    switch nom
        case {'Name', 'DataLoggingName'}
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            if ~(ischar(v) && (isempty(v) || isrow(v)))
                error('Simulink:Commands:SetParamInvalidValue', ...
                      'Le reglage %s %s est un texte.', nom, ou);
            end
        case {'DataLogging', 'DataLoggingDecimateData', 'DataLoggingLimitDataPoints', ...
              'TestPoint'}
            v = choix(v, {'off', 'on'}, nom, ou);
        case 'DataLoggingNameMode'
            v = choix(v, {'SignalName', 'Custom'}, nom, ou);
        case {'DataLoggingDecimation', 'DataLoggingMaxPoints'}
            n = v;
            if ischar(n) || (isstring(n) && isscalar(n))
                n = str2double(char(n));
            end
            if ~(isnumeric(n) && isscalar(n) && isreal(n) && n >= 1 && n == round(n))
                error('Simulink:Commands:SetParamInvalidValue', ...
                      'Le reglage %s %s est un entier au moins egal a 1.', nom, ou);
            end
            v = sprintf('%d', n);
    end
end

function v = choix(v, admis, nom, ou)
    if islogical(v) && isscalar(v)
        v = admis{double(v) + 1};
    end
    k = [];
    if ischar(v) || (isstring(v) && isscalar(v))
        k = find(strcmpi(char(v), admis), 1);
    end
    if isempty(k)
        error('Simulink:Commands:SetParamInvalidValue', ...
              'Le reglage %s %s vaut %s.', nom, ou, strjoin(strcat('''', admis, ''''), ' ou '));
    end
    v = admis{k};
end

% Le réglage du port PORT d'un bloc : ce qu'il porte, sinon les défauts.
function reglage = reglageDe(bloc, port)
    reglage = defauts();
    if ~isfield(bloc, 'signaux')
        return
    end
    for i = 1:numel(bloc.signaux)
        if bloc.signaux(i).Port == port
            for nom = fieldnames(reglage).'
                if isfield(bloc.signaux(i), nom{1})
                    reglage.(nom{1}) = bloc.signaux(i).(nom{1});
                end
            end
            return
        end
    end
end

% Un port qui revient à tous ses défauts n'est plus rangé : le bloc reste
% tel qu'ADD_BLOCK l'a fait.
function bloc = rangerReglage(bloc, port, reglage)
    entree = reglage;
    entree.Port = port;
    entree = orderfields(entree, [{'Port'}, fieldnames(reglage).']);
    liste = [];
    if isfield(bloc, 'signaux') && ~isempty(bloc.signaux)
        liste = bloc.signaux([bloc.signaux.Port] ~= port);
    end
    if ~isequal(reglage, defauts())
        if isempty(liste)
            liste = entree;
        else
            liste(end + 1) = entree;
        end
        [~, ordre] = sort([liste.Port]);
        liste = liste(ordre);
    end
    if isempty(liste)
        if isfield(bloc, 'signaux')
            bloc = rmfield(bloc, 'signaux');
        end
    else
        bloc.signaux = liste;
    end
end

function valeur = lire(modele, h, nom)
    [nomModele, chemin, genre, port] = decoder(h);
    verifierModele(modele, nomModele, h);
    nom = char(nom);
    switch lower(nom)
        case 'porttype'
            valeur = genre;
            return
        case 'portnumber'
            valeur = port;
            return
        case 'parent'
            valeur = [nomModele '/' chemin];
            return
        case 'handle'
            valeur = h;
            return
    end
    bloc = blocDe(modele, chemin);
    admis = fieldnames(defauts());
    j = find(strcmpi(nom, admis), 1);
    if isempty(j)
        error('Simulink:Commands:ParamUnknown', ...
              ['Le port %d du bloc ''%s/%s'' n''a pas de reglage ''%s'' ; ses reglages ' ...
               'sont : %s, PortType, PortNumber, Parent, Handle.'], port, nomModele, chemin, ...
              nom, strjoin(admis.', ', '));
    end
    if strcmp(genre, 'inport')
        % Un port d'entrée voit le signal qui lui arrive : celui de la
        % sortie qui le nourrit.
        [source, portSource] = sourceDe(modele, chemin, port);
        if isempty(source)
            valeur = defauts().(admis{j});
        else
            valeur = reglageDe(source, portSource).(admis{j});
        end
        return
    end
    valeur = reglageDe(bloc, port).(admis{j});
end

function [source, portSource] = sourceDe(modele, chemin, port)
    source = [];
    portSource = 0;
    [parent, feuille] = decouper(modele, chemin);
    systeme = modele;
    if ~isempty(parent)
        systeme = matlibre_sl_dedans(modele, parent);
    end
    k = find(cellfun(@(b) strcmp(char(b.nom), feuille), systeme.blocs), 1);
    liens = matlibre_sl_liens(systeme);
    l = find(liens(:, 2) == k & liens(:, 3) == port, 1);
    if ~isempty(l)
        source = systeme.blocs{liens(l, 1)};
        portSource = liens(l, 4);
    end
end

% --- le journal -----------------------------------------------------------------

function ds = journal(c, T, J, instants)
    ds = Simulink.SimulationData.Dataset;
    if ~isfield(c, 'signaux')
        return
    end
    N = numel(instants);
    for k = 1:c.n
        liste = c.signaux{k};
        for i = 1:numel(liste)
            reglage = liste(i);
            if ~strcmp(reglage.DataLogging, 'on')
                continue
            end
            q = find(arrayfun(@(R) R.bloc == k && R.port == reglage.Port && ~R.entree, ...
                              T.releves), 1);
            if isempty(q)
                continue
            end
            R = T.releves(q);
            donnees = J.releve(R.lignes, :);
            rangs = 1:N;
            if strcmp(reglage.DataLoggingDecimateData, 'on')
                rangs = rangs(1:str2double(reglage.DataLoggingDecimation):end);
            end
            if strcmp(reglage.DataLoggingLimitDataPoints, 'on')
                rangs = rangs(max(1, end - str2double(reglage.DataLoggingMaxPoints) + 1):end);
            end
            valeurs = mettreEnForme(donnees(:, rangs), R.dims, numel(rangs));
            nom = reglage.Name;
            if strcmp(reglage.DataLoggingNameMode, 'Custom')
                nom = reglage.DataLoggingName;
            end
            element = Simulink.SimulationData.Signal;
            element.Name = nom;
            element.PropagatedName = '';
            element.BlockPath = c.chemins{k};
            element.PortType = 'outport';
            element.PortIndex = reglage.Port;
            serie = timeseries(valeurs, instants(rangs), 'Name', nom);
            element.Values = serie;
            ds = ds.addElement(element, nom);
        end
    end
end

% Les valeurs dans la forme d'une timeseries : une ligne par instant pour
% un scalaire ou un vecteur, l'instant en dernier pour une matrice.
function v = mettreEnForme(brut, dims, N)
    d = double(dims(:)).';
    if numel(d) >= 2 && d(1) > 1 && d(2) > 1
        v = reshape(brut, [d(1), d(2), N]);
    else
        v = brut.';
    end
end
