function s = lsiminfo(y, t, valeurFinale)
%LSIMINFO Caractéristiques d'une réponse quelconque.
%   S = LSIMINFO(Y,T) décrit la réponse Y observée aux instants T :
%   SettlingTime le temps au bout duquel elle reste à deux pour cent de sa
%   valeur finale, Min et Max ses extrêmes, MinTime et MaxTime les
%   instants où ils sont atteints.
%
%   S = LSIMINFO(Y,T,YFINAL) impose la valeur finale au lieu de prendre la
%   dernière.
%
%   C'est STEPINFO pour une entrée qui n'est pas un échelon : ni temps de
%   montée ni dépassement, qui n'auraient pas de sens, mais le reste.
%
%   Exemples :
%      t = linspace(0, 10, 500);
%      y = 1 - exp(-t);
%      s = lsiminfo(y, t);
%      s.SettlingTime > 3 && s.SettlingTime < 5      % environ 4 constantes
%      s.Max                                          % proche de 1
%
%   Voir aussi STEPINFO, LSIM, STEP, IMPULSE.
    y = y(:);
    t = t(:);
    if nargin < 3 || isempty(valeurFinale)
        valeurFinale = y(end);
    end
    [maximum, kMax] = max(y);
    [minimum, kMin] = min(y);
    seuil = 0.02 * max(abs(valeurFinale), eps);
    etabli = t(end);
    for k = numel(y):-1:1
        if abs(y(k) - valeurFinale) > seuil
            if k < numel(y)
                etabli = t(k + 1);
            else
                etabli = NaN;
            end
            break
        end
        if k == 1
            etabli = t(1);
        end
    end
    s = struct('SettlingTime', etabli, ...
               'Min', minimum, 'MinTime', t(kMin), ...
               'Max', maximum, 'MaxTime', t(kMax));
end
