function [sys, point] = linearize(modele, io, varargin)
%LINEARIZE Linéarise un modèle entre des points d'analyse.
%   SYS = LINEARIZE(MODELE,IO) linéarise le modèle autour de son état
%   initial, des entrées aux sorties que désignent les points IO de
%   LINIO, et rend un modèle d'état SS. Une 'input' ajoute une
%   perturbation au signal, une 'output' le mesure, une coupure ouvre la
%   boucle : c'est ainsi qu'on lit, sur le schéma d'une boucle fermée, le
%   procédé seul, la boucle ouverte, ou la sensibilité.
%   SYS = LINEARIZE(MODELE) linéarise des blocs INPORT aux blocs OUTPORT
%   du modèle, comme LINMOD.
%   [SYS,POINT] = LINEARIZE(...) rend aussi le point de fonctionnement :
%   une structure à champs x et u.
%
%   MODELE est le nom d'un modèle de la session, ou un modèle par valeur.
%   Un point se pose sur n'importe quel bloc, sous-systèmes compris, par
%   son chemin : 'modele/regulateur/gain'. Les points posés sur un même
%   signal se suivent dans l'ordre où on les donne.
%
%   Le calcul est celui de LINMOD, sur le modèle où chaque point est
%   devenu ce qu'il dit : il est donc exact, à l'arrondi près, sur un
%   modèle linéaire. Un modèle à états discrets se linéarise par DLINMOD,
%   à la période de ses blocs discrets, et SYS est échantillonné.
%
%   Ce que LINEARIZE ne fait pas : choisir un autre point de
%   fonctionnement que l'état initial — LINMOD(MODELE,X,U) le fait, entre
%   les ports du modèle — ; retirer les états qui ne pèsent pas sur le
%   transfert demandé — SYS garde tous les états du modèle, et MINREAL
%   réduit — ; rééchantillonner un modèle à plusieurs périodes.
%
%   Exemple :
%      bdclose('all');
%      new_system('boucle');
%      add_block('simulink/Sources/Step', 'boucle/consigne');
%      add_block('simulink/Math Operations/Sum', 'boucle/ecart', 'Inputs', '+-');
%      add_block('simulink/Math Operations/Gain', 'boucle/regul', 'Gain', '4');
%      add_block('simulink/Continuous/Transfer Fcn', 'boucle/procede', ...
%                'Numerator', '1', 'Denominator', '[1 2 1]');
%      add_line('boucle', {'consigne/1', 'ecart/1', 'regul/1', 'procede/1'}, ...
%               {'ecart/1', 'regul/1', 'procede/1', 'ecart/2'});
%      io(1) = linio('boucle/consigne', 1, 'input');
%      io(2) = linio('boucle/procede', 1, 'output');
%      ferme = linearize('boucle', io);
%      dcgain(ferme)                            % 0.8 : 4/(1+4)
%      io(1) = linio('boucle/regul', 1, 'openinput');
%      procede = linearize('boucle', io);
%      dcgain(procede)                          % 1 : le procédé seul
%      bdclose('all');
%
%   Voir aussi LINIO, LINMOD, DLINMOD, TRIM, SS, MINREAL.
    if ~isempty(varargin)
        error('Simulink:Linearize:OperatingPointUnsupported', ...
              ['LINEARIZE(MODEL,IO) linearizes around the initial state of the model: it ' ...
               'takes no operating point, snapshot time, or options. ' ...
               'LINMOD(MODEL,X,U) chooses the point, between the ports of the model.']);
    end
    modele = matlibre_sl_modele(modele);
    nomModele = char(modele.nom);
    if nargin < 2
        io = [];
    end
    if isempty(io)
        [s, Ts] = lineariser(modele);
        sys = enModele(s, s.InputName, s.OutputName, Ts);
        point = s.OperPoint;
        return
    end
    if ~isstruct(io) || ~all(isfield(io, {'Block', 'PortNumber', 'Type'}))
        error('Simulink:Linearize:InvalidIO', ...
              ['LINEARIZE(MODEL,IO): IO must be a vector of analysis points, as ' ...
               'returned by LINIO.']);
    end

    % Le modèle déplié : un point se pose alors sur n'importe quel bloc,
    % où qu'il soit, comme sur un bloc du premier niveau.
    plat = matlibre_sl_aplatir(modele);
    c = matlibre_sl_compiler(plat, struct('silencieux', true, 'tFinal', 0));
    avant = matlibre_sl_executer('preparer', c);
    noms = cellfun(@(b) char(b.nom), plat.blocs, 'UniformOutput', false);
    liens = matlibre_sl_liens(plat);
    % les liens qu'un point a posés vers ses sorties ne se déplacent plus
    mesures = false(size(liens, 1), 1);
    [rangEntree, rangSortie] = derniersPorts(plat);
    tetes = zeros(0, 4);          % [bloc, port, bloc de tête, port de tête]
    nomsEntrees = {};
    nomsSorties = {};
    nEntrees = 0;
    nSorties = 0;
    for k = 1:numel(io)
        if isfield(io, 'Active') && strcmpi(char(io(k).Active), 'off')
            continue
        end
        ouverture = 'off';
        if isfield(io, 'OpenLoop') && ~isempty(io(k).OpenLoop)
            ouverture = io(k).OpenLoop;
        end
        etapes = matlibre_sl_pointanalyse('etapes', io(k).Type, ouverture);
        if isempty(etapes)
            continue
        end
        [a, p, dims, periode] = signalDe(c, noms, nomModele, io(k));
        largeur = prod(dims);
        voies = nomsDesVoies(plat.blocs{a}, p, largeur);
        % la tête du signal : là où les points déjà posés l'ont menée
        t = find(tetes(:, 1) == a & tetes(:, 2) == p, 1);
        if isempty(t)
            tetes(end + 1, :) = [a, p, a, p]; %#ok<AGROW>
            t = size(tetes, 1);
        end
        tete = tetes(t, 3:4);
        aval = find(liens(:, 1) == tete(1) & liens(:, 4) == tete(2) & ~mesures);
        for e = 1:numel(etapes)
            switch etapes{e}
                case 'mesurer'
                    rangSortie = rangSortie + 1;
                    [plat, y] = poser(plat, 'outport', 'y', 'Port', rangSortie);
                    liens(end + 1, :) = [tete(1), y, 1, tete(2)]; %#ok<AGROW>
                    mesures(end + 1, 1) = true; %#ok<AGROW>
                    nomsSorties = [nomsSorties, voies]; %#ok<AGROW>
                    nSorties = nSorties + largeur;
                case 'couper'
                    % Un gain nul plutôt qu'une constante : le signal coupé
                    % garde ses dimensions, son type et sa cadence, et ce
                    % qui en hérite en aval ne change pas.
                    [plat, z] = poser(plat, 'gain', 'coupure', 'Gain', 0);
                    liens(end + 1, :) = [tete(1), z, 1, tete(2)]; %#ok<AGROW>
                    mesures(end + 1, 1) = false; %#ok<AGROW>
                    tete = [z, 1];
                case 'ajouter'
                    rangEntree = rangEntree + 1;
                    [plat, u] = poser(plat, 'inport', 'u', 'Port', rangEntree, ...
                                      'PortDimensions', dimensionsDePort(dims));
                    % la somme tourne à la période du signal : l'entrée,
                    % continue, ne l'entraîne pas à la sienne
                    [plat, s] = poser(plat, 'sum', 'somme', 'Signs', '++', periode{:});
                    liens(end + 1:end + 2, :) = [tete(1), s, 1, tete(2); u, s, 2, 1]; %#ok<AGROW>
                    mesures(end + 1:end + 2, 1) = false; %#ok<AGROW>
                    tete = [s, 1];
                    nomsEntrees = [nomsEntrees, voies]; %#ok<AGROW>
                    nEntrees = nEntrees + largeur;
            end
        end
        liens(aval, 1) = tete(1);
        liens(aval, 4) = tete(2);
        tetes(t, 3:4) = tete;
    end
    if nEntrees == 0 || nSorties == 0
        error('Simulink:Linearize:NoIO', ...
              ['LINEARIZE(MODEL,IO): the active analysis points must include at least ' ...
               'one input and one output; they have %d input channel(s) and %d output ' ...
               'channel(s).'], ...
              nEntrees, nSorties);
    end
    plat.liens = liens;
    [s, Ts, apres] = lineariser(plat);
    memesEtatsDiscrets(avant, apres, nomModele);
    % les ports posés ici sont les derniers : les ports du modèle, restés
    % en place, tiennent les premières colonnes et les premières lignes
    colonnes = size(s.b, 2) - nEntrees + 1:size(s.b, 2);
    lignes = size(s.c, 1) - nSorties + 1:size(s.c, 1);
    s.b = s.b(:, colonnes);
    s.c = s.c(lignes, :);
    s.d = s.d(lignes, colonnes);
    sys = enModele(s, nomsEntrees, nomsSorties, Ts);
    point = s.OperPoint;
    point.u = point.u(1:numel(point.u) - nEntrees);
