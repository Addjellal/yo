function [r, puissances, frequences] = thd(x, fs, nharm)
%THD Distorsion harmonique totale, en décibels.
%   R = THD(X) rend le rapport, en décibels, entre la puissance des
%   harmoniques et celle du fondamental. La valeur est négative : plus
%   elle est basse, plus le signal est pur.
%
%   R = THD(X,FS,N) prend en compte N harmoniques, six par défaut.
%
%   [R,POW,FREQ] = THD(...) rend aussi la puissance et la fréquence de
%   chaque harmonique, fondamental compris.
%
%   Exemple :
%      t = (0:999)'/1000;
%      x = cos(2*pi*50*t) + 0.1*cos(2*pi*100*t);
%      thd(x)      % -20 dB : l'harmonique est dix fois plus petite
    if nargin < 2 || isempty(fs), fs = 1; end
    if nargin < 3 || isempty(nharm), nharm = 6; end
    [S, f] = signalSpectrePuissance(x, fs);
    S = retirerContinu(S);
    [~, kf] = max(S);
    puissanceFondamental = signalLobe(S, kf);
    frequences = f(kf);
    puissances = puissanceFondamental;
    sommeHarmoniques = 0;
    for h = 2:nharm
        cible = (kf - 1) * h + 1;
        if cible > numel(S)
            break
        end
        kh = signalSommet(S, cible, 3);
        [ph, ~] = signalLobe(S, kh);
        sommeHarmoniques = sommeHarmoniques + ph;
        puissances(end + 1, 1) = ph;                       %#ok<AGROW>
        frequences(end + 1, 1) = f(kh);                    %#ok<AGROW>
    end
    r = 10 * log10(sommeHarmoniques / puissanceFondamental);
end

function S = retirerContinu(S)
    [~, plage] = signalLobe(S, 1);
    S(plage) = 0;
end
