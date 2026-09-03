function x = wprec2(arbre)
%WPREC2 Reconstruction d'une image à partir de son arbre de paquets.
%   X = WPREC2(T) recompose l'image en remontant l'arbre : chaque nœud
%   scindé est refait de ses quatre enfants, jusqu'à la racine.
%
%   Exemple :
%      t = wpdec2(magic(16), 2, 'db2');
%      max(max(abs(wprec2(t) - magic(16))))   % nul
%
%   Voir aussi WPDEC2, WPREC, WPRCOEF, WPTHCOEF.
    if arbre.dimension ~= 2
        error('wavelet:wprec2:Dimension', ...
              'WPREC2 attend un arbre d''image ; employez WPREC.');
    end
    x = remonter(arbre, 0);
    x = wkeep(x, arbre.taille);
end

function donnees = remonter(arbre, indice)
    premier = 4 * indice + 1;
    if any(arbre.noeuds == premier)
        enfants = cell(1, 4);
        for k = 1:4
            enfants{k} = remonter(arbre, 4 * indice + k);
        end
        donnees = idwt2(enfants{1}, enfants{2}, enfants{3}, enfants{4}, arbre.nom);
    else
        donnees = lireNoeud(arbre, indice);
        if isempty(donnees)
            error('wavelet:wprec2:Absent', ...
                  'Le nœud %d manque : l''arbre est incomplet.', indice);
        end
    end
end
