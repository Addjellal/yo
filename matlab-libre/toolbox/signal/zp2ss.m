function [A, B, C, D] = zp2ss(z, p, k)
%ZP2SS Représentation d'état à partir des zéros, pôles et gain.
%   [A,B,C,D] = ZP2SS(Z,P,K) rend une représentation d'état ayant les
%   zéros Z, les pôles P et le gain K.
%
%   Les valeurs propres de A sont les pôles : la conversion place la
%   dynamique dans la matrice d'état, et les zéros dans le couplage C et
%   D. Un système strictement propre — plus de pôles que de zéros — a D
%   nul, et un zéro autant de pôles qu'il en faut pour que D ne le soit
%   pas.
%
%   Le passage emprunte la fonction de transfert développée, donc la forme
%   compagne : sur un ordre élevé, mieux vaut convertir en sections du
%   second ordre par ZP2SOS que raisonner sur cette forme d'état.
%
%   Exemple :
%      [A, B, C, D] = zp2ss([], [-1 -2], 1);
%      sort(eig(A))'
%
%   Voir aussi ZP2TF, ZP2SOS, SS2ZP, TF2SS.
    [b, a] = zp2tf(z, p, k);
    [A, B, C, D] = tf2ss(b, a);
end