end

% LINMOD, ou DLINMOD à la période des blocs discrets s'il y en a. Les
% noms rendus comptent une voie par élément d'un port vecteur.
function [s, Ts, T] = lineariser(modele)
    [~, ~, entrees, sorties, T] = matlibre_sl_etats(modele);
    discrets = find(T.zN > 0 & ismember(T.code, [80 83 84 85 86]));
    Ts = 0;
    if ~isempty(discrets)
        Ts = max(T.periodes(discrets));
    end
    nomsEntrees = {};
    for k = entrees
        largeur = T.oB(k) - T.oA(k) + 1;
        if largeur == 1
            nomsEntrees{end + 1} = char(T.noms{k}); %#ok<AGROW>
        else
            for i = 1:largeur
                nomsEntrees{end + 1} = sprintf('%s(%d)', char(T.noms{k}), i); %#ok<AGROW>
            end
        end
    end
    if Ts > 0
        s = dlinmod(modele, Ts);
        % l'état initial continu et l'entrée nulle, comme LINMOD les prend
        s.OperPoint = struct('x', T.x0(:), 'u', zeros(numel(nomsEntrees), 1));
    else
        s = linmod(modele);
    end
    s.InputName = nomsEntrees;
    s.OutputName = T.noms(sorties);
    if isscalar(sorties) && size(s.c, 1) > 1
        % une seule sortie, vecteur : une voie par élément
        s.OutputName = cell(1, size(s.c, 1));
        for i = 1:size(s.c, 1)
            s.OutputName{i} = sprintf('%s(%d)', char(T.noms{sorties}), i);
        end
    end
