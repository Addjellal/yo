function jeu = matlibre_jeu_ajouter(jeu, type, champs, classes, donnees)
%MATLIBRE_JEU_AJOUTER Ajoute des instruments d'un type à un jeu.
%   Les données sont diffusées : un scalaire vaut pour tous les
%   instruments ajoutés, et le nombre d'instruments est celui du plus
%   grand argument.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    nombre = 1;
    for k = 1:numel(donnees)
        if iscell(donnees{k})
            nombre = max(nombre, numel(donnees{k}));
        elseif ischar(donnees{k})
            nombre = max(nombre, 1);
        elseif ~isempty(donnees{k})
            nombre = max(nombre, size(donnees{k}, 1));
        end
    end
    valeurs = cell(1, numel(champs));
    for k = 1:numel(champs)
        if k <= numel(donnees)
            brut = donnees{k};
        else
            brut = [];
        end
        valeurs{k} = matlibre_champ_instrument(brut, classes{k}, nombre, champs{k});
    end
    rang = find(strcmpi(jeu.Type, type), 1);
    premier = jeu.Nombre + 1;
    indices = (premier:(premier + nombre - 1)).';
    if isempty(rang)
        jeu.Type{end+1} = type;
        jeu.FieldName{end+1} = champs;
        jeu.FieldClass{end+1} = classes;
        jeu.FieldData{end+1} = valeurs;
        jeu.Index{end+1} = indices;
    else
        for k = 1:numel(champs)
            if iscell(jeu.FieldData{rang}{k})
                jeu.FieldData{rang}{k} = [jeu.FieldData{rang}{k}; valeurs{k}];
            else
                ancien = jeu.FieldData{rang}{k};
                nouveau = valeurs{k};
                largeur = max(size(ancien, 2), size(nouveau, 2));
                ancien = matlibre_elargir(ancien, largeur);
                nouveau = matlibre_elargir(nouveau, largeur);
                jeu.FieldData{rang}{k} = [ancien; nouveau];
            end
        end
        jeu.Index{rang} = [jeu.Index{rang}; indices];
    end
    jeu.Nombre = jeu.Nombre + nombre;
end
