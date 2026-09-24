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
%   Le modèle est d'abord compilé comme pour SIM : l'ordre de calcul,
%   les dimensions des signaux — scalaires ou vecteurs —, les paramètres
%   sont ceux que SIM emploie, et chaque bloc s'écrit avec les formules
%   mêmes du simulateur. Le programme rend donc les mêmes nombres, au bit
%   près, que SIM avec le solveur ode1. C'est ce que vérifie le test.
%
%   Ne s'écrivent pas encore, et sont refusés en les nommant plutôt que
%   traduits de travers : les blocs échantillonnés à une autre période
%   que le pas, le retard pur, les échanges avec l'espace de travail, les
%   nombres au hasard, les signaux matrices, les boucles algébriques, et
%   les solveurs autres qu'Euler.
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
%   Voir aussi SAVE_SYSTEM, LOAD_SYSTEM, SIM, MATLIBRE_SL_COMPILER.
    modele = matlibre_sl_modele(modele);
    if nargin < 2 || isempty(nomFonction)
        nomFonction = nomValide(modele.nom);
    end
    nomFonction = nomValide(nomFonction);
    config = matlibre_sl_config('lire', modele);
    solveur = lower(char(config.Solver));
    if ~any(strcmp(solveur, {'ode1', 'fixedstepdiscrete'}))
        error('Simulink:programme:SolveurNonEcrit', ...
              ['Le modele ''%s'' demande le solveur %s ; le programme engendre ' ...
               'integre par la methode d''Euler (ode1) seulement. Posez ' ...
               'set_param(modele, ''Solver'', ''ode1'') pour l''ecrire.'], ...
              char(modele.nom), char(config.Solver));
    end
    % Le pas n'est connu qu'à l'appel du programme : un bloc qui porte sa
    % propre période ne peut donc pas s'écrire. On les refuse d'abord, en
    % les nommant ; le reste se compile avec un pas unité, qui suffit à tout
    % vérifier.
    aPlat = matlibre_sl_aplatir(modele);
    for k = 1:numel(aPlat.blocs)
        periode = periodeDonnee(aPlat.blocs{k});
        if ~isempty(periode) && isfinite(periode(1)) && periode(1) > 0
            error('Simulink:programme:BlocNonEcrit', ...
                  ['Le bloc ''%s/%s'' est echantillonne a la periode %g : le programme ' ...
                   'engendre ne connait que son pas d''appel. Les blocs echantillonnes, ' ...
                   'le retard pur, les nombres au hasard et les echanges avec ' ...
                   'l''espace de travail restent a faire.'], char(modele.nom), ...
                  aPlat.blocs{k}.nom, periode(1));
        end
    end
    c = matlibre_sl_compiler(modele, struct('silencieux', true, 'pas', 1, ...
                                             'config', config));
    if ~isempty(c.boucles)
        error('Simulink:programme:BoucleAlgebrique', ...
              ['Le modele ''%s'' contient une boucle algebrique (%s) : le programme ' ...
               'engendre ne la resout pas. Coupez-la par un bloc Memory ou Unit Delay.'], ...
              c.nom, strjoin(c.chemins(c.boucles{1}.blocs), ', '));
    end
    n = c.n;

    % Un nom de variable par port de sortie, distinct, et qui ne heurte pas
    % les noms du programme lui-même.
    reserves = {'t', 'pas', 'tFinal', 'instants', 'nInstants', 'pas_k', 'resultat'};
    vus = reserves;
    variables = cell(1, c.nPorts);
    racines = cell(1, n);
    for k = 1:n
        base = nomValide(c.noms{k});
        candidat = base;
        suffixe = 1;
        while any(strcmp(vus, candidat)) || any(strcmp(vus, ['x_' candidat]))
            suffixe = suffixe + 1;
            candidat = sprintf('%s_%d', base, suffixe);
        end
        vus{end + 1} = candidat; %#ok<AGROW>
        racines{k} = candidat;
        for q = 1:c.nOut(k)
            gp = c.portDebut(k) + q - 1;
            if q == 1
                variables{gp} = candidat;
            else
                variables{gp} = sprintf('%s_port%d', candidat, q);
                vus{end + 1} = variables{gp}; %#ok<AGROW>
            end
        end
    end
    for gp = 1:c.nPorts
        if any(c.dims{gp} > 1) && all(c.dims{gp} > 1)
            k = c.proprio(gp);
            error('Simulink:programme:BlocNonEcrit', ...
                  ['La sortie du bloc ''%s'' est une matrice %s : le programme engendre ' ...
                   'ne traite encore que des scalaires et des vecteurs.'], ...
                  c.chemins{k}, mat2str(c.dims{gp}));
        end
    end

    entete = {};
    corps = {};
    avance = {};
    derivees = {};
    for k = 1:n
        u = entreesDe(c, k, variables);
        [initiales, sortie, derivee, maj] = ecrireBloc(c, k, racines{k}, variables, u);
        entete = [entete, initiales]; %#ok<AGROW>
        if ~isempty(sortie)
            corps{k} = sortie; %#ok<AGROW>
        else
            corps{k} = {}; %#ok<AGROW>
        end
        derivees = [derivees, derivee]; %#ok<AGROW>
        avance = [avance, maj]; %#ok<AGROW>
    end

    lignes = {};
    lignes{end + 1} = sprintf('function resultat = %s(tFinal, pas)', nomFonction);
    lignes{end + 1} = sprintf('%%%s Simule le schema « %s », sans Simulink.', ...
                              upper(nomFonction), c.nom);
    lignes{end + 1} = '%   Programme ecrit par MATLIBRE_SL_PROGRAMME. Les reglages y';
    lignes{end + 1} = '%   sont inscrits tels qu''ils valaient : il ne depend de rien.';
    lignes{end + 1} = '%';
    lignes{end + 1} = '%   Exemple :';
    lignes{end + 1} = sprintf('%%      r = %s(1, 0.01);', nomFonction);
    lignes{end + 1} = '%      numel(r.temps) == 101';
    lignes{end + 1} = '%';
    lignes{end + 1} = '%   Voir aussi SIM, MATLIBRE_SL_PROGRAMME.';
    lignes{end + 1} = sprintf('    if nargin < 1, tFinal = %s; end', nombre(nombreConfig(config.StopTime)));
    lignes{end + 1} = sprintf('    if nargin < 2, pas = %s; end', nombre(nombreConfig(config.FixedStep)));
    lignes{end + 1} = sprintf('    instants = %s:pas:tFinal;', nombre(nombreConfig(config.StartTime)));
    lignes{end + 1} = '    nInstants = numel(instants);';
    lignes{end + 1} = '';
    if ~isempty(entete)
        lignes{end + 1} = '    % Les etats, dans leur condition initiale.';
        for j = 1:numel(entete)
            lignes{end + 1} = ['    ' entete{j}]; %#ok<AGROW>
        end
        lignes{end + 1} = '';
    end
    % Les relevés : un par port de sortie, ou par entrée d'un bloc qui n'a
    % pas de sortie — les mêmes que ceux de SIM.
    releves = {};
    lignes{end + 1} = '    % Un releve par signal, alloue une fois pour toutes.';
    for k = 1:n
        if c.nOut(k) >= 1
            for q = 1:c.nOut(k)
                gp = c.portDebut(k) + q - 1;
                champ = nomValide(c.noms{k});
                if q > 1
                    champ = sprintf('%s_port%d', champ, q);
                end
                releves(end + 1, :) = {champ, variables{gp}, c.largeur(gp)}; %#ok<AGROW>
            end
        else
            for j = 1:c.nIn(k)
                champ = nomValide(c.noms{k});
                if j > 1
                    champ = sprintf('%s_port%d', champ, j);
                end
                w = 1;
                if c.entrees{k}(j) > 0
                    w = c.largeur(c.entrees{k}(j));
                end
                releves(end + 1, :) = {champ, u_(c, k, j, variables), w}; %#ok<AGROW>
            end
        end
    end
    for r = 1:size(releves, 1)
        lignes{end + 1} = sprintf('    releve_%d = zeros(nInstants, %d);', r, releves{r, 3}); %#ok<AGROW>
    end
    lignes{end + 1} = '';
    lignes{end + 1} = '    for pas_k = 1:nInstants';
    lignes{end + 1} = '        t = instants(pas_k);';
    for e = 1:numel(c.etapes)
        for k = c.etapes{e}
            for j = 1:numel(corps{k})
                lignes{end + 1} = ['        ' corps{k}{j}]; %#ok<AGROW>
            end
        end
    end
    lignes{end + 1} = '';
    for r = 1:size(releves, 1)
        lignes{end + 1} = sprintf('        releve_%d(pas_k, :) = %s;', r, releves{r, 2}); %#ok<AGROW>
    end
    if ~isempty(derivees) || ~isempty(avance)
        lignes{end + 1} = '        if pas_k == nInstants';
        lignes{end + 1} = '            break';
        lignes{end + 1} = '        end';
        lignes{end + 1} = '';
        lignes{end + 1} = '        % Les etats avancent une fois les sorties connues : les';
        lignes{end + 1} = '        % derivees d''abord, puis les etats discrets, puis Euler.';
        for j = 1:numel(derivees)
            lignes{end + 1} = ['        ' derivees{j}]; %#ok<AGROW>
        end
        for j = 1:numel(avance)
            lignes{end + 1} = ['        ' avance{j}]; %#ok<AGROW>
        end
    end
    lignes{end + 1} = '    end';
    lignes{end + 1} = '';
    lignes{end + 1} = '    resultat = struct();';
    lignes{end + 1} = '    resultat.temps = instants(:);';
    lignes{end + 1} = '    resultat.signaux = struct();';
    for r = 1:size(releves, 1)
        lignes{end + 1} = sprintf('    resultat.signaux.%s = releve_%d;', releves{r, 1}, r); %#ok<AGROW>
    end
    lignes{end + 1} = 'end';
    texte = strjoin(lignes, sprintf('\n'));
    texte = [texte sprintf('\n')];
