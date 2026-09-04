function texte = matlibre_texte_loi(loi)
%MATLIBRE_TEXTE_LOI Nom de la loi des innovations.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isstruct(loi)
        if isfield(loi, 'Name')
            texte = char(loi.Name);
        else
            texte = 'Gaussian';
        end
    else
        texte = char(loi);
    end
end
