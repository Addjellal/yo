function [A, B, C, D] = sos2ss(sos, g)
%SOS2SS Représentation d'état d'un enchaînement de sections du second ordre.
%   [A,B,C,D] = SOS2SS(SOS) rend une représentation d'état équivalente à
%   l'enchaînement des sections du second ordre décrites par les lignes de
%   SOS, chacune de la forme [b0 b1 b2 a0 a1 a2].
%   [A,B,C,D] = SOS2SS(SOS,G) applique en plus le gain global G.
%
%   Le passage se fait par la fonction de transfert développée, donc par
%   la forme compagne. Cette forme est celle qui souffre le plus des
%   erreurs d'arrondi sur les coefficients : c'est précisément pour
%   l'éviter qu'on garde un filtre en sections du second ordre. Convertir
%   n'a donc d'intérêt que pour raisonner sur l'état, pas pour filtrer.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [sos, g] = tf2sos(b, a);
%      [A, B, C, D] = sos2ss(sos, g);
%
%   Voir aussi SS2SOS, SOS2TF, TF2SS, TF2SOS.
    if nargin < 2, g = 1; end
    [b, a] = sos2tf(sos, g);
    [A, B, C, D] = tf2ss(b, a);
end
