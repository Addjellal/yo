function [champs, type, indices] = matlibre_jeu_options(jeu, arguments)
%MATLIBRE_JEU_OPTIONS Lit les options communes aux fonctions INST*.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    champs = {};
    type = '';
    indices = [];
    k = 1;
    while k <= numel(arguments)
        nom = lower(char(arguments{k}));
        switch nom
            case 'fieldlist'
                valeur = arguments{k+1};
                if ischar(valeur) || isstring(valeur)
                    champs = {char(valeur)};
                else
                    champs = valeur(:).';
                end
                k = k + 2;
            case 'type'
                type = char(arguments{k+1});
                k = k + 2;
            case 'index'
                indices = double(arguments{k+1}(:));
                k = k + 2;
            otherwise
                % Une liste de champs peut être donnée sans mot-clé.
                if ischar(arguments{k}) || iscell(arguments{k})
                    valeur = arguments{k};
                    if ischar(valeur)
                        champs{end+1} = valeur;   %#ok<AGROW>
                    else
                        champs = [champs, valeur(:).'];   %#ok<AGROW>
                    end
                end
                k = k + 1;
        end
    end
    if isempty(indices)
        if isempty(type)
            indices = (1:jeu.Nombre).';
        else
            rang = find(strcmpi(jeu.Type, type), 1);
            if isempty(rang)
                indices = zeros(0, 1);
            else
                indices = jeu.Index{rang};
            end
        end
    end
end
