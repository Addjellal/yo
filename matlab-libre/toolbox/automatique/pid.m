function sys = pid(Kp, Ki, Kd, Tf, Ts)
%PID Correcteur proportionnel, intégral et dérivé.
%   C = PID(KP,KI,KD) rend le correcteur KP + KI/s + KD*s, sous forme de
%   fonction de transfert.
%
%   C = PID(KP,KI,KD,TF) filtre l'action dérivée par 1/(TF*s+1), ce qu'il
%   faut toujours faire en pratique : un dérivateur pur amplifie le bruit
%   sans limite.
%
%   Exemples :
%      c = pid(2, 1, 0);
%      dcgain(c)                            % Inf : l'integrateur annule l'erreur
%      c2 = pid(1, 0, 0.1, 0.01);
%      isfinite(evalfr(c2, 1e6))            % vrai : la derivee est filtree
%
%   Voir aussi PIDSTD, PIDTUNE, TF, FEEDBACK, MARGIN.
    if nargin < 1 || isempty(Kp), Kp = 1; end
    if nargin < 2 || isempty(Ki), Ki = 0; end
    if nargin < 3 || isempty(Kd), Kd = 0; end
    if nargin < 4 || isempty(Tf), Tf = 0; end
    if nargin < 5, Ts = 0; end
    % Sans terme intégral, le s du dénominateur commun se simplifie : on
    % le fait ici pour que le correcteur garde son degré minimal, sinon
    % dcgain rendrait 0/0.
    if Tf > 0
        if Ki ~= 0
            num = [Kp * Tf + Kd, Kp + Ki * Tf, Ki];
            den = [Tf, 1, 0];
        else
            num = [Kp * Tf + Kd, Kp];
            den = [Tf, 1];
        end
    else
        if Ki ~= 0
            % Sans terme dérivé, le numérateur reste de degré un : on ne
            % laisse pas de zéro de tête, comme MATLAB.
            if Kd ~= 0
                num = [Kd, Kp, Ki];
            else
                num = [Kp, Ki];
            end
            den = [1, 0];
        elseif Kd ~= 0
            num = [Kd, Kp];
            den = 1;
        else
            num = Kp;
            den = 1;
        end
    end
    sys = tf(num, den, Ts);
end
