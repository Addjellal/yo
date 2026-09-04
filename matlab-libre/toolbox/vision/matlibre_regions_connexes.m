function [M, nombre] = matlibre_regions_connexes(L, tailleMin)
%MATLIBRE_REGIONS_CONNEXES Rend connexe et renumérote un étiquetage.
%   [M,N] = MATLIBRE_REGIONS_CONNEXES(L,TAILLEMIN) découpe chaque
%   étiquette en ses morceaux connexes — voisinage de quatre — et
%   renumérote de un à N. Un morceau de moins de TAILLEMIN pixels est
%   fondu dans le morceau voisin déjà numéroté, ce qui évite les régions
%   d'un pixel que le regroupement laisse parfois derrière lui.
%
%   Exemple :
%      L = [1 1 2; 1 1 2; 3 3 2];
%      [M, n] = matlibre_regions_connexes(L, 0);   % n = 3
%
%   Voir aussi SUPERPIXELS, BWLABEL, PCSEGDIST.
    [h, l] = size(L);
    M = zeros(h, l);
    nombre = 0;
    pile = zeros(h * l, 1);
    membres = zeros(h * l, 1);
    voisinsLigne = [-1 1 0 0];
    voisinsColonne = [0 0 -1 1];
    for depart = 1:(h * l)
        if M(depart) ~= 0
            continue
        end
        etiquette = L(depart);
        sommet = 1;
        pile(1) = depart;
        compte = 0;
        adjacente = 0;
        M(depart) = -1;
        while sommet > 0
            courant = pile(sommet);
            sommet = sommet - 1;
            compte = compte + 1;
            membres(compte) = courant;
            [i, j] = ind2sub([h l], courant);
            for v = 1:4
                a = i + voisinsLigne(v);
                b = j + voisinsColonne(v);
                if a < 1 || a > h || b < 1 || b > l
                    continue
                end
                voisin = a + (b - 1) * h;
                if L(voisin) == etiquette
                    if M(voisin) == 0
                        M(voisin) = -1;
                        sommet = sommet + 1;
                        pile(sommet) = voisin;
                    end
                elseif M(voisin) > 0
                    % Une région déjà numérotée, en contact : c'est elle
                    % qui absorbera ce morceau s'il est trop petit.
                    adjacente = M(voisin);
                end
            end
        end
        if compte < tailleMin && adjacente > 0
            attribuee = adjacente;
        else
            nombre = nombre + 1;
            attribuee = nombre;
        end
        M(membres(1:compte)) = attribuee;
    end
end
