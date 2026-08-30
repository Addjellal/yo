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

function [y, t] = reponseImpulsion(sys, temps)
%REPONSEIMPULSION Réponse d'un modèle à une impulsion.
    t = matlibre_grille_temps(sys, temps);
    ys = lsim(sys, ones(size(t)), t);
    dt = t(2) - t(1);
    y = [0; diff(ys) / dt];
end
