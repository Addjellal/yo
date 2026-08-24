function [C, renseignements] = pidtune(sys, type, wc)
%PIDTUNE Réglage d'un correcteur PID par la marge de phase.
%   C = PIDTUNE(SYS,TYPE) règle un correcteur de type 'p', 'pi', 'pd',
%   'pid', 'pdf' ou 'pidf' pour que la boucle ouverte C*SYS traverse le
%   gain unité avec une marge de phase de soixante degrés.
%
%   La méthode est celle du façonnage de boucle : on choisit la pulsation
%   de coupure là où la phase du procédé vaut ce que le correcteur peut
%   compenser — -100 degrés pour un PI, qui retarde d'une vingtaine de
%   degrés, -165 pour un PID, qui avance d'une quarantaine — puis on
%   impose au correcteur, en cette pulsation, le module et l'argument qui
%   donnent exactement la marge voulue :
%
%      |C(jwc)| = 1 / |G(jwc)|
%      arg C(jwc) = -180 + PM - arg G(jwc)
%
%   Pour un PID, ces deux équations ne suffisent pas à fixer les trois
%   gains : on ajoute la relation classique TI = 4 TD.
%
%   C = PIDTUNE(SYS,TYPE,WC) impose la pulsation de coupure.
%
%   [C,INFO] = PIDTUNE(...) rend une structure aux champs Stable,
%   CrossoverFrequency et PhaseMargin.
%
%   Exemple :
%      c = pidtune(tf(1, [1 3 3 1]), 'pi');
%      [gm, pm] = margin(series(c, tf(1, [1 3 3 1])));
%      pm    % 60 degrés, par construction
%
%   Voir aussi PID, PIDSTD, MARGIN.
    if nargin < 2 || isempty(type), type = 'pi'; end
    type = lower(char(type));
    margeVoulue = 60;
    g = tf(sys);
    filtre = false;
    switch type
        case 'p',    phaseCible = -180 + margeVoulue;
        case 'pi',   phaseCible = -180 + margeVoulue + 20;
        case 'pd',   phaseCible = -180 + margeVoulue - 30;
        case 'pdf',  phaseCible = -180 + margeVoulue - 30; filtre = true;
        case 'pid',  phaseCible = -180 + margeVoulue - 45;
        case 'pidf', phaseCible = -180 + margeVoulue - 45; filtre = true;
        otherwise
            error('control:pidtune:BadType', ...
                  'Le type doit être ''p'', ''pi'', ''pd'', ''pdf'', ''pid'' ou ''pidf''.');
    end
    grille = logspace(-4, 4, 4000).';
    [module, phase] = bode(g, grille);
    if nargin < 3 || isempty(wc)
        % Première pulsation où la phase du procédé descend sous la cible.
        indice = find(phase <= phaseCible, 1);
        if isempty(indice)
            % La phase ne descend jamais si bas : on prend la pulsation la
            % plus rapide de la grille utile, dix fois le mode le plus vif.
            rapides = abs([roots(g.den); roots(g.num)]);
            rapides = rapides(rapides > 1e-9);
            if isempty(rapides)
                wc = 1;
            else
                wc = 10 * max(rapides);
            end
        elseif indice == 1
            wc = grille(1);
        else
            f = (phase(indice - 1) - phaseCible) / (phase(indice - 1) - phase(indice));
            wc = grille(indice - 1) + f * (grille(indice) - grille(indice - 1));
        end
    end
    reponse = evalfr(g, pointFrequentiel(g, wc));
    moduleC = 1 / abs(reponse);
    argumentC = (-180 + margeVoulue) * pi / 180 - angle(reponse);
    argumentC = mod(argumentC + pi, 2 * pi) - pi;
    partieReelle = moduleC * cos(argumentC);
    partieImaginaire = moduleC * sin(argumentC);
    Kp = partieReelle;
    Ki = 0;
    Kd = 0;
    switch type
        case 'p'
            Kp = moduleC;
        case 'pi'
            % C(jw) = Kp - j Ki/w : la partie imaginaire doit être négative.
            Ki = -partieImaginaire * wc;
            if Ki < 0, Ki = 0; end
        case {'pd', 'pdf'}
            Kd = partieImaginaire / wc;
            if Kd < 0, Kd = 0; end
        case {'pid', 'pidf'}
            % TI = 4 TD, soit Ki = Kd wc^2 / 4 : il reste 0.75 Kd wc sur
            % la partie imaginaire.
            Kd = partieImaginaire / (0.75 * wc);
            if Kd < 0, Kd = 0; end
            Ki = Kd * wc ^ 2 / 4;
    end
    if Kp < 0, Kp = 0; end
    Tf = 0;
    if filtre && Kd > 0
        Tf = Kd / (10 * Kp + eps);
    end
    C = pid(Kp, Ki, Kd, Tf, g.Ts);
    if nargout > 1
        ouverte = series(C, g);
        [~, pm, ~, wpm] = margin(ouverte);
        renseignements = struct('Stable', isstable(feedback(ouverte, 1)), ...
                                'CrossoverFrequency', wpm, ...
                                'PhaseMargin', pm);
    end
end

function point = pointFrequentiel(g, w)
    if g.Ts > 0
        point = exp(1i * w * g.Ts);
    else
        point = 1i * w;
    end
end
