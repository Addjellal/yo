function [racines, gains] = rlocus(varargin)
%RLOCUS Lieu des racines de la boucle fermée.
%   RLOCUS(SYS) trace, dans le plan complexe, le chemin que suivent les
%   pôles de la boucle 1 + K*SYS quand le gain K va de 0.01 à 1000. Les
%   branches partent des pôles de SYS et vont vers ses zéros.
%
%   RLOCUS(SYS,K) impose les gains à essayer.
%
%   RLOCUS(SYS1,SYS2,...,K) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT.
%
%   [R,K] = RLOCUS(SYS) ne trace rien et rend les racines — une ligne par
%   gain — et les gains employés.
%
%   Exemple :
%      rlocus(tf(1, [1 2 0]))
%
%   Voir aussi PZMAP, POLE, FEEDBACK, PLACE.
    [modeles, styles, gains] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if isempty(gains)
        gains = logspace(-2, 3, 200);
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command RLOCUS(SYS1,SYS2,...) with output ' ...
                   'arguments is not supported.']);
        end
        racines = lieu(modeles{1}, gains);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        r = lieu(modeles{k}, gains);
        courbes{end+1} = real(r);                   %#ok<AGROW>
        courbes{end+1} = imag(r);                   %#ok<AGROW>
        if isempty(styles{k})
            courbes{end+1} = '.';                   %#ok<AGROW>
        else
            courbes{end+1} = styles{k};             %#ok<AGROW>
        end
    end
    plot(courbes{:});
    grid on;
    xlabel('Partie réelle');
    ylabel('Partie imaginaire');
    title('Lieu des racines');
end

function racines = lieu(sys, gains)
%LIEU Racines de 1 + K*SYS pour chaque gain K.
    g = tf(sys);
    n = max(numel(g.den), numel(g.num)) - 1;
    racines = zeros(numel(gains), n);
    for k = 1:numel(gains)
        num = [zeros(1, numel(g.den) - numel(g.num)), g.num] * gains(k);
        p = roots(g.den + num);
        p = [p; zeros(n - numel(p), 1)];
        racines(k, :) = p(1:n).';
    end
end
