function arbre = matlibre_sym_reduire(arbre)
%MATLIBRE_SYM_REDUIRE Simplifie, et regroupe les termes semblables.
%   Après la simplification des cas triviaux, on essaie de lire
%   l'expression comme un polynôme en sa variable : si elle en est un,
%   on la réécrit à partir de ses coefficients, ce qui regroupe les
%   termes semblables et efface les zéros. Sinon on garde la forme
%   simplifiée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    arbre = symsimplify(arbre);
    noms = unique(matlibre_sym_noms(arbre));
    if numel(noms) ~= 1
        return
    end
    try
        coefficients = matlibre_sym_coefficients(arbre, noms{1});
    catch
        return
    end
    arbre = matlibre_sym_polynome(coefficients, noms{1});
end
