function [arbre, varargout] = wpsplt(arbre, noeud)
%WPSPLT Scinde un nœud terminal d'un arbre de paquets.
%   T = WPSPLT(T,N) coupe la feuille N en ses enfants : deux pour un
%   signal, quatre pour une image. C'est ainsi qu'on affine un arbre là
%   où le signal le demande, au lieu de le décomposer partout.
%
%   [T,CA,CD] = WPSPLT(T,N) rend en outre les coefficients des enfants.
%
%   Exemple :
%      t = wpdec(1:64, 1, 'db2');
%      t = wpsplt(t, 1);              % on affine la seule branche basse
%      leaves(t)'                     % 2 3 4
%
%   Voir aussi WPJOIN, WPDEC, LEAVES, BESTTREE.
    indice = indiceDeNoeud(arbre, noeud);
    if ~any(arbre.noeuds == indice)
        error('wavelet:wpsplt:Absent', ...
              'Le nœud %d n''est pas dans l''arbre.', indice);
    end
    if any(arbre.noeuds == arbre.ordre * indice + 1)
        error('wavelet:wpsplt:DejaScinde', ...
              'Le nœud %d est déjà scindé.', indice);
    end
    arbre = scinderNoeud(arbre, indice);
    arbre.profondeur = treedpth(arbre);
    for k = 1:min(nargout - 1, arbre.ordre)
        varargout{k} = lireNoeud(arbre, arbre.ordre * indice + k);   %#ok<AGROW>
    end
end
