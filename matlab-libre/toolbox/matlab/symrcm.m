function p = symrcm(A)
%SYMRCM Renumérotation de Cuthill-McKee inverse.
%   P = SYMRCM(A) rend une permutation qui, appliquée à A, en réduit la
%   largeur de bande : A(P,P) a ses coefficients non nuls plus près de la
%   diagonale.
%
%   L'algorithme parcourt le graphe d'adjacence en largeur depuis un nœud
%   périphérique, en visitant les voisins par degré croissant, puis
%   renverse l'ordre obtenu. Le renversement n'est pas un ornement : il
%   déplace les nœuds de fort degré vers la fin, ce qui réduit encore le
%   remplissage de la factorisation.
%
%   Une bande étroite fait deux choses : la factorisation de Cholesky ne
%   remplit que dans la bande, donc coûte O(n*b^2) au lieu de O(n^3), et
%   le stockage suit. C'est la raison d'être de la renumérotation.
%
%   Le nœud de départ est choisi de plus petit degré : c'est
%   l'heuristique usuelle pour approcher un nœud périphérique sans
%   calculer l'excentricité de tous.
%
%   Exemple :
%      A = [1 0 1 0; 0 1 0 1; 1 0 1 0; 0 1 0 1];
%      p = symrcm(A);
%      isequal(sort(p), 1:4)                    % 1 : c'est une permutation
%      matlibre_largeur_bande(A(p, p)) <= matlibre_largeur_bande(A)
%
%   Voir aussi SYMAMD, COLAMD, CHOL, LU.
    A = full(double(A ~= 0));
    n = size(A, 1);
    A = A | A';                    % le graphe est non oriente
    A(1:n+1:end) = false;          % une boucle ne relie rien
    degres = sum(A, 2);
    vus = false(n, 1);
    ordre = [];
    while numel(ordre) < n
        % Un nouveau depart pour chaque composante connexe.
        restants = find(~vus);
        [~, k] = min(degres(restants));
        depart = restants(k);
        file = depart;
        vus(depart) = true;
        while ~isempty(file)
            courant = file(1);
            file(1) = [];
            ordre(end + 1) = courant;   %#ok<AGROW>
            voisins = find(A(courant, :) & ~vus');
            [~, tri] = sort(degres(voisins));
            voisins = voisins(tri);
            vus(voisins) = true;
            file = [file, voisins];     %#ok<AGROW>
        end
    end
    p = fliplr(ordre);              % le renversement de Cuthill-McKee
end
