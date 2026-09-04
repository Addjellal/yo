function matlibre_garch_afficher(obj)
%MATLIBRE_GARCH_AFFICHER Écrit le modèle sous une forme lisible.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(obj.Description)
        fprintf('  GARCH(%d,%d)\n', obj.P, obj.Q);
    else
        fprintf('  %s\n', obj.Description);
    end
    fprintf('    Distribution : %s\n', matlibre_texte_loi(obj.Distribution));
    fprintf('    P = %d, Q = %d\n', obj.P, obj.Q);
    fprintf('    Constant = %s\n', matlibre_texte_nombre(obj.Constant));
    ecrireListe('GARCH', obj.GARCHLags, obj.GARCH);
    ecrireListe('ARCH', obj.ARCHLags, obj.ARCH);
    fprintf('    Offset = %s\n', matlibre_texte_nombre(obj.Offset));
end

function ecrireListe(nom, retards, coefficients)
    if isempty(retards)
        return
    end
    morceaux = cell(1, numel(retards));
    for k = 1:numel(retards)
        morceaux{k} = sprintf('{%d: %s}', retards(k), ...
                              matlibre_texte_nombre(coefficients{k}));
    end
    fprintf('    %s = %s\n', nom, strjoin(morceaux, ' '));
end
