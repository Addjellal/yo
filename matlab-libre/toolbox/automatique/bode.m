function [module, phase, w] = bode(varargin)
%BODE Diagramme de Bode : module et phase de la réponse fréquentielle.
%   BODE(SYS) trace le gain en décibels et la phase en degrés du modèle
%   SYS en fonction de la pulsation, l'abscisse en échelle logarithmique.
%   Le gain occupe la moitié haute de la case courante, la phase la
%   moitié basse.
%
%   BODE(SYS,W) impose la grille de pulsations, en radians par seconde :
%   un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.
%
%   BODE(SYS1,SYS2,...) superpose plusieurs modèles. Une chaîne de style
%   peut suivre chacun d'eux, comme dans PLOT :
%   BODE(SYS1,'b',SYS2,'r--',W).
%
%   [MODULE,PHASE] = BODE(SYS) ne trace rien et rend le module — linéaire,
%   pas en décibels — et la phase en degrés. [MODULE,PHASE,W] = BODE(SYS)
%   rend en plus la grille employée. Avec des sorties, un seul modèle est
%   accepté, comme dans MATLAB.
%
%   Pour un modèle échantillonné, la réponse est évaluée sur le cercle
%   unité, en exp(j*W*Ts) ; pour un modèle continu, en j*W.
%
%   Exemples :
%      bode(tf(1, [1 2 1]))
%      bode(tf(1, [1 1]), tf(1, [1 0.2 1]), logspace(-2, 2, 500))
%      [m, p] = bode(tf(1, [1 1]), 1);   % m = 0.7071, p = -45
%
%   Voir aussi BODEMAG, NICHOLS, NYQUIST, SIGMA, MARGIN, FREQRESP.
    [modeles, styles, w] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command BODE(SYS1,SYS2,...) with output arguments ' ...
                   'is not supported.']);
        end
        [module, phase, w] = reponseBode(modeles{1}, w);
        return;
    end

    gain = {};
    dephasage = {};
    for k = 1:numel(modeles)
        [m, p, wk] = reponseBode(modeles{k}, w);
        gain{end+1} = wk;               %#ok<AGROW>
        gain{end+1} = 20 * log10(m);    %#ok<AGROW>
        dephasage{end+1} = wk;          %#ok<AGROW>
        dephasage{end+1} = p;           %#ok<AGROW>
        if ~isempty(styles{k})
            gain{end+1} = styles{k};        %#ok<AGROW>
            dephasage{end+1} = styles{k};   %#ok<AGROW>
        end
    end

    [haut, bas] = matlibre_cases_bode();
    axes(haut);
    semilogx(gain{:});
    grid on;
    ylabel('Gain (dB)');
    title('Diagramme de Bode');
    axes(bas);
    semilogx(dephasage{:});
    grid on;
    xlabel('Pulsation (rad/s)');
    ylabel('Phase (deg)');
    axes(bas);
end

function [module, phase, w] = reponseBode(sys, w)
%REPONSEBODE Module et phase d'un modèle sur une grille de pulsations.
    g = tf(sys);
    if isempty(w)
        w = matlibre_pulsations(g);
    end
    w = w(:);
    if g.Ts > 0
        s = exp(1i * w * g.Ts);
    else
        s = 1i * w;
    end
    h = polyval(g.num, s) ./ polyval(g.den, s);
    module = abs(h);
    phase = unwrap(angle(h)) * 180 / pi;
end
