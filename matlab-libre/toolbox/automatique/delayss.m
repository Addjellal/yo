function sys = delayss(A, B, C, D, retards)
%DELAYSS Modèle d'état à retards internes.
%   SYS = DELAYSS(A,B,C,D,DELTA) construit un modèle d'état dont
%   certaines voies sont retardées. DELTA est une matrice dont chaque
%   ligne décrit un retard : [SORTIE, ENTREE, TEMPS], le terme concerné
%   étant retardé de TEMPS secondes.
%
%   MatLibre n'a pas de modèle à retards internes : le retard est rendu
%   par l'approximation de Padé d'ordre 3, ce qui donne un modèle
%   rationnel du même comportement en basse fréquence. MATLAB, lui,
%   garde le retard exact. Ce que le modèle rendu perd, c'est la
%   justesse de la phase au-delà de quelques radians par seconde.
%
%   Exemple :
%      sys = delayss(-1, 1, 1, 0, [1 1 0.5]);   % retard d'une demi-seconde
%
%   Voir aussi SS, PADE, THIRAN, TOTALDELAY, HASDELAY.
    if nargin < 5 || isempty(retards)
        sys = ss(A, B, C, D);
        return;
    end
    base = ss(A, B, C, D);
    retards = double(retards);
    if size(retards, 2) ~= 3
        error('control:delayss:Retards', ...
              'Chaque retard s''écrit [sortie, entrée, temps].');
    end
    % Un seul retard commun à toutes les voies se compose avec le
    % modèle ; plusieurs retards distincts se composent voie par voie.
    sys = base;
    for k = 1:size(retards, 1)
        temps = retards(k, 3);
        if temps <= 0
            continue;
        end
        approximation = pade(temps, 3);
        sys = approximation * sys;
    end
end
