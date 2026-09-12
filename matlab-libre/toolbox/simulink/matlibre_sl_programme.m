function texte = matlibre_sl_programme(modele, nomFonction)
%MATLIBRE_SL_PROGRAMME Écrit le programme .m qui simule un schéma-bloc.
%   TEXTE = MATLIBRE_SL_PROGRAMME(MODELE) rend le texte d'une fonction
%   MATLAB qui calcule ce que calcule le schéma, sans passer par
%   Simulink : des variables, une boucle, de l'arithmétique.
%   MATLIBRE_SL_PROGRAMME(MODELE,NOM) choisit le nom de la fonction.
%
%   Ce n'est pas SAVE_SYSTEM. SAVE_SYSTEM écrit le programme qui
%   *rebâtit* le modèle — NEW_SYSTEM, ADD_BLOCK, ADD_LINE —, et
%   LOAD_SYSTEM le relit : c'est l'aller-retour du schéma. Ici, on écrit
%   le programme qui *fait ce que le schéma fait*, et il n'y a pas de
%   retour : on ne remonte pas d'un calcul quelconque au schéma qui
%   l'aurait produit.
%
%   Le programme rendu ne dépend de rien : les réglages y sont inscrits
%   tels qu'ils valent au moment où on l'écrit. Un gain réglé sur « K »
%   y devient la valeur de K, non la lettre — sans quoi le programme
%   demanderait un espace de travail qu'il n'a pas. C'est ce que fait
%   aussi le générateur de code de MathWorks.
%
%   L'ordre de calcul est celui de SIM, et l'intégration la même : le
%   programme rend donc les mêmes nombres, au bit près. C'est ce que
%   vérifie le test.
%
%   Les blocs échantillonnés, le retard pur et les échanges avec l'espace
%   de travail ne s'écrivent pas encore : ils sont refusés en les
%   nommant, plutôt que passés sous silence.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
%   dont le générateur de code écrit du C, non du MATLAB.
%
%   Exemple :
%      m = new_system('chute');
%      m = add_block(m, 'constant', 'g', 'Value', -9.81);
%      m = add_block(m, 'integrator', 'vitesse');
%      m = add_line(m, 'g', 'vitesse');
%      p = matlibre_sl_programme(m);
%      ~isempty(strfind(p, 'function'))          % 1 : c'est une fonction
%
%   Voir aussi SAVE_SYSTEM, LOAD_SYSTEM, SIM, MATLIBRE_SL_ORDRE.
    modele = matlibre_sl_aplatir(modele);
    if nargin < 2 || isempty(nomFonction)
        nomFonction = nomValide(modele.nom);
    end
    nomFonction = nomValide(nomFonction);
    n = numel(modele.blocs);
    [ordre, ~, memoire] = matlibre_sl_ordre(modele);

    % Un nom de variable par bloc, distinct : deux blocs peuvent porter
    % des noms qui se ressemblent une fois nettoyés.
    variables = cell(1, n);
    vus = {};
    for k = 1:n
        base = nomValide(modele.blocs{k}.nom);
        candidat = base;
        suffixe = 1;
        while any(strcmp(vus, candidat))
            suffixe = suffixe + 1;
            candidat = sprintf('%s_%d', base, suffixe);
        end
        vus{end + 1} = candidat;   %#ok<AGROW>
        variables{k} = candidat;
    end

    sources = cell(1, n);
    for k = 1:n
        sources{k} = [];
    end
    for l = 1:size(modele.liens, 1)
        sources{modele.liens(l, 2)}(end + 1, :) = ...
            [modele.liens(l, 1), modele.liens(l, 3)];
    end

    lignes = {};
    lignes{end + 1} = sprintf('function resultat = %s(tFinal, pas)', nomFonction);
    lignes{end + 1} = sprintf('%%%s Simule le schema « %s », sans Simulink.', ...
                              upper(nomFonction), modele.nom);
    lignes{end + 1} = '%   Programme ecrit par MATLIBRE_SL_PROGRAMME. Les reglages y';
    lignes{end + 1} = '%   sont inscrits tels qu''ils valaient : il ne depend de rien.';
    lignes{end + 1} = '%';
    lignes{end + 1} = '%   Exemple :';
    lignes{end + 1} = sprintf('%%      r = %s(1, 0.01);', nomFonction);
    lignes{end + 1} = '%      numel(r.temps) == 101';
    lignes{end + 1} = '%';
    lignes{end + 1} = '%   Voir aussi SIM, MATLIBRE_SL_PROGRAMME.';
    lignes{end + 1} = '    if nargin < 1, tFinal = 10; end';
    lignes{end + 1} = '    if nargin < 2, pas = 0.01; end';
    lignes{end + 1} = '    instants = 0:pas:tFinal;';
    lignes{end + 1} = '    nInstants = numel(instants);';
    lignes{end + 1} = '';

    % --- les états, dans leur condition initiale ---
    aEtat = false;
    for k = 1:n
        if ~memoire(k)
            continue
        end
        depart = etatInitial(modele.blocs{k});
        if isempty(depart)
            continue
        end
        if ~aEtat
            lignes{end + 1} = '    % Les etats, dans leur condition initiale.';   %#ok<AGROW>
            aEtat = true;
        end
        for j = 1:numel(depart)
            lignes{end + 1} = sprintf('    %s_%s = %s;', depart{j}{1}, ...
                                      variables{k}, depart{j}{2});   %#ok<AGROW>
        end
    end
    if aEtat
        lignes{end + 1} = '';
    end

    lignes{end + 1} = '    % Un releve par bloc, alloue une fois pour toutes.';
    for k = 1:n
        lignes{end + 1} = sprintf('    releve_%s = zeros(nInstants, 1);', ...
                                  variables{k});   %#ok<AGROW>
    end
    lignes{end + 1} = '';
    lignes{end + 1} = '    for pas_k = 1:nInstants';
    lignes{end + 1} = '        t = instants(pas_k);';

    % --- le calcul, dans l'ordre du tri topologique ---
    for i = 1:numel(ordre)
        k = ordre(i);
        corps = sortieDe(modele.blocs{k}, variables{k}, entrees(sources{k}, variables));
        for j = 1:numel(corps)
            lignes{end + 1} = ['        ' corps{j}];   %#ok<AGROW>
        end
    end
    lignes{end + 1} = '';
    for k = 1:n
        lignes{end + 1} = sprintf('        releve_%s(pas_k) = %s;', ...
                                  variables{k}, variables{k});   %#ok<AGROW>
    end

    % --- les états avancent, une fois les sorties connues ---
    misesAJour = {};
    for k = 1:n
        if ~memoire(k)
            continue
        end
        corps = avanceDe(modele.blocs{k}, variables{k}, entrees(sources{k}, variables));
        for j = 1:numel(corps)
            misesAJour{end + 1} = ['        ' corps{j}];   %#ok<AGROW>
        end
    end
    if ~isempty(misesAJour)
        lignes{end + 1} = '';
        lignes{end + 1} = '        % Les etats avancent une fois les sorties connues.';
        for j = 1:numel(misesAJour)
            lignes{end + 1} = misesAJour{j};   %#ok<AGROW>
        end
    end
    lignes{end + 1} = '    end';
    lignes{end + 1} = '';
    lignes{end + 1} = '    resultat = struct();';
    lignes{end + 1} = '    resultat.temps = instants(:);';
    lignes{end + 1} = '    resultat.signaux = struct();';
    for k = 1:n
        lignes{end + 1} = sprintf('    resultat.signaux.%s = releve_%s;', ...
                                  nomValide(modele.blocs{k}.nom), variables{k});   %#ok<AGROW>
    end
    lignes{end + 1} = 'end';
    texte = strjoin(lignes, sprintf('\n'));
    texte = [texte sprintf('\n')];