end

function sys = enModele(s, nomsEntrees, nomsSorties, Ts)
    if Ts > 0
        sys = ss(s.a, s.b, s.c, s.d, Ts);
    else
        sys = ss(s.a, s.b, s.c, s.d);
    end
    % un nom par voie, ou pas de nom : une sortie vecteur du modèle en
    % compte plusieurs sous un seul
    if numel(nomsEntrees) == size(s.b, 2)
        sys.InputName = nomsEntrees(:).';
    end
    if numel(nomsSorties) == size(s.c, 1)
        sys.OutputName = nomsSorties(:).';
    end
    if isfield(s, 'StateName') && numel(s.StateName) == size(s.a, 1)
        sys.StateName = s.StateName(:).';
    end
end

% Le bloc déplié et le port qu'un point désigne, et les dimensions du
% signal qui en part.
function [a, p, dims, periode] = signalDe(c, noms, nomModele, point)
    chemin = char(point.Block);
    a = find(strcmp(noms, chemin), 1);
    prefixe = [nomModele '/'];
    if isempty(a) && strncmp(chemin, prefixe, numel(prefixe))
        chemin = chemin(numel(prefixe) + 1:end);
        a = find(strcmp(noms, chemin), 1);
    end
    k = find(strcmp(c.chemins, [prefixe chemin]), 1);
    if isempty(a) || isempty(k)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              ['The analysis point refers to block ''%s'', which model ''%s'' does not have. ' ...
               'A block of a referenced model cannot hold an analysis point.'], ...
              char(point.Block), nomModele);
    end
    p = double(point.PortNumber);
    if ~(isscalar(p) && p >= 1 && p == fix(p) && p <= c.nOut(k))
        error('Simulink:Linearize:InvalidPort', ...
              ['The analysis point is on output port %g of block ''%s'', which ' ...
               'has %d.'], p, char(point.Block), c.nOut(k));
    end
    dims = c.dims{c.portDebut(k) + p - 1};
    if isempty(dims)
        dims = [1 1];
    end
    % la période du signal, quand il est échantillonné : un réglage
    % SampleTime, prêt à poser
    periode = {};
    if isfinite(c.cadence(k)) && c.cadence(k) > 0
        periode = {'SampleTime', [c.cadence(k), c.decalage(k)]};
    end
