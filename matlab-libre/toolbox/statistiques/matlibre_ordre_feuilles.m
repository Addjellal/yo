function ordre = matlibre_ordre_feuilles(Z, nf)
%MATLIBRE_ORDRE_FEUILLES Range les feuilles pour qu'aucun lien n'en croise un autre.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   C'est un parcours en profondeur depuis la racine : les feuilles
%   sortent dans l'ordre où on les rencontre, et deux feuilles réunies
%   tôt restent voisines.
    m = size(Z, 1);
    if m == 0
        ordre = 1;
        return;
    end
    ordre = zeros(1, nf);
    place = 0;
    pile = nf + m;      % la racine
    while ~isempty(pile)
        noeud = pile(end);
        pile(end) = [];
        if noeud <= nf
            place = place + 1;
            ordre(place) = noeud;
        else
            % On empile la branche droite d'abord : la gauche sortira
            % en premier.
            pile(end + 1) = Z(noeud - nf, 2);   %#ok<AGROW>
            pile(end + 1) = Z(noeud - nf, 1);   %#ok<AGROW>
        end
    end
end
