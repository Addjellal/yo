function textes = matlibre_parquet_textes(colonne)
%MATLIBRE_PARQUET_TEXTES Colonne de texte ramenée à une cellule de chaînes.
%   TEXTES = MATLIBRE_PARQUET_TEXTES(COLONNE) accepte une cellule, un
%   tableau de chaînes, une matrice de caractères ou une catégorielle, et
%   rend une cellule de vecteurs de caractères — une ligne par élément.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_parquet_textes(["a"; "b"])    % {'a', 'b'}
%
%   Voir aussi PARQUETWRITE, MATLIBRE_PARQUET_ENCODER.
    if iscell(colonne)
        textes = cell(1, numel(colonne));
        for k = 1:numel(colonne)
            element = colonne{k};
            % Une cellule peut contenir n'importe quoi ; seul du texte
            % se range dans une colonne de texte, et le dire ici évite
            % une conversion obscure trois appels plus loin.
            if ~ischar(element) && ~(isstring(element) && isscalar(element))
                error('MATLAB:parquet:TypeNonSupporte', ...
                      ['Une colonne de cellules ne se range en Parquet que si ' ...
                       'elle ne contient que du texte ; l''élément %d est de ' ...
                       'classe %s.'], k, class(element));
            end
            textes{k} = char(element);
        end
        return
    end
    if isa(colonne, 'categorical')
        colonne = string(colonne);
    end
    if isstring(colonne)
        textes = cell(1, numel(colonne));
        for k = 1:numel(colonne)
            textes{k} = char(colonne(k));
        end
        return
    end
    if ischar(colonne)
        if size(colonne, 1) <= 1
            textes = {colonne};
        else
            textes = cell(1, size(colonne, 1));
            for k = 1:size(colonne, 1)
                textes{k} = deblank(colonne(k, :));
            end
        end
        return
    end
    error('MATLAB:parquet:TypeNonSupporte', ...
          'Colonne de texte attendue ; reçu %s.', class(colonne));
end