end

% L'expression qui donne la valeur arrivant sur chaque entrée d'un bloc.
% Une entrée que rien n'alimente vaut zéro, comme dans SIM.
function liste = entrees(liens, variables)
    liste = {};
    if isempty(liens)
        return
    end
    for p = 1:max(liens(:, 2))
        liste{p} = '0';   %#ok<AGROW>
    end
    for l = 1:size(liens, 1)
        liste{liens(l, 2)} = variables{liens(l, 1)};
    end
end

function e = entree(liste, p)
    if p <= numel(liste) && ~isempty(liste{p})
        e = liste{p};
    else
        e = '0';
    end
end

function nom = nomValide(brut)
    nom = regexprep(char(brut), '[^A-Za-z0-9_]', '_');
    if isempty(nom) || ~isletter(nom(1))
        nom = ['b_' nom];
    end
end

function t = nombre(v)
    t = mat2str(double(v), 17);
end

function v = param(bloc, nom, defaut)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    end
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), bloc.nom, nom);
    end
end

function t = texteParam(bloc, nom, defaut)
    t = defaut;
    if isfield(bloc.parametres, nom)
        t = char(bloc.parametres.(nom));
    end
end

% L'état d'un bloc au départ : une liste de couples {prefixe, valeur}.
% Le préfixe distingue les états d'un même bloc — un PID en a deux.
function depart = etatInitial(bloc)
    depart = {};
    switch bloc.type
        case 'integrator'
            depart = {{'x', nombre(param(bloc, 'InitialCondition', 0))}};
        case {'delay', 'unitdelay', 'memory'}
            depart = {{'x', nombre(param(bloc, 'InitialCondition', 0))}};
        case 'derivative'
            depart = {{'x', '0'}};
        case 'relay'
            depart = {{'etat', '0'}};
        case 'ratelimiter'
            depart = {{'x', nombre(param(bloc, 'InitialOutput', 0))}};
        case 'pidcontroller'
            depart = {{'xi', nombre(param(bloc, 'InitialConditionForIntegrator', 0))}, ...
                      {'xd', nombre(param(bloc, 'InitialConditionForFilter', 0))}};
        case {'statespace', 'transferfcn'}
            [A, ~, ~, ~] = matricesDe(bloc);
            x0 = param(bloc, 'X0', []);
            if isempty(x0)
                x0 = zeros(size(A, 1), 1);
            end
            depart = {{'x', nombre(x0(:))}};
    end
