function sys = pid(Kp, Ki, Kd, Tf, Ts)
%PID Correcteur proportionnel intégral dérivé.
%   C = PID(KP,KI,KD,TF) rend la fonction de transfert
%   KP + KI/s + KD*s/(TF*s+1). Avec TF nul, le terme dérivé est pur.
%   C = PID(...,TS) donne un correcteur échantillonné.
%
%   Exemple :
%      c = pid(2, 1, 0);          % (2s + 1)/s
%      dcgain(pid(1, 0, 0))       % 1
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
