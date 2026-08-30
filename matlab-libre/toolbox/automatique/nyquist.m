function [reel, imaginaire, w] = nyquist(varargin)
%NYQUIST Lieu de Nyquist.
%   NYQUIST(SYS) trace, dans le plan complexe, la réponse fréquentielle du
%   modèle SYS quand la pulsation parcourt tout l'axe imaginaire : la
%   partie positive, puis son image par symétrie. Le point -1 dit la
%   stabilité de la boucle fermée — c'est le critère de Nyquist.
%
%   NYQUIST(SYS,W) impose la grille de pulsations, en radians par seconde.
%
%   NYQUIST(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT.
%
%   [RE,IM] = NYQUIST(SYS) ne trace rien et rend les parties réelle et
%   imaginaire ; [RE,IM,W] = NYQUIST(SYS) rend en plus la grille.
%
%   Exemple :
%      nyquist(tf(1, [1 1 1]))
%
%   Voir aussi BODE, NICHOLS, MARGIN.
    [modeles, styles, w] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command NYQUIST(SYS1,SYS2,...) with output ' ...
                   'arguments is not supported.']);
        end
        [m, p, w] = bode(modeles{1}, w);
        h = m .* exp(1i * p * pi / 180);
        reel = real(h);
        imaginaire = imag(h);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [m, p] = bode(modeles{k}, w);
        h = m .* exp(1i * p * pi / 180);
        courbes{end+1} = [real(h); real(h)];    %#ok<AGROW>
        courbes{end+1} = [imag(h); -imag(h)];   %#ok<AGROW>
        if ~isempty(styles{k})
            courbes{end+1} = styles{k};         %#ok<AGROW>
        end
    end
    plot(courbes{:});
    grid on;
    xlabel('Partie réelle');
    ylabel('Partie imaginaire');
    title('Lieu de Nyquist');
end
