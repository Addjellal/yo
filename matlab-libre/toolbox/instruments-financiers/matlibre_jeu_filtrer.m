function [indices, applique] = matlibre_jeu_filtrer(jeu, arguments)
%MATLIBRE_JEU_FILTRER Numéros des instruments répondant à un critère.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    applique = false;
    indices = (1:jeu.Nombre).';
    nomChamp = '';
    donnee = [];
    k = 1;
    while k + 1 <= numel(arguments)
        nom = lower(char(arguments{k}));
        switch nom
            case 'type'
                rang = find(strcmpi(jeu.Type, char(arguments{k+1})), 1);
                if isempty(rang)
                    indices = zeros(0, 1);
                else
                    indices = intersect(indices, jeu.Index{rang});
                end
                applique = true;
            case 'index'
                indices = intersect(indices, double(arguments{k+1}(:)));
                applique = true;
            case 'fieldname'
                nomChamp = char(arguments{k+1});
            case 'data'
                donnee = arguments{k+1};
        end
        k = k + 2;
    end
    if ~isempty(nomChamp)
        colonne = matlibre_jeu_colonne(jeu, nomChamp, indices);
        if iscell(colonne)
            if ischar(donnee) || isstring(donnee)
                garde = strcmpi(colonne, char(donnee));
            else
                garde = true(size(colonne));
            end
        else
            valeurs = double(donnee(:)).';
            garde = false(size(colonne, 1), 1);
            for k = 1:size(colonne, 1)
                garde(k) = any(abs(colonne(k, 1) - valeurs) < 1e-12);
            end
        end
        indices = indices(garde);
        applique = true;
    end
end
