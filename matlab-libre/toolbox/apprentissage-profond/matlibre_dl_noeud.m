function n = matlibre_dl_noeud(x)
%MATLIBRE_DL_NOEUD Numéro de nœud d'un opérande sur la bande.
%   N = MATLIBRE_DL_NOEUD(X) rend le nœud que X occupe, ou zéro si X est
%   une constante — un tableau ordinaire, ou un DLARRAY créé hors
%   enregistrement. Un parent de numéro zéro ne reçoit pas de dérivée.
%
%   Exemple :
%      matlibre_dl_noeud(3)     % 0
%
%   Voir aussi DLARRAY, MATLIBRE_BANDE, DLGRADIENT.
    if isa(x, 'dlarray')
        n = x.Noeud;
    else
        n = 0;
    end
end
