function [lent, rapide] = slowfast(sys, nombreLents)
%SLOWFAST Sépare les modes lents des modes rapides.
%   [GL,GR] = SLOWFAST(SYS,N) découpe SYS en deux modèles dont la somme
%   redonne SYS : GL porte les N pôles les plus lents — ceux dont la
%   partie réelle est la plus proche de zéro — et GR tous les autres.
%
%   Le terme direct est mis dans GL ; GR n'en a pas.
%
%   C'est la façon de réduire un modèle par la fréquence plutôt que par
%   le poids : quand on sait que seule la bande basse importe, on garde
%   GL. La troncature équilibrée, elle, choisit selon ce que chaque mode
%   apporte à la réponse, ce qui n'est pas la même chose.
%
%   Exemples :
%      G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      [lent, rapide] = slowfast(G, 1);
%      pole(lent)                    % -1
%      pole(rapide)                  % -10 et -100
%      norm(G - (lent + rapide), Inf) < 1e-8    % la somme redonne G
%
%   Voir aussi STABPROJ, MODREAL, STRANS, BALANCMR, MODRED.
    G = ss(sys);
    n = size(G.A, 1);
    if nargin < 2 || isempty(nombreLents)
        nombreLents = ceil(n / 2);
    end
    nombreLents = max(0, min(round(nombreLents), n));
    poles = eig(G.A);
    [~, ordre] = sort(abs(real(poles)), 'ascend');
    garde = false(n, 1);
    garde(ordre(1:nombreLents)) = true;
    [lent, rapide] = matlibre_scinder_modes(G, poles, garde);
end
