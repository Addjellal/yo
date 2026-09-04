function P = matlibre_generateur_vers_transition(transitions, tempsPasse, intervalle)
%MATLIBRE_GENERATEUR_VERS_TRANSITION Matrice de transition par le générateur.
%   L'intensité de passage de i vers j est le nombre de passages observés
%   divisé par le temps passé en i ; la diagonale est l'opposé de la
%   somme de la ligne, de sorte que les lignes du générateur somment à
%   zéro. La matrice de transition sur un intervalle est l'exponentielle
%   du générateur multiplié par cet intervalle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = size(transitions, 1);
    Q = zeros(n);
    for i = 1:n
        if tempsPasse(i) > 0
            Q(i, :) = transitions(i, :) / tempsPasse(i);
        end
        Q(i, i) = 0;
        Q(i, i) = -sum(Q(i, :));
    end
    P = expm(Q * intervalle);
    % L'exponentielle numérique peut laisser des résidus négatifs
    % minuscules ; on les efface et l'on renormalise.
    P(P < 0) = 0;
    for i = 1:n
        total = sum(P(i, :));
        if total > 0
            P(i, :) = P(i, :) / total;
        end
    end
end
