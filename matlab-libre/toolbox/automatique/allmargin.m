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
    w = logspace(-4, 4, 8000).';
    [module, phase, w] = bode(sys, w);
    dB = 20 * log10(module);
    % Marges de gain : la phase traverse -180 degrés modulo 360.
    marges = [];
    pulsations = [];
    for k = 1:numel(w) - 1
        cible = -180 + 360 * floor((phase(k) + 180) / 360);
        for essai = [cible, cible - 360, cible + 360]
            if (phase(k) - essai) * (phase(k+1) - essai) < 0
                f = (essai - phase(k)) / (phase(k+1) - phase(k));
                gainDb = dB(k) + f * (dB(k+1) - dB(k));
                marges(end+1) = 10 ^ (-gainDb / 20);          %#ok<AGROW>
                pulsations(end+1) = w(k) + f * (w(k+1) - w(k)); %#ok<AGROW>
            end
        end
    end
    % Marges de phase : le gain traverse 0 dB.
    margesPhase = [];
    pulsationsPhase = [];
    for k = 1:numel(w) - 1
        if dB(k) * dB(k+1) < 0
            f = -dB(k) / (dB(k+1) - dB(k));
            ph = phase(k) + f * (phase(k+1) - phase(k));
            wc = w(k) + f * (w(k+1) - w(k));
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
