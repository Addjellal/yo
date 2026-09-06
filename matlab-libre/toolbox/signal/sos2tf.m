function [b, a] = sos2tf(sos, g)
%SOS2TF Sections du second ordre vers fonction de transfert.
%   [B,A] = SOS2TF(SOS) développe l'enchaînement des sections du second
%   ordre en une seule fonction de transfert B(z)/A(z), en convoluant les
%   numérateurs entre eux et les dénominateurs entre eux.
%   [B,A] = SOS2TF(SOS,G) multiplie le numérateur par le gain global G.
%
%   Chaque ligne de SOS vaut [b0 b1 b2 a0 a1 a2]. Les zéros de tête du
%   résultat sont retirés : un coefficient de tête nul ne décrit pas un
%   degré, seulement un retard.
%
%   Le développement est exact en arithmétique réelle et fragile en
%   virgule flottante : sur un filtre d'ordre élevé, les coefficients
%   développés s'étendent sur plusieurs ordres de grandeur et de petites
%   erreurs relatives déplacent beaucoup les racines. C'est pour cela
%   qu'on filtre en sections plutôt qu'avec B et A.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [sos, g] = tf2sos(b, a);
%      [b2, a2] = sos2tf(sos, g);
%      max(abs(b2 - b)) < 1e-10
%
%   Voir aussi TF2SOS, SOS2ZP, SOS2SS, ZP2SOS.
    if nargin < 2, g = 1; end
    b = g;
    a = 1;
    for k = 1:size(sos, 1)
        b = conv(b, sos(k, 1:3));
        a = conv(a, sos(k, 4:6));
    end
    % Les zéros de tête n'ont pas de sens dans une fonction de transfert.
    while numel(b) > 1 && b(1) == 0, b(1) = []; end
    while numel(a) > 1 && a(1) == 0, a(1) = []; end
end