end

function v = nombreConfig(v)
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), 'configuration', 'reglage');
    end
end

% Les expressions qui arrivent sur les entrées d'un bloc : la variable du
% port qui l'alimente, ou zéro pour une entrée en l'air — comme dans SIM.
function u = entreesDe(c, k, variables)
    u = cell(1, c.nIn(k));
    for j = 1:c.nIn(k)
        u{j} = u_(c, k, j, variables);
    end
end

function e = u_(c, k, j, variables)
    source = c.entrees{k}(j);
    if source == 0
        e = '0';
    else
        e = variables{source};
    end
end

function t = nombre(v)
    v = double(v);
    if isempty(v)
        t = 'zeros(0, 1)';
    elseif isscalar(v)
        t = mat2str(v, 17);
    else
        t = mat2str(v(:), 17);
    end
end

function t = matrice(v)
    t = mat2str(double(v), 17);
end

function nom = nomValide(brut)
    nom = regexprep(char(brut), '[^A-Za-z0-9_]', '_');
    if isempty(nom) || ~isletter(nom(1))
        nom = ['b_' nom];
    end
end

function refuser(c, k, pourquoi)
    error('Simulink:programme:BlocNonEcrit', ...
          ['Le bloc ''%s'', de type ''%s'', ne s''ecrit pas encore en programme : %s. ' ...
           'Les blocs echantillonnes, le retard pur, les nombres au hasard et les ' ...
           'echanges avec l''espace de travail restent a faire.'], ...
          c.chemins{k}, c.types{k}, pourquoi);
