function valeur = matlibre_simpson(fonction, a, b, morceaux)
%MATLIBRE_SIMPSON Intégrale par la méthode de Simpson composée.
%   V = MATLIBRE_SIMPSON(FONCTION,A,B,MORCEAUX) approche l'intégrale par
%   des paraboles sur un nombre pair de morceaux. La formule est exacte
%   pour tout polynôme de degré trois, ce qui la rend bien plus précise
%   que les trapèzes à coût égal.
%
%   Exemple :
%      matlibre_simpson(@(t) t.^2, 0, 3, 100)      % 9
%
%   Voir aussi INTEGRATE, QUAD, TRAPZ.
    if a == b
        valeur = 0;
        return
    end
    if mod(morceaux, 2) == 1
        morceaux = morceaux + 1;
    end
    t = linspace(a, b, morceaux + 1).';
    y = fonction(t);
    y = y(:);
    poids = ones(morceaux + 1, 1);
    poids(2:2:end-1) = 4;
    poids(3:2:end-2) = 2;
    valeur = (b - a) / (3 * morceaux) * sum(poids .* y);
end
