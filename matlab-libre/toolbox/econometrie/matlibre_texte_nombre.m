function texte = matlibre_texte_nombre(valeur)
%MATLIBRE_TEXTE_NOMBRE Écrit un nombre, « NaN » compris.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(valeur)
        texte = '[]';
    elseif isnan(valeur)
        texte = 'NaN';
    else
        texte = sprintf('%.6g', valeur);
    end
end
