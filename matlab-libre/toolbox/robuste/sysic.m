function P = sysic()
%SYSIC Assemble une interconnexion décrite par des variables.
%   P = SYSIC assemble un schéma-bloc à partir de variables posées juste
%   avant, dans l'espace de travail de l'appelant. C'est la façon dont on
%   écrivait les modèles augmentés de la commande robuste avant CONNECT,
%   et beaucoup de sujets de travaux pratiques l'emploient encore :
%
%      systemnames    = 'G K W1 W2';
%      inputvar       = '[ref; bruit; u]';
%      outputvar      = '[W1; W2; G(1)+bruit]';
%      input_to_G     = '[u]';
%      input_to_K     = '[ref - G]';
%      input_to_W1    = '[ref - G]';
%      input_to_W2    = '[u]';
%      cleanupsysic   = 'yes';
%      P = sysic;
%
%   SYSTEMNAMES nomme les blocs, séparés par des espaces ; chacun doit
%   exister dans l'espace de travail. INPUTVAR nomme les entrées du
%   schéma, une par ligne du crochet ; « nom{3} » en déclare trois d'un
%   coup. OUTPUTVAR nomme ses sorties. INPUT_TO_<BLOC> dit ce qui entre
%   dans chaque bloc.
%
%   Une ligne est une somme de termes, chacun de la forme
%
%      [+|-] [gain*] nom [(indices)]
%
%   où NOM est un bloc ou une entrée du schéma, et INDICES choisit
%   certaines de ses voies : G(3), G(1:2). Sans indices, toutes les voies
%   du bloc sont prises. Les termes d'une même ligne doivent porter le
%   même nombre de voies.
%
%   CLEANUPSYSIC valant 'yes' efface ensuite toutes ces variables, comme
%   dans MATLAB. SYSOUTNAME, s'il existe, donne le nom sous lequel le
%   résultat est rangé chez l'appelant.
%
%   Voir aussi CONNECT, APPEND, LFT, FEEDBACK, HINFSYN.
    % Les variables se lisent ici, dans le corps de SYSIC : « caller »
    % désigne l'appelant de la fonction où l'on écrit evalin, et une
    % fonction locale n'aurait vu que SYSIC lui-même.
    if evalin('caller', 'exist(''systemnames'', ''var'')') == 0
        error('Robust:sysic:Missing', ...
              'The variable ''systemnames'' must be defined before calling SYSIC.');
    end
    noms = strsplit(strtrim(char(evalin('caller', 'systemnames'))));
    noms = noms(~strcmp(noms, ''));
    if isempty(noms)
        error('Robust:sysic:NoSystems', ...
              'SYSTEMNAMES must name at least one system.');
    end

    % Les blocs, et la place de leurs voies dans les vecteurs.
    blocs = cell(1, numel(noms));
    debutSortie = zeros(1, numel(noms));
    nbSorties = zeros(1, numel(noms));
    nbEntrees = zeros(1, numel(noms));
    for k = 1:numel(noms)
        blocs{k} = ss(evalin('caller', noms{k}));
        [nbSorties(k), nbEntrees(k)] = size(blocs{k});
    end

    % Les entrées du schéma : « nom » en déclare une, « nom{3} » en
    % déclare trois.
    if evalin('caller', 'exist(''inputvar'', ''var'')') == 0
        error('Robust:sysic:Missing', ...
              'The variable ''inputvar'' must be defined before calling SYSIC.');
    end
    [nomsEntrees, largeurs] = declarations(char(evalin('caller', 'inputvar')));
    nw = sum(largeurs);

    % Le vecteur des sources : les entrées du schéma, puis les sorties de
    % tous les blocs, dans l'ordre de SYSTEMNAMES.
    table = struct();
    position = 0;
    for k = 1:numel(nomsEntrees)
        table.(nomsEntrees{k}) = position + (1:largeurs(k));
        position = position + largeurs(k);
    end
    for k = 1:numel(noms)
        debutSortie(k) = position;
        table.(noms{k}) = position + (1:nbSorties(k));
        position = position + nbSorties(k);
    end
    nSources = position;

    % Ce qui entre dans chaque bloc, empilé dans l'ordre des blocs.
    M1 = zeros(0, nSources);
    for k = 1:numel(noms)
        variable = ['input_to_' noms{k}];
        if evalin('caller', ['exist(''' variable ''', ''var'')']) == 0
            error('Robust:sysic:Missing', ...
                  'The variable ''%s'' must be defined before calling SYSIC.', variable);
        end
        bloc = matriceDe(char(evalin('caller', variable)), table, nSources, variable);
        if size(bloc, 1) ~= nbEntrees(k)
            error('Robust:sysic:InputSize', ...
                  '%s describes %d signals, but %s has %d inputs.', ...
                  variable, size(bloc, 1), noms{k}, nbEntrees(k));
        end
        M1 = [M1; bloc];   %#ok<AGROW>
    end
    % Ce qui sort du schéma.
    if evalin('caller', 'exist(''outputvar'', ''var'')') == 0
        error('Robust:sysic:Missing', ...
              'The variable ''outputvar'' must be defined before calling SYSIC.');
    end
    M2 = matriceDe(char(evalin('caller', 'outputvar')), table, nSources, 'outputvar');

    % Le schéma est le produit étoile de la matrice d'aiguillage et des
    % blocs mis bout à bout : la matrice envoie [entrées ; sorties des
    % blocs] vers [sorties du schéma ; entrées des blocs], et les blocs
    % referment la boucle.
    A = blocs{1};
    for k = 2:numel(blocs)
        A = append(A, blocs{k});
    end
    nu = sum(nbEntrees);
    ny = sum(nbSorties);
    aiguillage = ss([M2; M1]);
    P = lft(aiguillage, A, nu, ny);

    % Le rangement, comme dans MATLAB.
    if evalin('caller', 'exist(''sysoutname'', ''var'')') ~= 0
        assignin('caller', strtrim(char(evalin('caller', 'sysoutname'))), P);
    end
    if evalin('caller', 'exist(''cleanupsysic'', ''var'')') ~= 0 && ...
            strcmpi(strtrim(char(evalin('caller', 'cleanupsysic'))), 'yes')
        aEffacer = {'systemnames', 'inputvar', 'outputvar', 'cleanupsysic', 'sysoutname'};
        for k = 1:numel(noms)
            aEffacer{end+1} = ['input_to_' noms{k}];   %#ok<AGROW>
        end
        for k = 1:numel(aEffacer)
            evalin('caller', ['clear ' aEffacer{k}]);
        end
    end
end

function [noms, largeurs] = declarations(texte)
%DECLARATIONS Les entrées déclarées par INPUTVAR : « a; b{3}; c ».
    lignes = lignesDuCrochet(texte);
    noms = {};
    largeurs = [];
    for k = 1:numel(lignes)
        morceau = strtrim(lignes{k});
        if isempty(morceau)
            continue
        end
        accolade = strfind(morceau, '{');
        if isempty(accolade)
            noms{end+1} = morceau;      %#ok<AGROW>
            largeurs(end+1) = 1;        %#ok<AGROW>
        else
            fin = strfind(morceau, '}');
            noms{end+1} = strtrim(morceau(1:accolade(1)-1));            %#ok<AGROW>
            largeurs(end+1) = str2double(morceau(accolade(1)+1:fin(1)-1));  %#ok<AGROW>
        end
    end
end

function lignes = lignesDuCrochet(texte)
%LIGNESDUCROCHET Les lignes d'un « [a; b; c] », crochets retirés.
    texte = strtrim(texte);
    if ~isempty(texte) && texte(1) == '['
        texte = texte(2:end);
    end
    if ~isempty(texte) && texte(end) == ']'
        texte = texte(1:end-1);
    end
    % Le point-virgule sépare les lignes, mais pas à l'intérieur d'une
    % parenthèse — « G(1;2) » n'existe pas, mais mieux vaut être sûr.
    lignes = {};
    courante = '';
    profondeur = 0;
    for k = 1:numel(texte)
        c = texte(k);
        if c == '('
            profondeur = profondeur + 1;
        elseif c == ')'
            profondeur = profondeur - 1;
        end
        if (c == ';' || c == sprintf('\n')) && profondeur == 0
            lignes{end+1} = courante;   %#ok<AGROW>
            courante = '';
        else
            courante = [courante c];    %#ok<AGROW>
        end
    end
    lignes{end+1} = courante;
end

function M = matriceDe(texte, table, nSources, origine)
%MATRICEDE La matrice qui décrit une liste de signaux.
%   Chaque ligne du crochet devient autant de lignes de M qu'elle porte de
%   voies ; chaque terme y ajoute son gain à la colonne de la source.
    lignes = lignesDuCrochet(texte);
    M = zeros(0, nSources);
    for k = 1:numel(lignes)
        expression = strtrim(lignes{k});
        if isempty(expression)
            continue
        end
        termes = decouperTermes(expression);
        bloc = [];
        for t = 1:numel(termes)
            [gain, colonnes] = analyserTerme(termes{t}, table, origine);
            morceau = zeros(numel(colonnes), nSources);
            for i = 1:numel(colonnes)
                morceau(i, colonnes(i)) = gain;
            end
            if isempty(bloc)
                bloc = morceau;
            elseif size(bloc, 1) ~= size(morceau, 1)
                error('Robust:sysic:Width', ...
                      'In %s, the terms of a line do not carry the same number of signals.', ...
                      origine);
            else
                bloc = bloc + morceau;
            end
        end
        M = [M; bloc];   %#ok<AGROW>
    end
end

function termes = decouperTermes(expression)
%DECOUPERTERMES Découpe une somme, en gardant les signes.
    termes = {};
    courant = '';
    profondeur = 0;
    for k = 1:numel(expression)
        c = expression(k);
        if c == '('
            profondeur = profondeur + 1;
        elseif c == ')'
            profondeur = profondeur - 1;
        end
        if (c == '+' || c == '-') && profondeur == 0 && ~isempty(strtrim(courant))
            termes{end+1} = courant;   %#ok<AGROW>
            courant = c;
        else
            courant = [courant c];     %#ok<AGROW>
        end
    end
    if ~isempty(strtrim(courant))
        termes{end+1} = courant;
    end
end

function [gain, colonnes] = analyserTerme(terme, table, origine)
%ANALYSERTERME Un terme « -2*G(1:2) » : son gain et les sources visées.
    terme = strtrim(terme);
    gain = 1;
    while ~isempty(terme) && (terme(1) == '+' || terme(1) == '-')
        if terme(1) == '-'
            gain = -gain;
        end
        terme = strtrim(terme(2:end));
    end
    % Un gain explicite, écrit devant le nom.
    facteur = regexp(terme, '^\s*([0-9.]+([eE][+-]?\d+)?)\s*\*\s*(.*)$', 'tokens', 'once');
    if ~isempty(facteur)
        gain = gain * str2double(facteur{1});
        terme = strtrim(facteur{3});
    end
    parties = regexp(terme, '^([A-Za-z]\w*)\s*(?:\(([^)]*)\))?$', 'tokens', 'once');
    if isempty(parties)
        error('Robust:sysic:Syntax', 'In %s, ''%s'' is not a signal.', origine, terme);
    end
    nom = parties{1};
    if ~isfield(table, nom)
        error('Robust:sysic:Unknown', ...
              'In %s, ''%s'' is neither an input nor a system of the diagram.', ...
              origine, nom);
    end
    toutes = table.(nom);
    if numel(parties) < 2 || isempty(parties{2})
        colonnes = toutes;
        return
    end
    indices = round(eval(['[' parties{2} ']']));
    if any(indices < 1) || any(indices > numel(toutes))
        error('Robust:sysic:Index', ...
              'In %s, ''%s'' does not have channel %d.', origine, nom, max(indices));
    end
    colonnes = toutes(indices);
end
