function x = wprec(arbre)
%WPREC Reconstruction à partir d'un arbre de paquets d'ondelettes.
%   X = WPREC(T) recompose le signal en remontant l'arbre : chaque nœud
%   scindé est refait de ses enfants, jusqu'à la racine.
%
%   La reconstruction est exacte, aux erreurs d'arrondi près, quel que
%   soit l'élagage de l'arbre : c'est ce qui permet d'annuler ou de
%   seuiller quelques feuilles et de revenir au signal.
%
%   Exemple :
%      t = wpdec(1:64, 3, 'db2');
%      max(abs(wprec(t) - (1:64)))    % nul
%
%   Voir aussi WPDEC, WPRCOEF, WPREC2, WPTHCOEF.
    if arbre.dimension ~= 1
        error('wavelet:wprec:Dimension', ...
              'WPREC attend un arbre de signal ; employez WPREC2.');
    end
    x = remonter(arbre, 0);
    x = wkeep(x, arbre.longueur);
    if ~arbre.ligne
        x = x(:);
    end
end

function donnees = remonter(arbre, indice)
%REMONTER Coefficients d'un nœud, recomposés s'il est scindé.
    gauche = 2 * indice + 1;
    droite = 2 * indice + 2;
    if any(arbre.noeuds == gauche) && any(arbre.noeuds == droite)
        a = remonter(arbre, gauche);
        d = remonter(arbre, droite);
        donnees = idwt(a, d, arbre.nom);
    else
        donnees = lireNoeud(arbre, indice);
        if isempty(donnees)
            error('wavelet:wprec:Absent', ...
                  'Le nœud %d manque : l''arbre est incomplet.', indice);
        end
    end
end