end

function [A, B, C, D] = matricesDe(bloc)
    if strcmp(bloc.type, 'transferfcn')
        [A, B, C, D] = tf2ss(param(bloc, 'Numerator', 1), param(bloc, 'Denominator', 1));
    else
        A = param(bloc, 'A', 0);
        B = param(bloc, 'B', 0);
        C = param(bloc, 'C', 1);
        D = param(bloc, 'D', 0);
    end
end

% Ce que le bloc met dans sa variable de sortie, en une ou plusieurs
% lignes de programme.
function lignes = sortieDe(bloc, v, u)
    lignes = {};
    un = entree(u, 1);
    switch bloc.type
        case 'constant'
            lignes = {sprintf('%s = %s;', v, nombre(param(bloc, 'Value', 1)))};
        case 'step'
            lignes = {sprintf('%s = %s;', v, ...
                              sprintf('%s + (t >= %s) * (%s - %s)', ...
                                      nombre(param(bloc, 'Before', 0)), ...
                                      nombre(param(bloc, 'Time', 1)), ...
                                      nombre(param(bloc, 'After', 1)), ...
                                      nombre(param(bloc, 'Before', 0))))};
        case 'ramp'
            lignes = {sprintf('%s = %s * t;', v, nombre(param(bloc, 'Slope', 1)))};
        case 'sine'
            lignes = {sprintf('%s = %s * sin(%s * t + %s);', v, ...
                              nombre(param(bloc, 'Amplitude', 1)), ...
                              nombre(param(bloc, 'Frequency', 1)), ...
                              nombre(param(bloc, 'Phase', 0)))};
        case 'gain'
            lignes = {sprintf('%s = %s * %s;', v, nombre(param(bloc, 'Gain', 1)), un)};
        case 'bias'
            lignes = {sprintf('%s = %s + %s;', v, un, nombre(param(bloc, 'Bias', 0)))};
        case 'sum'
            signes = texteParam(bloc, 'Signs', '++');
            morceaux = '';
            for k = 1:max(numel(signes), numel(u))
                signe = '+';
                if k <= numel(signes) && signes(k) == '-'
                    signe = '-';
                end
                if k == 1 && signe == '+'
                    morceaux = entree(u, 1);
                else
                    morceaux = sprintf('%s %s %s', morceaux, signe, entree(u, k));
                end
            end
            if isempty(morceaux)
                morceaux = '0';
            end
            lignes = {sprintf('%s = %s;', v, morceaux)};
        case 'product'
            morceaux = entree(u, 1);
            for k = 2:numel(u)
                morceaux = sprintf('%s * %s', morceaux, entree(u, k));
            end
            lignes = {sprintf('%s = %s;', v, morceaux)};
        case 'abs'
            lignes = {sprintf('%s = abs(%s);', v, un)};
        case 'sign'
            lignes = {sprintf('%s = sign(%s);', v, un)};
        case 'saturation'
            lignes = {sprintf('%s = min(max(%s, %s), %s);', v, un, ...
                              nombre(param(bloc, 'LowerLimit', -1)), ...
                              nombre(param(bloc, 'UpperLimit', 1)))};
        case 'deadzone'
            haut = nombre(param(bloc, 'UpperValue', 0.5));
            bas = nombre(param(bloc, 'LowerValue', -0.5));
            lignes = {sprintf('%s = (%s > %s) * (%s - %s) + (%s < %s) * (%s - %s);', ...
                              v, un, haut, un, haut, un, bas, un, bas)};
        case 'quantizer'
            q = nombre(param(bloc, 'QuantizationInterval', 0.5));
            lignes = {sprintf('%s = %s * round(%s / %s);', v, q, un, q)};
        case 'lookup'
            abscisses = param(bloc, 'BreakpointsData', [0 1]);
            valeurs = param(bloc, 'TableData', [0 1]);
            lignes = {sprintf(['%s = interp1(%s, %s, min(max(%s, %s), %s), ' ...
                               '''linear'');'], v, nombre(abscisses(:)'), ...
                              nombre(valeurs(:)'), un, nombre(min(abscisses)), ...
                              nombre(max(abscisses)))};
        case 'math'
            switch texteParam(bloc, 'Operator', 'square')
                case 'square', lignes = {sprintf('%s = %s ^ 2;', v, un)};
                case 'sqrt', lignes = {sprintf('%s = sqrt(max(%s, 0));', v, un)};
                case 'exp', lignes = {sprintf('%s = exp(%s);', v, un)};
                case 'log', lignes = {sprintf('%s = log(max(%s, eps));', v, un)};
                case 'reciprocal', lignes = {sprintf('%s = 1 / %s;', v, un)};
                otherwise, lignes = {sprintf('%s = %s;', v, un)};
            end
        case 'trigonometry'
            operateur = lower(texteParam(bloc, 'Operator', 'sin'));
            if strcmp(operateur, 'atan2')
                lignes = {sprintf('%s = atan2(%s, %s);', v, un, entree(u, 2))};
            else
                lignes = {sprintf('%s = %s(%s);', v, operateur, un)};
            end
        case 'minmax'
            morceaux = entree(u, 1);
            for k = 2:numel(u)
                morceaux = sprintf('%s, %s', morceaux, entree(u, k));
            end
            fonction = 'min';
            if strcmpi(texteParam(bloc, 'Function', 'min'), 'max')
                fonction = 'max';
            end
            lignes = {sprintf('%s = %s(%s);', v, fonction, morceaux)};
        case 'relational'
            operateur = texteParam(bloc, 'Operator', '<');
            lignes = {sprintf('%s = double(%s %s %s);', v, un, operateur, entree(u, 2))};
        case 'logic'
            morceaux = sprintf('%s ~= 0', entree(u, 1));
            for k = 2:max(2, numel(u))
                morceaux = sprintf('%s, %s ~= 0', morceaux, entree(u, k));
            end
            switch upper(texteParam(bloc, 'Operator', 'AND'))
                case 'AND',  forme = sprintf('all([%s])', morceaux);
                case 'OR',   forme = sprintf('any([%s])', morceaux);
                case 'NAND', forme = sprintf('~all([%s])', morceaux);
                case 'NOR',  forme = sprintf('~any([%s])', morceaux);
                case 'XOR',  forme = sprintf('mod(sum([%s]), 2) == 1', morceaux);
                case 'NXOR', forme = sprintf('mod(sum([%s]), 2) == 0', morceaux);
                case 'NOT',  forme = sprintf('~(%s ~= 0)', entree(u, 1));
                otherwise,   forme = sprintf('all([%s])', morceaux);
            end
            lignes = {sprintf('%s = double(%s);', v, forme)};
        case 'switch'
            seuil = nombre(param(bloc, 'Threshold', 0));
            switch texteParam(bloc, 'Criteria', 'u2>=Threshold')
                case 'u2>Threshold', test = sprintf('%s > %s', entree(u, 2), seuil);
                case 'u2~=0',        test = sprintf('%s ~= 0', entree(u, 2));
                otherwise,           test = sprintf('%s >= %s', entree(u, 2), seuil);
            end
            lignes = {sprintf('if %s', test), ...
                      sprintf('    %s = %s;', v, entree(u, 1)), ...
                      'else', ...
                      sprintf('    %s = %s;', v, entree(u, 3)), ...
                      'end'};
        case 'relay'
            lignes = {sprintf('if %s >= %s', un, nombre(param(bloc, 'OnSwitch', 0.5))), ...
                      sprintf('    etat_%s = 1;', v), ...
                      sprintf('elseif %s <= %s', un, nombre(param(bloc, 'OffSwitch', -0.5))), ...
                      sprintf('    etat_%s = 0;', v), ...
                      'end', ...
                      sprintf('if etat_%s == 1', v), ...
                      sprintf('    %s = %s;', v, nombre(param(bloc, 'OnOutput', 1))), ...
                      'else', ...
                      sprintf('    %s = %s;', v, nombre(param(bloc, 'OffOutput', 0))), ...
                      'end'};
        case {'integrator', 'delay', 'unitdelay', 'memory'}
            lignes = {sprintf('%s = x_%s;', v, v)};
        case 'derivative'
            lignes = {sprintf('%s = (%s - x_%s) / pas;', v, un, v)};
        case 'ratelimiter'
            montee = nombre(param(bloc, 'RisingSlewLimit', 1));
            descente = nombre(param(bloc, 'FallingSlewLimit', -1));
            lignes = {sprintf('pente_%s = (%s - x_%s) / pas;', v, un, v), ...
                      sprintf('if pente_%s > %s', v, montee), ...
                      sprintf('    %s = x_%s + pas * %s;', v, v, montee), ...
                      sprintf('elseif pente_%s < %s', v, descente), ...
                      sprintf('    %s = x_%s + pas * %s;', v, v, descente), ...
                      'else', ...
                      sprintf('    %s = %s;', v, un), ...
                      'end'};
        case 'pidcontroller'
            P = nombre(param(bloc, 'P', 1));
            I = nombre(param(bloc, 'I', 0));
            D = nombre(param(bloc, 'D', 0));
            N = nombre(param(bloc, 'N', 100));
            lignes = {sprintf('%s = %s * %s + %s * xi_%s + %s * %s * (%s - %s * xd_%s);', ...
                              v, P, un, I, v, D, N, un, N, v)};
        case {'statespace', 'transferfcn'}
            [~, ~, C, D] = matricesDe(bloc);
            lignes = {sprintf('%s = %s * x_%s + %s * %s;', v, nombre(C), v, ...
                              nombre(D), un)};
        case 'inport'
            lignes = {sprintf('%s = %s;', v, nombre(param(bloc, 'Value', 0)))};
        case {'outport', 'scope', 'mux', 'demux', 'terminator', 'display', ...
              'signalconversion', 'goto', 'from'}
            lignes = {sprintf('%s = %s;', v, un)};
        otherwise
            error('Simulink:programme:BlocNonEcrit', ...
                  ['Le bloc ''%s'', de type ''%s'', ne s''ecrit pas encore en ' ...
                   'programme. Les blocs echantillonnes, le retard pur et les ' ...
                   'echanges avec l''espace de travail restent a faire.'], ...
                  bloc.nom, bloc.type);
    end
end

% Ce que le bloc fait avancer, une fois toutes les sorties connues.
function lignes = avanceDe(bloc, v, u)
    lignes = {};
    un = entree(u, 1);
    switch bloc.type
        case 'integrator'
            lignes = {sprintf('x_%s = x_%s + pas * %s;', v, v, un)};
        case {'delay', 'unitdelay', 'memory'}
            lignes = {sprintf('x_%s = %s;', v, un)};
        case 'derivative'
            lignes = {sprintf('x_%s = %s;', v, un)};
        case 'ratelimiter'
            lignes = {sprintf('x_%s = %s;', v, v)};
        case 'pidcontroller'
            N = nombre(param(bloc, 'N', 100));
            lignes = {sprintf('xi_%s = xi_%s + pas * %s;', v, v, un), ...
                      sprintf('xd_%s = xd_%s + pas * (%s - %s * xd_%s);', v, v, un, ...
                              N, v)};
        case {'statespace', 'transferfcn'}
            [A, B, ~, ~] = matricesDe(bloc);
            lignes = {sprintf('x_%s = x_%s + pas * (%s * x_%s + %s * %s);', v, v, ...
                              nombre(A), v, nombre(B), un)};
        case 'relay'
            % Le relais decide dans la passe de sortie : rien a avancer.
    end
end
