function k = matlibre_chainer_aretes(bord)
%MATLIBRE_CHAINER_ARETES Chaîne les arêtes de bord en un contour fermé.
%   On part de la première arête et l'on suit : à chaque pas, l'arête
%   restante qui touche le point courant donne le point suivant. Le
%   contour est rendu premier point répété à la fin.
%
%   Les arêtes sont traitées comme non orientées. C'est nécessaire : les
%   triangles d'une triangulation ne tournent pas tous dans le même sens,
%   donc l'arête de bord peut être rangée dans un sens ou dans l'autre, et
%   suivre l'orientation ferait s'arrêter le contour au premier
%   changement.
%
%   Si le bord a plusieurs composantes — un nuage en deux amas —, seule
%   celle qui part de la première arête est rendue.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      k = matlibre_chainer_aretes([1 2; 3 2; 3 1]);
%      isequal(k([1 end]), [1; 1])     % le contour se referme
%      numel(k)                        % 4 : trois sommets et le retour
%
%   Voir aussi BOUNDARY, ALPHASHAPE, FREEBOUNDARY.
    if isempty(bord)
        k = zeros(0, 1);
        return
    end
    depart = bord(1, 1);
    courant = bord(1, 2);
    k = [depart; courant];
    reste = bord(2:end, :);
    while courant ~= depart && ~isempty(reste)
        suivante = find(reste(:, 1) == courant | reste(:, 2) == courant, 1);
        if isempty(suivante)
            break
        end
        if reste(suivante, 1) == courant
            courant = reste(suivante, 2);
        else
            courant = reste(suivante, 1);
        end
        reste(suivante, :) = [];
        k(end + 1, 1) = courant;   %#ok<AGROW>
    end
    if k(end) ~= depart
        k(end + 1, 1) = depart;
    end
end
