function [y, t] = impulse(varargin)
%IMPULSE Réponse impulsionnelle.
%   IMPULSE(SYS) trace la réponse du modèle SYS à une impulsion de Dirac,
%   obtenue en dérivant la réponse indicielle.
%
%   IMPULSE(SYS,TFINAL) impose l'horizon, en secondes ; IMPULSE(SYS,T)
%   impose la grille de temps.
%
%   IMPULSE(SYS1,SYS2,...,T) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT.
%
%   [Y,T] = IMPULSE(SYS) ne trace rien et rend la réponse et les instants.
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
function [y, t] = reponseImpulsion(sys, temps)
    retard = matlibre_retard_scalaire(sys, 'IMPULSE');
    [y, t] = reponseImpulsionNue(sys, temps);
    if retard ~= 0
        y = interp1(t, y, t - retard, 'linear', 0);
        y = y(:);
    end
end

function [y, t] = reponseImpulsionNue(sys, temps)
%REPONSEIMPULSIONNUE Réponse d'un modèle à une impulsion.
%   Une impulsion de Dirac ne fait que charger l'état : la réponse
%   impulsionnelle est la réponse libre partant de x0 = B, soit
%   y(t) = C*expm(A*t)*B. C'est exact, là où dériver numériquement la
%   réponse indicielle ne l'est pas — et forçait y(0) à zéro, alors que
%   la valeur initiale vaut C*B.
%
%   Le terme direct D d'un modèle non strictement propre ajouterait une
%   impulsion, qu'aucune grille ne peut porter : il n'est donc pas
%   représenté, comme dans MATLAB.
    modele = ss(sys);
    a = modele.A;
    b = modele.B;
    c = modele.C;
    d = modele.D;
    if size(b, 2) > 1 || size(c, 1) > 1
        error('Control:analysis:MIMO', ...
              'IMPULSE ne traite que les modèles à une entrée et une sortie.');
    end
    if modele.Ts > 0
        t = grilleEchantillonnee(sys, temps, modele.Ts);
    else
        t = matlibre_grille_temps(sys, temps);
    end
    y = zeros(numel(t), 1);
    if isempty(a)
        return;
    end

    if modele.Ts > 0
        % En temps discret, l'impulsion vaut 1/Ts au premier instant,
        % comme dans MATLAB : c'est ce qui fait tendre la réponse vers
        % celle du modèle continu quand la période diminue. La réponse à
        % l'impulsion unité s'obtient en multipliant par Ts.
        y(1) = d / modele.Ts;
        etat = b(:) / modele.Ts;
        for k = 2:numel(t)
            y(k) = c * etat;
            etat = a * etat;
        end
        return;
    end

    pas = diff(t);
    uniforme = isempty(pas) || max(abs(pas - pas(1))) <= 1e-12 * max(1, abs(pas(1)));
    if uniforme && ~isempty(pas)
        avance = expm(a * pas(1));
    end
    etat = b(:);
    for k = 1:numel(t)
        y(k) = c * etat;
        if k < numel(t)
            if uniforme
                etat = avance * etat;
            else
                etat = expm(a * pas(k)) * etat;
            end
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
