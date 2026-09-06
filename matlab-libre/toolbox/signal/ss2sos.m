function [sos, g] = ss2sos(A, B, C, D, iu)
%SS2SOS Sections du second ordre d'une représentation d'état.
%   [SOS,G] = SS2SOS(A,B,C,D) rend les sections du second ordre
%   équivalentes à la représentation d'état donnée, et le gain global G.
%   [SOS,G] = SS2SOS(A,B,C,D,IU) choisit l'entrée numéro IU quand le
%   système en a plusieurs ; par défaut la première.
%
%   Le chemin passe par la fonction de transfert, puis par le groupement
%   des pôles et zéros conjugués en sections du second ordre. Un filtre
%   d'ordre impair donne une section du premier ordre, complétée par des
%   coefficients nuls.
%
%   L'intérêt de la forme d'arrivée est numérique : chaque section n'a que
%   deux pôles, dont la position ne dépend que de deux coefficients, si
%   bien qu'un arrondi de quantification ne déplace jamais un pôle plus
%   loin que dans sa propre section.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [A, B, C, D] = tf2ss(b, a);
%      [sos, g] = ss2sos(A, B, C, D);
%
%   Voir aussi SOS2SS, TF2SOS, ZP2SOS, SS2TF.
    if nargin < 5, iu = 1; end
    [num, den] = ss2tf(A, B, C, D, iu);
    [sos, g] = tf2sos(num, den);
end
