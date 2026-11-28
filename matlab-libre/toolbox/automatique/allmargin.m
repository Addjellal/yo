function m = allmargin(sys)
%ALLMARGIN Toutes les marges de stabilité d'une boucle ouverte.
%   M = ALLMARGIN(SYS) rend une structure aux champs
%     GainMargin, GMFrequency    marges de gain et pulsations associées
%     PhaseMargin, PMFrequency   marges de phase, en degrés
%     DelayMargin, DMFrequency   retards purs supportables, en secondes
%                                (en périodes d'échantillonnage si le
%                                modèle est discret)
%     Stable                     la boucle fermée est-elle stable
%
%   À la différence de MARGIN, qui ne rend que la plus petite de chaque
%   sorte, ALLMARGIN les rend toutes : une boucle peut traverser
%   plusieurs fois le gain unité ou la phase -180 degrés.
%
%   Exemple :
%      m = allmargin(tf(1, [1 2 1 0]));
%      m.GainMargin   % 2
%
%   Voir aussi MARGIN, BODE, NYQUIST.
    matlibre_monovoie(sys, 'ALLMARGIN', 'LOOPMARGIN');
    w = logspace(-4, 4, 8000).';
    if sys.Ts > 0
        % Au-delà de la pulsation de Nyquist, la réponse d'un modèle
        % échantillonné se répète : MATLAB s'y arrête, sans quoi chaque
        % repli ajouterait de fausses traversées.
        nyquist = pi / sys.Ts;
        w = [w(w < nyquist); nyquist];
    end
    [module, phase, w] = bode(sys, w);
    dB = 20 * log10(module);
    % Marges de gain : la phase traverse -180 degrés modulo 360.
    marges = [];
    pulsations = [];
    for k = 1:numel(w) - 1
        cible = -180 + 360 * floor((phase(k) + 180) / 360);
        for essai = [cible, cible - 360, cible + 360]
            if (phase(k) - essai) * (phase(k+1) - essai) < 0
                % La grille situe la traversée ; elle se lit sur la réponse
                % exacte, comme dans MATLAB, et non par interpolation.
                [wg, ~, module] = matlibre_traversee(sys, 'phase', essai, w(k), w(k+1), ...
                                                     phase(k), phase(k+1));
                marges(end+1) = 1 / module;                    %#ok<AGROW>
                pulsations(end+1) = wg;                        %#ok<AGROW>
            end
        end
    end
    % Marges de phase : le gain traverse 0 dB.
    margesPhase = [];
    pulsationsPhase = [];
    for k = 1:numel(w) - 1
        if dB(k) * dB(k+1) < 0
            [wc, ph] = matlibre_traversee(sys, 'gain', 0, w(k), w(k+1), phase(k), phase(k+1));
            % Marge de phase : 180 + phase, ramenée dans (-180, 180].
            marge = mod(ph + 180, 360);
            if marge > 180
                marge = marge - 360;
            end
            margesPhase(end+1) = marge;                        %#ok<AGROW>
            pulsationsPhase(end+1) = wc;                       %#ok<AGROW>
        end
    end
    % Marge de retard : le déphasage que la marge de phase autorise.
    if isempty(margesPhase)
        margeRetard = Inf;
        pulsationRetard = NaN;
    else
        margeRetard = zeros(size(margesPhase));
        for k = 1:numel(margesPhase)
            phi = margesPhase(k) * pi / 180;
            if phi <= 0 || pulsationsPhase(k) == 0
                margeRetard(k) = Inf;
            else
                margeRetard(k) = phi / pulsationsPhase(k);
            end
        end
        pulsationRetard = pulsationsPhase;
        if sys.Ts > 0
            margeRetard = margeRetard / sys.Ts;
        end
    end
    boucle = feedback(sys, 1);
    p = pole(boucle);
    if sys.Ts > 0
        stable = all(abs(p) < 1 - 1e-9);
    else
        stable = all(real(p) < -1e-9);
    end
    m = struct('GainMargin', marges, 'GMFrequency', pulsations, ...
               'PhaseMargin', margesPhase, 'PMFrequency', pulsationsPhase, ...
               'DelayMargin', margeRetard, 'DMFrequency', pulsationRetard, ...
               'Stable', stable);
end
