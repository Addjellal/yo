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
    [y, t] = lsim(sys, ones(size(t)), t);
    y = amplitude * y;
    if depart ~= 0
        gain = dcgain(sys);
        if ~all(isfinite(gain(:)))
            error('control:step:Offset', ...
                  ['InputOffset demande un gain statique fini ; ce modèle ' ...
                   'n''en a pas.']);
        end
        y = y + depart * gain;
    end
end
