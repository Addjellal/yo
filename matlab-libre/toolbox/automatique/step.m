function [y, t] = step(varargin)
%STEP Réponse indicielle.
%   STEP(SYS) trace la réponse du modèle SYS à un échelon unité, sur un
%   horizon choisi d'après ses pôles : huit fois la constante de temps la
%   plus lente, bornée entre une seconde et mille.
%
%   STEP(SYS,TFINAL) impose l'horizon, en secondes. STEP(SYS,T) où T est
%   un vecteur impose la grille de temps.
%
%   STEP(SYS1,SYS2,...,T) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT :
%   STEP(SYS,'b',SYSCORRIGE,'r--').
%
%   [Y,T] = STEP(SYS) ne trace rien et rend la réponse et les instants.
%
%   Un modèle à plusieurs entrées et sorties répond sur chaque couple :
%   Y est alors de taille NT x NY x NU, Y(:,I,J) étant la réponse de la
%   sortie I à un échelon sur la seule entrée J. Le tracé en fait une
%   grille, une case par couple, comme dans MATLAB. Un modèle à une voie
%   rend une colonne, comme avant.
%
%   STEP(...,OPTIONS) où OPTIONS vient de STEPDATAOPTIONS part du niveau
%   InputOffset et monte de StepAmplitude, au lieu de l'échelon unité.
%
%   Exemple :
%      G = tf(1, [1 0.4 1]);
%      step(G, feedback(G, 1), 30)
%
%   Voir aussi IMPULSE, LSIM, INITIAL, STEPINFO, STEPDATAOPTIONS.
    [modeles, styles, temps, options] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    [depart, amplitude] = niveaux(options);
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command STEP(SYS1,SYS2,...) with output arguments ' ...
                   'is not supported.']);
        end
        [y, t] = reponseEchelon(modeles{1}, temps, depart, amplitude);
        return;
    end
    if ~estMonovoie(modeles{1})
        tracerGrille(modeles, styles, temps, depart, amplitude);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [yk, tk] = reponseEchelon(modeles{k}, temps, depart, amplitude);
        courbes{end+1} = tk;            %#ok<AGROW>
        courbes{end+1} = yk;            %#ok<AGROW>
        if ~isempty(styles{k})
            courbes{end+1} = styles{k}; %#ok<AGROW>
        end
    end
    plot(courbes{:});
    grid on;
    xlabel('Temps (s)');
    ylabel('Amplitude');
    title('Réponse indicielle');
end

function [depart, amplitude] = niveaux(options)
%NIVEAUX Les deux niveaux de l'échelon, tirés des options.
    depart = 0;
    amplitude = 1;
    if isempty(options) || ~isstruct(options)
        return;
    end
    if isfield(options, 'InputOffset'),   depart = double(options.InputOffset); end
    if isfield(options, 'StepAmplitude'), amplitude = double(options.StepAmplitude); end
end

function [y, t] = reponseEchelon(sys, temps, depart, amplitude)
%REPONSEECHELON Réponse d'un modèle à un échelon.
%   Avant l'instant zéro l'entrée vaut DEPART et le système est à
%   l'équilibre : la sortie part donc du gain statique multiplié par
%   DEPART. Le modèle étant linéaire, la réponse au saut de DEPART à
%   DEPART+AMPLITUDE est ce niveau, plus AMPLITUDE fois la réponse à
%   l'échelon unité partant du repos.
    t = matlibre_grille_temps(sys, temps);
    modele = ss(sys);
    ny = size(modele.D, 1);
    nu = size(modele.D, 2);
    if ny == 1 && nu == 1
        [y, t] = lsim(sys, ones(size(t)), t);
    else
        % Un echelon sur une seule entree a la fois : c'est ce que montre
        % chaque case de la grille, et ce que rend Y(:,:,J).
        y = zeros(numel(t), ny, nu);
        for j = 1:nu
            u = zeros(numel(t), nu);
            u(:, j) = 1;
            y(:, :, j) = lsim(sys, u, t);
        end
    end
    y = amplitude * y;
    if depart ~= 0
        gain = dcgain(sys);
        if ~all(isfinite(gain(:)))
            error('control:step:Offset', ...
                  ['InputOffset demande un gain statique fini ; ce modèle ' ...
                   'n''en a pas.']);
        end
        if ny == 1 && nu == 1
            y = y + depart * gain;
        else
            for j = 1:nu
                y(:, :, j) = y(:, :, j) + depart * repmat(gain(:, j).', numel(t), 1);
            end
        end
    end
end

function oui = estMonovoie(sys)
    modele = ss(sys);
    oui = size(modele.D, 1) == 1 && size(modele.D, 2) == 1;
end

% Une case par couple (sortie, entree), et chaque modele superpose dans
% chacune. Tous les modeles doivent avoir les memes dimensions : sinon les
% cases ne se correspondraient pas.
function tracerGrille(modeles, styles, temps, depart, amplitude)
    reference = ss(modeles{1});
    [cases, entrees, sorties] = matlibre_grille_voies(modeles{1});
    reponses = cell(1, numel(modeles));
    instants = cell(1, numel(modeles));
    for k = 1:numel(modeles)
        autre = ss(modeles{k});
        if ~isequal(size(autre.D), size(reference.D))
            error('Control:analysis:MultipleModels', ...
                  'Les modeles superposes doivent avoir les memes entrees et sorties.');
        end
        [reponses{k}, instants{k}] = reponseEchelon(modeles{k}, temps, depart, amplitude);
    end
    for i = 1:size(cases, 1)
        for j = 1:size(cases, 2)
            axes(cases{i, j});
            courbes = {};
            for k = 1:numel(modeles)
                courbes{end + 1} = instants{k};                  %#ok<AGROW>
                courbes{end + 1} = reponses{k}(:, i, j);         %#ok<AGROW>
                if ~isempty(styles{k})
                    courbes{end + 1} = styles{k};                %#ok<AGROW>
                end
            end
            plot(courbes{:});
            grid on;
            title(sprintf('De %s vers %s', entrees{j}, sorties{i}));
            if i == size(cases, 1), xlabel('Temps (s)'); end
            if j == 1, ylabel('Amplitude'); end
        end
    end
end
