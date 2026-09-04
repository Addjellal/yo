function valeur = matlibre_champ_instrument(brut, classe, nombre, nom)
%MATLIBRE_CHAMP_INSTRUMENT Met une donnée à la forme attendue par le jeu.
%   Les champs de texte deviennent un tableau de cellules d'une ligne par
%   instrument ; les champs numériques une matrice, les dates converties
%   en numéros de série.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if strcmp(classe, 'char')
        if isempty(brut)
            valeur = repmat({''}, nombre, 1);
        elseif ischar(brut) || isstring(brut)
            valeur = repmat({char(brut)}, nombre, 1);
        elseif iscell(brut)
            valeur = brut(:);
            if numel(valeur) == 1
                valeur = repmat(valeur, nombre, 1);
            end
        else
            error('finstr:instrument:Champ', ...
                  'Le champ %s attend du texte.', nom);
        end
        return
    end
    if isempty(brut)
        valeur = nan(nombre, 1);
        return
    end
    if ischar(brut) || iscell(brut) || isstring(brut)
        brut = matlibre_dates(brut);
    end
    brut = double(brut);
    if size(brut, 1) == 1 && size(brut, 2) > 1 && nombre > 1
        % Une ligne pour plusieurs instruments : c'est une suite de
        % valeurs communes, non un instrument par colonne.
        brut = repmat(brut, nombre, 1);
    elseif numel(brut) == 1
        brut = repmat(brut, nombre, 1);
    elseif size(brut, 1) == 1 && nombre == 1
        % rien à faire
    elseif size(brut, 1) ~= nombre
        brut = reshape(brut, [], 1);
        if size(brut, 1) ~= nombre
            error('finstr:instrument:Taille', ...
                  'Le champ %s n''a pas le bon nombre de lignes.', nom);
        end
    end
    valeur = brut;
end
