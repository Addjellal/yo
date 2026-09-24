function [y, t] = impulse(varargin)
%IMPULSE Réponse impulsionnelle.
%   IMPULSE(SYS) trace la réponse du modèle SYS à une impulsion de Dirac.
%   Elle est calculée exactement, comme la réponse libre partant de
%   l'état B — non en dérivant la réponse indicielle, ce qui forcerait
%   y(0) à zéro alors qu'elle vaut C*B.
%
%   IMPULSE(SYS,TFINAL) impose l'horizon, en secondes ; IMPULSE(SYS,T)
%   impose la grille de temps.
%
%   IMPULSE(SYS1,SYS2,...,T) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT.
%
%   [Y,T] = IMPULSE(SYS) ne trace rien et rend la réponse et les instants.
%
%   Un modèle à plusieurs entrées et sorties répond sur chaque couple :
%   Y est alors de taille NT x NY x NU, Y(:,I,J) étant la réponse de la
%   sortie I à une impulsion sur la seule entrée J, et le tracé en fait
%   une grille. Chaque couple porte son propre retard.
%
%   Exemple :
%      impulse(tf(1, [1 0.4 1]))
%
%   Voir aussi STEP, LSIM, INITIAL.
    [modeles, styles, temps] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command IMPULSE(SYS1,SYS2,...) with output ' ...
                   'arguments is not supported.']);
        end
        [y, t] = reponseImpulsion(modeles{1}, temps);
        return;
    end
    if ~estMonovoie(modeles{1})
        tracerGrille(modeles, styles, temps);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [yk, tk] = reponseImpulsion(modeles{k}, temps);
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
    title('Réponse impulsionnelle');
end

% La reponse impulsionnelle d'un modele retarde est la meme, decalee : une
% impulsion qui met D a arriver produit la meme chose D plus tard. Le
% calcul se fait donc sans le retard, et le decalage vient apres.
% La reponse impulsionnelle, voie par voie. Pour chaque entree J, c'est la
% reponse libre partant de l'etat B(:,J) ; chaque couple (I,J) est ensuite
% decale de son propre retard. Un modele a une voie rend une colonne.
function [y, t] = reponseImpulsion(sys, temps)
    modele = ss(sys);
    ny = size(modele.D, 1);
    nu = size(modele.D, 2);
    if modele.Ts > 0
        t = grilleEchantillonnee(sys, temps, modele.Ts);
    else
        t = matlibre_grille_temps(sys, temps);
    end
    retards = totaldelay(sys);
    y = zeros(numel(t), ny, nu);
    for j = 1:nu
        yj = reponseDepuis(modele, t, j);
        for i = 1:ny
            if retards(i, j) ~= 0
                yj(:, i) = reshape(interp1(t, yj(:, i), t - retards(i, j), ...
                                           'linear', 0), [], 1);
            end
        end
        y(:, :, j) = yj;
    end
    if ny == 1 && nu == 1
        y = y(:);
    end
end

%REPONSEDEPUIS Réponse de toutes les sorties à une impulsion sur l'entrée J.
%   Une impulsion de Dirac ne fait que charger l'état : la réponse
%   impulsionnelle est la réponse libre partant de x0 = B(:,J), soit
%   y(t) = C*expm(A*t)*B(:,J). C'est exact, là où dériver numériquement la
%   réponse indicielle ne l'est pas — et forçait y(0) à zéro, alors que
%   la valeur initiale vaut C*B.
%
%   Le terme direct D d'un modèle non strictement propre ajouterait une
%   impulsion, qu'aucune grille ne peut porter : il n'est donc pas
%   représenté, comme dans MATLAB.
function y = reponseDepuis(modele, t, j)
    a = modele.A;
    b = modele.B(:, j);
    c = modele.C;
    d = modele.D(:, j);
    ny = size(modele.D, 1);
    y = zeros(numel(t), ny);
    if isempty(a)
        return;
    end

    if modele.Ts > 0
        % En temps discret, l'impulsion vaut 1/Ts au premier instant,
        % comme dans MATLAB : c'est ce qui fait tendre la réponse vers
        % celle du modèle continu quand la période diminue. La réponse à
        % l'impulsion unité s'obtient en multipliant par Ts.
        y(1, :) = (d / modele.Ts).';
        etat = b / modele.Ts;
        for k = 2:numel(t)
            y(k, :) = (c * etat).';
            etat = a * etat;
        end
        return;
    end

    pas = diff(t);
    uniforme = isempty(pas) || max(abs(pas - pas(1))) <= 1e-12 * max(1, abs(pas(1)));
    if uniforme && ~isempty(pas)
        avance = expm(a * pas(1));
    end
    etat = b;
    for k = 1:numel(t)
        y(k, :) = (c * etat).';
        if k < numel(t)
            if uniforme
                etat = avance * etat;
            else
                etat = expm(a * pas(k)) * etat;
            end
        end
    end
end

function oui = estMonovoie(sys)
    modele = ss(sys);
    oui = size(modele.D, 1) == 1 && size(modele.D, 2) == 1;
end

function tracerGrille(modeles, styles, temps)
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
        [reponses{k}, instants{k}] = reponseImpulsion(modeles{k}, temps);
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

function t = grilleEchantillonnee(sys, temps, periode)
% Un modèle à temps discret n'a de valeurs qu'aux multiples de sa
% période : une grille régulière quelconque n'aurait pas de sens.
    if ~isempty(temps) && numel(temps) > 1
        t = temps(:);
        return;
    end
    horizon = matlibre_grille_temps(sys, temps);
    horizon = horizon(end);
    t = (0:periode:horizon).';
end
