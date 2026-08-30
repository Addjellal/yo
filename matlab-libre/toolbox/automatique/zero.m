function z = zero(sys)
%ZERO Zéros d'un modèle.
%   Z = ZERO(SYS) rend les zéros : les racines du numérateur d'une
%   fonction de transfert, les zéros de transmission d'un modèle d'état.
%   [Z,K] = ZERO(SYS) rend en plus le gain.
%
%   Un zéro dans le demi-plan droit fait partir la réponse indicielle du
%   mauvais côté avant de revenir : c'est le comportement à non-minimum
%   de phase, qu'aucun correcteur ne supprime.
%
%   Exemples :
%      zero(tf([1 2], [1 3 2]))             % -2
%      isempty(zero(tf(1, [1 1])))          % vrai
%      zero(tf([1 -1], [1 1]))              % 1 : a non-minimum de phase
%
%   Voir aussi POLE, TZERO, PZMAP, ROOTS.
    if strcmp(sys.type, 'ss')
        [num, ~] = ss2tf(sys.A, sys.B, sys.C, sys.D);
        z = roots(num);
    else
        z = roots(sys.num);
    end
end
