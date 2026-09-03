function noms = matlibre_sym_noms(arbre)
%MATLIBRE_SYM_NOMS Noms des variables d'un arbre d'expression.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    noms = {};
    switch arbre{1}
        case 'num'
            return
        case 'var'
            noms = {arbre{2}};
        otherwise
            for k = 2:numel(arbre)
                noms = [noms, matlibre_sym_noms(arbre{k})];   %#ok<AGROW>
            end
    end
end
