function v = completerLongueur(v, longueur)
%COMPLETERLONGUEUR Complète un polynôme de zéros, ou le tronque.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    longueur = round(longueur);
    if isvector(v)
        % Un scalaire est à la fois ligne et colonne : le rendre en
        % colonne ferait ensuite diffuser les opérations terme à terme en
        % matrice, au lieu de les garder en vecteur.
        colonne = iscolumn(v) && numel(v) > 1;
        v = v(:).';
        if numel(v) < longueur
            v = [v, zeros(1, longueur - numel(v))];
        else
            v = v(1:longueur);
        end
        if colonne
            v = v.';
        end
        return
    end
    if size(v, 2) < longueur
        v = [v, zeros(size(v, 1), longueur - size(v, 2))];
    else
        v = v(:, 1:longueur);
    end
end