end

% Ce que le bloc écrit : les états initiaux, le calcul de sa sortie, la
% dérivée de ses états continus, et l'avance de ses états discrets. Chaque
% formule est celle de MATLIBRE_SL_EXECUTER, écrite à l'identique : c'est
% ce qui rend les mêmes nombres au bit près.
function [initiales, sortie, derivee, maj] = ecrireBloc(c, k, v, variables, u)
    initiales = {};
    sortie = {};
    derivee = {};
    maj = {};
    s = c.seg{k};
    type = c.types{k};
    y = '';
    if c.nOut(k) >= 1
        y = variables{c.portDebut(k)};
        w = c.largeur(c.portDebut(k));
    else
        w = 1;
    end
    switch type
        case {'outport', 'scope', 'display', 'terminator', 'goto'}
            return
        case 'constant'
            sortie = {sprintf('%s = %s;', y, nombre(s))};
        case 'ground'
            sortie = {sprintf('%s = %s;', y, nombre(zeros(w, 1)))};
        case 'step'
            if w == 1
                sortie = {sprintf('if t >= %s', nombre(s(1))), ...
                          sprintf('    %s = %s;', y, nombre(s(3))), 'else', ...
                          sprintf('    %s = %s;', y, nombre(s(2))), 'end'};
            else
                sortie = {sprintf('%s = %s;', y, nombre(s(w + 1:2 * w))), ...
                          sprintf('apres_%s = %s;', v, nombre(s(2 * w + 1:3 * w))), ...
                          sprintf('haut_%s = t >= %s;', v, nombre(s(1:w))), ...
                          sprintf('%s(haut_%s) = apres_%s(haut_%s);', y, v, v, v)};
            end
        case 'ramp'
            if w == 1
                sortie = {sprintf('if t < %s', nombre(s(2))), ...
                          sprintf('    %s = %s;', y, nombre(s(3))), 'else', ...
                          sprintf('    %s = %s * (t - %s) + %s;', y, nombre(s(1)), ...
                                  nombre(s(2)), nombre(s(3))), 'end'};
            else
                sortie = {sprintf('%s = %s .* (t - %s) + %s;', y, nombre(s(1:w)), ...
                                  nombre(s(w + 1:2 * w)), nombre(s(2 * w + 1:3 * w))), ...
                          sprintf('avant_%s = t < %s;', v, nombre(s(w + 1:2 * w))), ...
                          sprintf('depart_%s = %s;', v, nombre(s(2 * w + 1:3 * w))), ...
                          sprintf('%s(avant_%s) = depart_%s(avant_%s);', y, v, v, v)};
            end
        case 'sine'
            if w == 1
                sortie = {sprintf('%s = %s * sin(%s * t + %s) + %s;', y, nombre(s(1)), ...
                                  nombre(s(2)), nombre(s(3)), nombre(s(4)))};
            else
                sortie = {sprintf('%s = %s .* sin(%s * t + %s) + %s;', y, nombre(s(1:w)), ...
                                  nombre(s(w + 1:2 * w)), nombre(s(2 * w + 1:3 * w)), ...
                                  nombre(s(3 * w + 1:4 * w)))};
            end
        case 'clock'
            sortie = {sprintf('%s = t;', y)};
        case 'inport'
            sortie = {sprintf('%s = %s;', y, nombre(s))};
        case {'from', 'reshape', 'zoh'}
            sortie = {sprintf('%s = %s;', y, u{1})};
        case 'signalconversion'
            for j = 1:c.nIn(k)
                sortie{end + 1} = sprintf('%s = %s;', variables{c.portDebut(k) + j - 1}, ...
                                          u{j}); %#ok<AGROW>
            end
        case 'gain'
            nK = s(1) * s(2);
            K = reshape(s(3:end), s(1), s(2));
            switch c.sub(k)
                case 1
                    if nK == 1
                        sortie = {sprintf('%s = %s * %s;', y, nombre(K), u{1})};
                    else
                        sortie = {sprintf('%s = %s .* %s;', y, nombre(K(:)), u{1})};
                    end
                case {2, 4}
                    if nK == 1
                        sortie = {sprintf('%s = %s * %s;', y, nombre(K), u{1})};
                    else
                        sortie = {sprintf('%s = %s * %s;', y, matrice(K), u{1})};
                    end
                otherwise
                    if nK == 1
                        sortie = {sprintf('%s = %s * %s;', y, nombre(K), u{1})};
                    else
                        sortie = {sprintf('%s = (%s.'' * %s).'';', y, u{1}, matrice(K))};
                    end
            end
        case 'sum'
            nIn = s(1);
            if nIn == 1
                if s(2) > 0
                    sortie = {sprintf('%s = sum(%s);', y, u{1})};
                else
                    sortie = {sprintf('%s = -sum(%s);', y, u{1})};
                end
            else
                if s(2) > 0
                    expression = u{1};
                else
                    expression = ['-' u{1}];
                end
                for j = 2:nIn
                    if s(j + 1) > 0
                        expression = sprintf('%s + %s', expression, u{j});
                    else
                        expression = sprintf('%s - %s', expression, u{j});
                    end
                end
                sortie = {sprintf('%s = %s;', y, expression)};
            end
        case 'product'
            nIn = s(1);
            if s(nIn + 2) ~= 0
                refuser(c, k, 'le produit matriciel n''est pas encore ecrit');
            end
            if nIn == 1
                if s(2) > 0
                    sortie = {sprintf('%s = prod(%s);', y, u{1})};
                else
                    sortie = {sprintf('%s = 1 / prod(%s);', y, u{1})};
                end
            else
                if s(2) > 0
                    expression = u{1};
                else
                    expression = ['1 ./ ' u{1}];
                end
                for j = 2:nIn
                    if s(j + 1) > 0
                        expression = sprintf('%s .* %s', expression, u{j});
                    else
                        expression = sprintf('%s ./ %s', expression, u{j});
                    end
                end
                sortie = {sprintf('%s = %s;', y, expression)};
            end
        case 'abs'
            sortie = {sprintf('%s = abs(%s);', y, u{1})};
        case 'sign'
            sortie = {sprintf('%s = sign(%s);', y, u{1})};
        case 'unaryminus'
            sortie = {sprintf('%s = -%s;', y, u{1})};
        case 'bias'
            sortie = {sprintf('%s = %s + %s;', y, u{1}, nombre(s))};
        case 'dotproduct'
            sortie = {sprintf('%s = sum(%s .* %s);', y, u{1}, u{2})};
        case 'math'
            switch c.sub(k)
                case 1
                    sortie = {sprintf('%s = exp(%s);', y, u{1})};
                case {2, 4}
                    fonction = 'log';
                    if c.sub(k) == 4
                        fonction = 'log10';
                    end
                    sortie = {sprintf('%s = %s(abs(%s));', y, fonction, u{1}), ...
                              sprintf('%s(%s < 0) = NaN;', y, u{1})};
                case 3
                    sortie = {sprintf('%s = 10 .^ %s;', y, u{1})};
                case 5
                    sortie = {sprintf('%s = %s .* %s;', y, u{1}, u{1})};
                case 6
                    sortie = {sprintf('%s = %s .^ 2;', y, u{1})};
                case 7
                    sortie = {sprintf('%s = sqrt(abs(%s));', y, u{1}), ...
                              sprintf('%s(%s < 0) = NaN;', y, u{1})};
                case 9
                    sortie = {sprintf('%s = %s;', y, u{1})};
                case 10
                    sortie = {sprintf('%s = 1 ./ %s;', y, u{1})};
                case 11
                    sortie = {sprintf('%s = hypot(%s, %s);', y, u{1}, u{2})};
                case 12
                    sortie = {sprintf('%s = rem(%s, %s);', y, u{1}, u{2})};
                case 13
                    sortie = {sprintf('%s = mod(%s, %s);', y, u{1}, u{2})};
                otherwise
                    refuser(c, k, 'cet operateur ne s''ecrit pas encore');
            end
        case 'trigonometry'
            noms = {'sin', 'cos', 'tan', '', '', 'atan', '', 'sinh', 'cosh', 'tanh', 'asinh'};
            operateur = c.sub(k);
            if operateur <= numel(noms) && ~isempty(noms{operateur})
                sortie = {sprintf('%s = %s(%s);', y, noms{operateur}, u{1})};
            elseif operateur == 7
                sortie = {sprintf('%s = atan2(%s, %s);', y, u{1}, u{2})};
            elseif operateur == 14
                sortie = {sprintf('%s = sin(%s);', y, u{1}), ...
                          sprintf('%s = cos(%s);', variables{c.portDebut(k) + 1}, u{1})};
            else
                refuser(c, k, 'cet operateur ne s''ecrit pas encore');
            end
        case 'minmax'
            fonction = 'min';
            if c.sub(k) == 2
                fonction = 'max';
            end
            if s(1) == 1
                sortie = {sprintf('%s = %s(%s);', y, fonction, u{1})};
            else
                expression = u{1};
                for j = 2:s(1)
                    expression = sprintf('%s(%s, %s)', fonction, expression, u{j});
                end
                sortie = {sprintf('%s = %s;', y, expression)};
            end
        case 'rounding'
            noms = {'floor', 'ceil', 'round', 'fix'};
            sortie = {sprintf('%s = %s(%s);', y, noms{c.sub(k)}, u{1})};
        case 'polynomial'
            sortie = {sprintf('%s = %s;', y, nombre(s(2)))};
            for j = 3:numel(s)
                sortie{end + 1} = sprintf('%s = %s .* %s + %s;', y, y, u{1}, nombre(s(j))); %#ok<AGROW>
            end
        case 'saturation'
            if w == 1
                sortie = {sprintf('if %s > %s', u{1}, nombre(s(1))), ...
                          sprintf('    %s = %s;', y, nombre(s(1))), ...
                          sprintf('elseif %s < %s', u{1}, nombre(s(2))), ...
                          sprintf('    %s = %s;', y, nombre(s(2))), 'else', ...
                          sprintf('    %s = %s;', y, u{1}), 'end'};
            else
                sortie = {sprintf('%s = min(max(%s, %s), %s);', y, u{1}, ...
                                  nombre(s(w + 1:2 * w)), nombre(s(1:w)))};
            end
        case 'deadzone'
            if w == 1
                sortie = {sprintf('if %s > %s', u{1}, nombre(s(1))), ...
                          sprintf('    %s = %s - %s;', y, u{1}, nombre(s(1))), ...
                          sprintf('elseif %s < %s', u{1}, nombre(s(2))), ...
                          sprintf('    %s = %s - %s;', y, u{1}, nombre(s(2))), 'else', ...
                          sprintf('    %s = 0;', y), 'end'};
            else
                haut = nombre(s(1:w));
                bas = nombre(s(w + 1:2 * w));
                sortie = {sprintf('%s = (%s > %s) .* (%s - %s) + (%s < %s) .* (%s - %s);', ...
                                  y, u{1}, haut, u{1}, haut, u{1}, bas, u{1}, bas)};
            end
        case 'quantizer'
            sortie = {sprintf('%s = %s .* round(%s ./ %s);', y, nombre(s), u{1}, nombre(s))};
        case 'coulombfriction'
            sortie = {sprintf('%s = sign(%s) .* (%s .* abs(%s) + %s);', y, u{1}, ...
                              nombre(s(w + 1:2 * w)), u{1}, nombre(s(1:w)))};
        case 'lookup'
            nb = s(1);
            xs = s(4:3 + nb);
            ys = s(4 + nb:3 + 2 * nb);
            methodes = {'linear', 'previous', 'nearest'};
            methode = methodes{s(2)};
            if s(3) == 1 || ~strcmp(methode, 'linear')
                sortie = {sprintf('%s = interp1(%s, %s, min(max(%s, %s), %s), ''%s'');', y, ...
                                  nombre(xs), nombre(ys), u{1}, nombre(xs(1)), ...
                                  nombre(xs(nb)), methode)};
            else
                sortie = {sprintf('%s = interp1(%s, %s, %s, ''linear'', ''extrap'');', y, ...
                                  nombre(xs), nombre(ys), u{1})};
            end
        case 'relay'
            initiales = {sprintf('etat_%s = %s;', v, nombre(zeros(w, 1)))};
            sortie = {sprintf('mode_%s = etat_%s;', v, v), ...
                      sprintf('mode_%s(%s + %s <= %s) = 0;', v, u{1}, nombre(zeros(w, 1)), ...
                              nombre(s(w + 1:2 * w))), ...
                      sprintf('mode_%s(%s + %s >= %s) = 1;', v, u{1}, nombre(zeros(w, 1)), ...
                              nombre(s(1:w))), ...
                      sprintf('%s = %s;', y, nombre(s(3 * w + 1:4 * w))), ...
                      sprintf('marche_%s = %s;', v, nombre(s(2 * w + 1:3 * w))), ...
                      sprintf('%s(mode_%s == 1) = marche_%s(mode_%s == 1);', y, v, v, v)};
            maj = {sprintf('etat_%s = mode_%s;', v, v)};
        case 'ratelimiter'
            initiales = {sprintf('precedent_%s = %s;', v, nombre(s0(c, k, 3, w)))};
            montee = nombre(s(1:w));
            descente = nombre(s(w + 1:2 * w));
            if w == 1
                sortie = {sprintf('pente_%s = (%s - precedent_%s) / pas;', v, u{1}, v), ...
                          sprintf('if pente_%s > %s', v, montee), ...
                          sprintf('    %s = precedent_%s + pas * %s;', y, v, montee), ...
                          sprintf('elseif pente_%s < %s', v, descente), ...
                          sprintf('    %s = precedent_%s + pas * %s;', y, v, descente), ...
                          'else', sprintf('    %s = %s;', y, u{1}), 'end'};
            else
                refuser(c, k, 'le limiteur de pente d''un vecteur ne s''ecrit pas encore');
            end
            maj = {sprintf('precedent_%s = %s;', v, y)};
        case 'comparetozero'
            sortie = {sprintf('%s = double(%s %s 0);', y, u{1}, relation(c.sub(k)))};
        case 'comparetoconstant'
            sortie = {sprintf('%s = double(%s %s %s);', y, u{1}, relation(c.sub(k)), nombre(s))};
        case 'relational'
            sortie = {sprintf('%s = double(%s %s %s);', y, u{1}, relation(c.sub(k)), u{2})};
        case {'detectchange', 'detectincrease', 'detectdecrease'}
            initiales = {sprintf('precedent_%s = %s;', v, nombre(c.z0{k}))};
            operateurs = struct('detectchange', '~=', 'detectincrease', '>', ...
                                'detectdecrease', '<');
            sortie = {sprintf('%s = double(%s %s precedent_%s);', y, u{1}, ...
                              operateurs.(type), v)};
            maj = {sprintf('precedent_%s = %s + %s;', v, u{1}, nombre(zeros(w, 1)))};
        case 'logic'
            sortie = ecrireLogique(c, k, y, u, s);
        case 'switch'
            criteres = {'>=', '>', '~='};
            seuil = nombre(s(2:end));
            if c.sub(k) == 3
                seuil = '0';
            end
            largeur2 = 1;
            if c.entrees{k}(2) > 0
                largeur2 = c.largeur(c.entrees{k}(2));
            end
            if largeur2 == 1 && (numel(s) == 2 || c.sub(k) == 3)
                sortie = {sprintf('if %s %s %s', u{2}, criteres{c.sub(k)}, seuil), ...
                          sprintf('    %s = %s;', y, etendu(u{1}, w)), 'else', ...
                          sprintf('    %s = %s;', y, etendu(u{3}, w)), 'end'};
            else
                sortie = {sprintf('passe_%s = %s %s %s;', v, u{2}, criteres{c.sub(k)}, seuil), ...
                          sprintf('%s = %s + %s;', y, u{3}, nombre(zeros(w, 1))), ...
                          sprintf('premier_%s = %s + %s;', v, u{1}, nombre(zeros(w, 1))), ...
                          sprintf('%s(passe_%s) = premier_%s(passe_%s);', y, v, v, v)};
            end
        case 'multiportswitch'
            sortie = {sprintf('choix_%s = fix(%s(1)) + %s;', v, u{1}, nombre(s(2)))};
            for j = 1:s(1)
                if j == 1
                    sortie{end + 1} = sprintf('if choix_%s == 1', v); %#ok<AGROW>
                else
                    sortie{end + 1} = sprintf('elseif choix_%s == %d', v, j); %#ok<AGROW>
                end
                sortie{end + 1} = sprintf('    %s = %s;', y, etendu(u{j + 1}, w)); %#ok<AGROW>
            end
            sortie = [sortie, {'else', ...
                sprintf(['    error(''Simulink:blocks:MultiPortSwitchIndexOutOfRange'', ' ...
                         '''L''''entree de commande de %s vaut %%g a t = %%g.'', %s(1), t);'], ...
                        strrep(c.chemins{k}, '''', ''''''), u{1}), 'end'}];
        case 'mux'
            sortie = {sprintf('%s = [%s];', y, strjoin(u, '; '))};
        case 'concatenate'
            if c.sub(k) ~= 1
                refuser(c, k, 'la concatenation multidimensionnelle ne s''ecrit pas encore');
            end
            sortie = {sprintf('%s = [%s];', y, strjoin(u, '; '))};
        case 'demux'
            for q = 1:c.nOut(k)
                sortie{end + 1} = sprintf('%s = %s(%d:%d);', variables{c.portDebut(k) + q - 1}, ...
                                          u{1}, s(2 * q - 1), s(2 * q)); %#ok<AGROW>
            end
        case 'selector'
            sortie = {sprintf('%s = %s(%s);', y, u{1}, nombre(s(2:end)))};
        case 'integrator'
            x0 = c.x0(c.xA(k):c.xB(k));
            initiales = {sprintf('x_%s = %s;', v, nombre(x0))};
            if s(1) == 0
                sortie = {sprintf('%s = x_%s;', y, v)};
                derivee = {sprintf('dx_%s = %s + %s;', v, u{1}, nombre(zeros(w, 1)))};
                if w == 1
                    derivee = {sprintf('dx_%s = %s;', v, u{1})};
                end
                maj = {sprintf('x_%s = x_%s + pas * dx_%s;', v, v, v)};
            else
                haut = nombre(s(2:1 + w));
                bas = nombre(s(2 + w:1 + 2 * w));
                sortie = {sprintf('%s = min(max(x_%s, %s), %s);', y, v, bas, haut)};
                derivee = {sprintf('dx_%s = %s + %s;', v, u{1}, nombre(zeros(w, 1))), ...
                           sprintf('dx_%s(x_%s >= %s & dx_%s > 0) = 0;', v, v, haut, v), ...
                           sprintf('dx_%s(x_%s <= %s & dx_%s < 0) = 0;', v, v, bas, v)};
                maj = {sprintf('x_%s = min(max(x_%s + pas * dx_%s, %s), %s);', v, v, v, ...
                               bas, haut)};
            end
        case 'derivative'
            initiales = {sprintf('parti_%s = 0;', v), ...
                         sprintf('precedent_%s = %s;', v, nombre(zeros(w, 1)))};
            sortie = {sprintf('if parti_%s == 0', v), sprintf('    %s = %s;', y, ...
                      nombre(zeros(w, 1))), 'else', ...
                      sprintf('    %s = (%s - precedent_%s) / pas;', y, u{1}, v), 'end'};
            maj = {sprintf('parti_%s = 1;', v), sprintf('precedent_%s = %s;', v, u{1})};
        case {'transferfcn', 'statespace', 'zeropole'}
            [A, B, C, D] = matricesDe(s);
            nx = size(A, 1);
            if nx > 0
                initiales = {sprintf('x_%s = %s;', v, nombre(c.x0(c.xA(k):c.xB(k))))};
            end
            % Sans transmission directe, D est nul et l'entrée n'est pas
            % encore calculée quand la sortie l'est : la sortie ne la lit
            % pas — comme dans le simulateur. La dérivée, elle, la lit.
            if size(C, 1) == 1 && size(B, 2) == 1
                if nx == 0
                    sortie = {sprintf('%s = %s * %s;', y, nombre(D), u{1})};
                elseif ~c.direct(k)
                    sortie = {sprintf('%s = %s * x_%s;', y, matrice(C), v)};
                else
                    sortie = {sprintf('%s = %s * x_%s + %s * %s;', y, matrice(C), v, ...
                                      nombre(D), u{1})};
                end
                if nx > 0
                    derivee = {sprintf('dx_%s = %s * x_%s + %s * %s;', v, matrice(A), v, ...
                                       nombre(B), u{1})};
                    maj = {sprintf('x_%s = x_%s + pas * dx_%s;', v, v, v)};
                end
            else
                entree = sprintf('(%s + %s)', u{1}, nombre(zeros(size(B, 2), 1)));
                if nx == 0
                    sortie = {sprintf('%s = %s * %s;', y, matrice(D), entree)};
                elseif ~c.direct(k)
                    sortie = {sprintf('%s = %s * x_%s;', y, matrice(C), v)};
                else
                    sortie = {sprintf('%s = %s * x_%s + %s * %s;', y, matrice(C), v, ...
                                      matrice(D), entree)};
                end
                if nx > 0
                    derivee = {sprintf('dx_%s = %s * x_%s + %s * %s;', v, matrice(A), v, ...
                                       matrice(B), entree)};
                    maj = {sprintf('x_%s = x_%s + pas * dx_%s;', v, v, v)};
                end
            end
        case 'pidcontroller'
            if w ~= 1
                refuser(c, k, 'un PID sur un vecteur ne s''ecrit pas encore');
            end
            x0 = c.x0(c.xA(k):c.xB(k));
            initiales = {sprintf('xi_%s = %s;', v, nombre(x0(1))), ...
                         sprintf('xd_%s = %s;', v, nombre(x0(2)))};
            sortie = {sprintf('%s = %s * %s + %s * xi_%s + %s * %s * (%s - %s * xd_%s);', y, ...
                              nombre(s(1)), u{1}, nombre(s(2)), v, nombre(s(3)), ...
                              nombre(s(4)), u{1}, nombre(s(4)), v)};
            derivee = {sprintf('dxi_%s = %s;', v, u{1}), ...
                       sprintf('dxd_%s = %s - %s * xd_%s;', v, u{1}, nombre(s(4)), v)};
            maj = {sprintf('xi_%s = xi_%s + pas * dxi_%s;', v, v, v), ...
                   sprintf('xd_%s = xd_%s + pas * dxd_%s;', v, v, v)};
        case 'delay'
            L = s(1);
            if L == 0
                sortie = {sprintf('%s = %s;', y, u{1})};
            else
                tampon = reshape(c.z0{k}(2:end), w, L);
                initiales = {sprintf('tampon_%s = %s;', v, matrice(tampon)), ...
                             sprintf('tete_%s = 1;', v)};
                sortie = {sprintf('%s = tampon_%s(:, tete_%s);', y, v, v)};
                maj = {sprintf('tampon_%s(:, tete_%s) = %s;', v, v, u{1}), ...
                       sprintf('tete_%s = mod(tete_%s, %d) + 1;', v, v, L)};
            end
        case 'memory'
            initiales = {sprintf('precedent_%s = %s;', v, nombre(c.z0{k}))};
            sortie = {sprintf('%s = precedent_%s;', y, v)};
            maj = {sprintf('precedent_%s = %s;', v, u{1})};
        otherwise
            refuser(c, k, 'ce type n''a pas encore de traduction');
    end
end

% La période qu'un bloc porte, donnée ou par défaut ; vide s'il n'en a
% pas. Une expression s'évalue, comme dans SIM.
function periode = periodeDonnee(bloc)
    periode = [];
    try
        entree = matlibre_sl_catalogue('type', bloc.type);
    catch
        return
    end
    for k = 1:size(entree.params, 1)
        if strcmp(entree.params{k, 1}, 'SampleTime')
            periode = entree.params{k, 2};
        end
    end
    if isfield(bloc.parametres, 'SampleTime')
        periode = bloc.parametres.SampleTime;
    end
    if ischar(periode) || isstring(periode)
        periode = matlibre_sl_expression(char(periode), bloc.nom, 'SampleTime');
    end
    periode = double(periode);
end

% La valeur initiale d'un état discret rangé à partir du rang DEBUT de Z.
function v = s0(c, k, debut, w)
    v = c.z0{k}(debut:debut + w - 1);
end

% Une valeur étendue à la largeur du port, comme le fait l'écriture d'un
% scalaire dans une plage du simulateur.
function e = etendu(expression, w)
    if w == 1
        e = expression;
    else
        e = sprintf('%s + %s', expression, nombre(zeros(w, 1)));
    end
end

function r = relation(code)
    relations = {'==', '~=', '<', '<=', '>=', '>'};
    r = relations{code};
end

function lignes = ecrireLogique(c, k, y, u, s)
    operateur = c.sub(k);
    if operateur == 7
        lignes = {sprintf('%s = double(%s == 0);', y, u{1})};
        return
    end
    if s(1) == 1
        switch operateur
            case {1, 3}
                forme = sprintf('all(%s ~= 0)', u{1});
            case {2, 4}
                forme = sprintf('any(%s ~= 0)', u{1});
            otherwise
                forme = sprintf('mod(sum(%s ~= 0), 2) == 1', u{1});
        end
    else
        forme = sprintf('%s ~= 0', u{1});
        for j = 2:s(1)
            switch operateur
                case {1, 3}
                    forme = sprintf('(%s) & (%s ~= 0)', forme, u{j});
                case {2, 4}
                    forme = sprintf('(%s) | (%s ~= 0)', forme, u{j});
                otherwise
                    forme = sprintf('xor(%s, %s ~= 0)', forme, u{j});
            end
        end
    end
    if operateur == 3 || operateur == 4 || operateur == 6
        forme = sprintf('~(%s)', forme);
    end
    lignes = {sprintf('%s = double(%s);', y, forme)};
end

function [A, B, C, D] = matricesDe(s)
    nx = s(1);
    ny = s(2);
    nu = s(3);
    i = 4;
    A = reshape(s(i:i + nx * nx - 1), nx, nx);
    i = i + nx * nx;
    B = reshape(s(i:i + nx * nu - 1), nx, nu);
    i = i + nx * nu;
    C = reshape(s(i:i + ny * nx - 1), ny, nx);
    i = i + ny * nx;
    D = reshape(s(i:i + ny * nu - 1), ny, nu);
end
