function s = stepinfo(systeme, varargin)
%STEPINFO Caractéristiques d'une réponse indicielle.
%   S = STEPINFO(SYS) rend une structure décrivant la réponse à un
%   échelon : RiseTime le temps de montée de 10 à 90 pour cent,
%   SettlingTime le temps d'établissement à 2 pour cent, Overshoot le
%   dépassement en pourcentage, Peak la valeur maximale et PeakTime
%   l'instant où elle est atteinte.
%
%   S = STEPINFO(Y,T) part d'une réponse déjà simulée.
%
%   Exemples :
%      s = stepinfo(tf(1, [1 1]));
%      s.Overshoot < 1                      % un premier ordre ne depasse pas
%      s2 = stepinfo(tf(1, [1 0.4 1]));
%      s2.Overshoot > 50                    % un second ordre peu amorti, si
%
%   Voir aussi STEP, LSIM, DAMP, BANDWIDTH.
    [y, t] = step(systeme);
    y = y(:);
    t = t(:);
    finale = y(end);
    s = struct('RiseTime', NaN, 'SettlingTime', NaN, 'SettlingMin', NaN, ...
               'SettlingMax', NaN, 'Overshoot', 0, 'Undershoot', 0, ...
               'Peak', 0, 'PeakTime', 0);
    if finale == 0
        return
    end
    % Temps de montée : premier passage à 10 % puis à 90 % de la valeur
    % finale, interpolés linéairement.
    s.RiseTime = instantSeuil(t, y, 0.9 * finale) - instantSeuil(t, y, 0.1 * finale);
    % Temps d'établissement : dernier instant hors de la bande à 2 %.
    dehors = find(abs(y - finale) > 0.02 * abs(finale), 1, 'last');
    if isempty(dehors)
        s.SettlingTime = 0;
    elseif dehors < numel(t)
        s.SettlingTime = t(dehors + 1);
    else
        s.SettlingTime = t(end);
    end
    [pic, k] = max(abs(y));
    s.Peak = pic;
    s.PeakTime = t(k);
    s.SettlingMin = min(y(max(1, dehors):end));
    s.SettlingMax = max(y(max(1, dehors):end));
    s.Overshoot = max(0, (max(y) - finale) / abs(finale) * 100);
    s.Undershoot = max(0, -min(y) / abs(finale) * 100);
end

function instant = instantSeuil(t, y, seuil)
    k = find(y >= seuil, 1);
    if isempty(k)
        instant = NaN;
    elseif k == 1
        instant = t(1);
    else
        pente = y(k) - y(k - 1);
        if pente == 0
            instant = t(k);
        else
            instant = t(k - 1) + (seuil - y(k - 1)) * (t(k) - t(k - 1)) / pente;
        end
    end
end