end

% Les points posés ne doivent rien changer aux états discrets du modèle :
% un bloc qui héritait sa période d'un signal et en changerait rendrait
% une autre linéarisation, sans le dire.
function memesEtatsDiscrets(avant, apres, nomModele)
    for k = find(avant.zN > 0)
        j = find(strcmp(apres.chemins, avant.chemins{k}), 1);
        if isempty(j)
            continue
        end
        pa = avant.periodes(k);
        pb = apres.periodes(j);
        memePeriode = pa == pb || (isfinite(pa) && isfinite(pb) && ...
                                   abs(pa - pb) <= 1e-9 * max(abs(pa), abs(pb)));
        if apres.zN(j) ~= avant.zN(k) || ~memePeriode
            error('Simulink:Linearize:SampleTimeChanged', ...
                  ['An analysis point changes the sample time of block ''%s'' of model ''%s'', ' ...
                   'which inherits it from its input: it goes from %g to %g. Give the block its ' ...
                   '' ...
                   'sample time (SampleTime), and the linearization will match the model.'], ...
                  avant.chemins{k}, nomModele, pa, pb);
        end
    end
end

% PortDimensions, comme un Inport l'attend : une largeur pour un vecteur,
% [lignes colonnes] pour une matrice.
function d = dimensionsDePort(dims)
    if prod(dims) == 1
        d = 1;
    elseif any(dims == 1) && numel(dims) == 2
        d = prod(dims);
    else
        d = dims;
    end
end

% Le rang du dernier Inport et du dernier Outport du modèle : les ports
% qu'on ajoute prennent la suite, et LINMOD les range donc après eux.
function [entree, sortie] = derniersPorts(modele)
    entree = 0;
    sortie = 0;
    for k = 1:numel(modele.blocs)
        b = modele.blocs{k};
        if ~any(strcmp(b.type, {'inport', 'outport'}))
            continue
        end
        rang = 1;
        if isfield(b.parametres, 'Port')
            rang = b.parametres.Port;
            if ischar(rang) || isstring(rang)
                rang = str2double(rang);
            end
            if ~(isnumeric(rang) && isscalar(rang) && isfinite(rang))
                rang = 1;
            end
        end
        if strcmp(b.type, 'inport')
            entree = max(entree, double(rang)) + (double(rang) <= entree);
        else
            sortie = max(sortie, double(rang)) + (double(rang) <= sortie);
        end
    end
end

% Poser un bloc sous un nom libre ; rend son rang.
function [modele, k] = poser(modele, type, racine, varargin)
    pris = cellfun(@(b) char(b.nom), modele.blocs, 'UniformOutput', false);
    n = 1;
    while any(strcmp(pris, sprintf('linearize_%s%d', racine, n)))
        n = n + 1;
    end
    modele = add_block(modele, type, sprintf('linearize_%s%d', racine, n), varargin{:});
    k = numel(modele.blocs);
end

% Les noms des voies d'un point : celui du signal s'il en porte un, sinon
% celui du bloc ; une voie par élément.
function voies = nomsDesVoies(bloc, port, largeur)
    base = '';
    try
        base = char(matlibre_sl_signaux('nom', bloc, port));
    catch
    end
    if isempty(base)
        base = char(bloc.nom);
    end
    if largeur == 1
        voies = {base};
        return
    end
    voies = cell(1, largeur);
    for i = 1:largeur
        voies{i} = sprintf('%s(%d)', base, i);
    end
end
