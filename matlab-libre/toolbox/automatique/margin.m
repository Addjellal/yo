function [gainMarge, phaseMarge, wGain, wPhase] = margin(varargin)
%MARGIN Marges de gain et de phase.
%   [GM,PM,WCG,WCP] = MARGIN(SYS) rend la marge de gain — linéaire, non en
%   décibels —, la marge de phase en degrés, et les deux pulsations où
%   elles se lisent : WCG là où la phase traverse -180 degrés, WCP là où
%   le gain traverse 0 dB.
%
%   [GM,PM,WCG,WCP] = MARGIN(MAG,PHASE,W) part d'une réponse déjà
%   calculée, telle que la rend BODE : MAG linéaire, PHASE en degrés.
%
%   MARGIN(SYS) sans sortie trace le diagramme de Bode et marque les deux
%   traversées, avec les marges en titre.
%
%   Une marge infinie signale que la traversée n'a pas lieu sur la grille
%   examinée : la phase ne descend jamais à -180 degrés, ou le gain ne
%   passe jamais sous 0 dB.
%
%   Exemple :
%      [gm, pm] = margin(tf(1, [1 2 1 0]));   % gm = 2, pm = 21.4 degrés
%
%   Voir aussi ALLMARGIN, BODE, NICHOLS, NYQUIST.
    if numel(varargin) >= 3
        m = varargin{1}(:);
        p = varargin{2}(:);
        w = varargin{3}(:);
        sys = [];
    elseif numel(varargin) == 1
        sys = matlibre_monovoie(varargin{1}, 'MARGIN', 'LOOPMARGIN');
        w = logspace(-4, 4, 4000).';
        [m, p] = bode(sys, w);
    else
        error('MATLAB:narginchk:notEnoughInputs', ...
              'Not enough input arguments.');
    end
    dB = 20 * log10(m);

    % Marge de phase : pulsation où le gain traverse 0 dB.
    phaseMarge = inf;
    wPhase = NaN;
    for k = 1:numel(w)-1
        if dB(k) >= 0 && dB(k+1) < 0
            f = dB(k) / (dB(k) - dB(k+1));
            wPhase = w(k) + f * (w(k+1) - w(k));
            phaseMarge = 180 + p(k) + f * (p(k+1) - p(k));
            if ~isempty(sys)
                % La grille ne fait que situer la traversée : elle se
                % lit ensuite sur la réponse exacte, par dichotomie.
                wPhase = dichotomie(@(x) gainDB(sys, x), w(k), w(k+1));
                phaseMarge = 180 + phaseExacte(sys, wPhase, p(k), p(k+1), w(k), w(k+1));
            end
            break;
        end
    end
    % Marge de gain : pulsation où la phase traverse -180 degrés.
    gainMarge = inf;
    wGain = NaN;
    for k = 1:numel(w)-1
        if (p(k) + 180) * (p(k+1) + 180) < 0
            f = (p(k) + 180) / (p(k) - p(k+1));
            wGain = w(k) + f * (w(k+1) - w(k));
            gainMarge = 10 ^ (-(dB(k) + f * (dB(k+1) - dB(k))) / 20);
            if ~isempty(sys)
                wGain = dichotomie(@(x) phaseExacte(sys, x, p(k), p(k+1), w(k), w(k+1)) + 180, ...
                                   w(k), w(k+1));
                gainMarge = 10 ^ (-gainDB(sys, wGain) / 20);
            end
            break;
        end
    end

    if nargout == 0
        if isempty(sys)
            error('Control:general:InvalidArgument', ...
                  'MARGIN without output arguments needs a model.');
        end
        [haut, bas] = matlibre_cases_bode();
        axes(haut);
        semilogx(w, dB);
        grid on;
        ylabel('Gain (dB)');
        if isfinite(gainMarge)
            titre = sprintf('Gm = %.3g dB (a %.3g rad/s)', 20 * log10(gainMarge), wGain);
        else
            titre = 'Gm = Inf';
        end
        if isfinite(phaseMarge)
            titre = sprintf('%s,  Pm = %.3g deg (a %.3g rad/s)', titre, phaseMarge, wPhase);
        else
            titre = [titre ',  Pm = Inf'];
        end
        title(titre);
        axes(bas);
        semilogx(w, p);
        grid on;
        xlabel('Pulsation (rad/s)');
        ylabel('Phase (deg)');
        clear gainMarge phaseMarge wGain wPhase
    end
end

% Le zéro d'une fonction qui change de signe entre A et B, à la précision
% de la machine.
function x = dichotomie(f, a, b)
    fa = f(a);
    for k = 1:200
        x = (a + b) / 2;
        if x <= a || x >= b
            break
        end
        fx = f(x);
        if fx == 0
            return
        end
        if sign(fx) == sign(fa)
            a = x;
            fa = fx;
        else
            b = x;
        end
    end
end

function g = gainDB(sys, w)
    m = bode(sys, w);
    g = 20 * log10(m(1));
end

% La phase exacte en W, ramenée à la branche de la grille : celle que
% l'interpolation entre (WA, PA) et (WB, PB) donne à 180 degrés près.
function ph = phaseExacte(sys, w, pa, pb, wa, wb)
    [~, ph] = bode(sys, w);
    ph = ph(1);
    estime = pa + (w - wa) / (wb - wa) * (pb - pa);
    ph = ph + 360 * round((estime - ph) / 360);
end
