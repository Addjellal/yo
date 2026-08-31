function [Zr, feuilleDe] = matlibre_arbre_reduit(Z, T, garde)
%MATLIBRE_ARBRE_REDUIT L'arbre des GARDE derniers groupes seulement.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   DENDROGRAM s'en sert pour ne dessiner que le haut de l'arbre quand
%   les observations sont trop nombreuses pour tenir sur un axe.
    n = size(Z, 1) + 1;
    feuilleDe = T(:);
    if garde >= n
        Zr = Z;
        return;
    end
    % Les GARDE-1 dernières fusions sont celles à garder ; les nœuds
    % qu'elles réunissent deviennent les feuilles du nouvel arbre.
    premiere = n - garde + 1;      % première fusion conservée
    correspondance = zeros(2 * n - 1, 1);
    % Quel groupe de T chaque nœud du bas représente-t-il ?
    membres = cell(2 * n - 1, 1);
    for i = 1:n
        membres{i} = i;
    end
    for m = 1:n - 1
        membres{n + m} = [membres{Z(m, 1)}, membres{Z(m, 2)}];
    end
    for noeud = 1:2 * n - 1
        g = T(membres{noeud}(1));
        if all(T(membres{noeud}) == g)
            correspondance(noeud) = g;      % ce nœud tient dans une feuille
        end
    end
    nf = garde;
    Zr = zeros(garde - 1, 3);
    numeroDe = zeros(2 * n - 1, 1);
    for i = 1:2 * n - 1
        if correspondance(i) > 0
            numeroDe(i) = correspondance(i);
        end
    end
    ligne = 0;
    for m = premiere:n - 1
        ligne = ligne + 1;
        a = numeroDe(Z(m, 1));
        b = numeroDe(Z(m, 2));
        Zr(ligne, 1) = min(a, b);
        Zr(ligne, 2) = max(a, b);
        Zr(ligne, 3) = Z(m, 3);
        numeroDe(n + m) = nf + ligne;
    end
end
