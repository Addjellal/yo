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
%   Exemple :
%      G = tf(1, [1 0.4 1]);
%      step(G, feedback(G, 1), 30)
%
%   Voir aussi IMPULSE, LSIM, INITIAL, STEPINFO.
    [modeles, styles, temps] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command STEP(SYS1,SYS2,...) with output arguments ' ...
                   'is not supported.']);
        end
        [y, t] = reponseEchelon(modeles{1}, temps);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [yk, tk] = reponseEchelon(modeles{k}, temps);
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

function [y, t] = reponseEchelon(sys, temps)
%REPONSEECHELON Réponse d'un modèle à un échelon unité.
    t = matlibre_grille_temps(sys, temps);
    [y, t] = lsim(sys, ones(size(t)), t);
end
